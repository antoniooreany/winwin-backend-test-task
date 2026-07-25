param(
    [string]$BaseUrl = "http://localhost:8080",
    [string]$DataApiUrl = "http://localhost:8081",
    [string]$Email = "user@example.com",
    [string]$Password = "Pass12345!",
    [string[]]$Texts = @("hello", "hello world", "WinWin Travel"),
    [switch]$RunMavenTests,
    [switch]$RebuildAndRestart
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Title)
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

function Invoke-JsonPost {
    param(
        [string]$Url,
        [hashtable]$Body,
        [hashtable]$Headers = @{}
    )

    $json = $Body | ConvertTo-Json -Compress

    try {
        $result = Invoke-RestMethod -Method Post `
            -Uri $Url `
            -ContentType "application/json" `
            -Headers $Headers `
            -Body $json

        [pscustomobject]@{
            Ok          = $true
            Url         = $Url
            RequestBody = $json
            StatusCode  = 200
            Data        = $result
            ErrorText   = $null
            ErrorBody   = $null
        }
    }
    catch {
        $statusCode = $null
        $errorText = $_.Exception.Message
        $errorBody = $null

        if ($_.Exception.Response) {
            try {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
            catch {}

            if (-not [string]::IsNullOrWhiteSpace($_.ErrorDetails.Message)) {
                $errorBody = $_.ErrorDetails.Message
            }
            else {
                try {
                    $stream = $_.Exception.Response.GetResponseStream()
                    if ($stream) {
                        $reader = New-Object System.IO.StreamReader($stream)
                        $reader.BaseStream.Position = 0
                        $reader.DiscardBufferedData()
                        $errorBody = $reader.ReadToEnd()
                    }
                }
                catch {}
            }
        }

        [pscustomobject]@{
            Ok          = $false
            Url         = $Url
            RequestBody = $json
            StatusCode  = $statusCode
            Data        = $null
            ErrorText   = $errorText
            ErrorBody   = $errorBody
        }
    }
}


function Wait-HttpReady {
    param(
        [string]$Url,
        [int]$MaxAttempts = 40,
        [int]$DelaySeconds = 3
    )

    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 5 | Out-Null
            Write-Host "READY: $Url" -ForegroundColor Green
            return
        }
        catch {
            Write-Host ("WAIT  : " + $Url + " (attempt " + $i + "/" + $MaxAttempts + ")") -ForegroundColor Yellow
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    throw "Service is not ready: $Url"
}
function Require-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name"
    }
}

function Show-ProcessingLog {
    $pg = docker compose ps -q postgres
    if (-not $pg) {
        throw "Postgres container not found"
    }

    docker exec -i $pg psql -U appuser -d appdb -c "select id, user_email, input_text, output_text, created_at from processinglog order by id desc limit 10;"
}

function Show-ServiceLogs {
    param(
        [string[]]$Services = @("auth-api", "data-api"),
        [int]$Tail = 80
    )

    foreach ($service in $Services) {
        Write-Host "`n--- LOGS: $service (last $Tail lines) ---" -ForegroundColor DarkYellow
        docker compose logs --tail $Tail $service
    }
}

Require-Command mvn
Require-Command docker

if ($RunMavenTests) {
    Write-Step "MAVEN TESTS"
    mvn -f .\data-api\pom.xml test
    if ($LASTEXITCODE -ne 0) { throw "data-api tests failed" }

    mvn -f .\auth-api\pom.xml test
    if ($LASTEXITCODE -ne 0) { throw "auth-api tests failed" }
}

if ($RebuildAndRestart) {
    Write-Step "MAVEN PACKAGE"
    mvn -f .\data-api\pom.xml clean package -DskipTests
    if ($LASTEXITCODE -ne 0) { throw "data-api package failed" }

    mvn -f .\auth-api\pom.xml clean package -DskipTests
    if ($LASTEXITCODE -ne 0) { throw "auth-api package failed" }

    Write-Step "DOCKER COMPOSE RESTART"
    docker compose down
    if ($LASTEXITCODE -ne 0) { throw "docker compose down failed" }

    docker compose up -d --build
    if ($LASTEXITCODE -ne 0) { throw "docker compose up failed" }

    Start-Sleep -Seconds 15
}

Write-Step "HTTP PREFLIGHT"
Wait-HttpReady -Url "http://127.0.0.1:8080/health"
Wait-HttpReady -Url "http://127.0.0.1:8081/health"

Write-Step "AUTH REGISTER"
$register = Invoke-JsonPost -Url "$BaseUrl/api/auth/register" -Body @{
    email = $Email
    password = $Password
}

if ($register.Ok) {
    Write-Host "Register OK" -ForegroundColor Green
}
else {
    Write-Host "Register skipped/failed" -ForegroundColor Yellow
    if ($register.StatusCode) {
        Write-Host ("STATUS : " + $register.StatusCode) -ForegroundColor Yellow
    }
    if ($register.ErrorBody) {
        Write-Host ("BODY   : " + $register.ErrorBody) -ForegroundColor DarkYellow
    }
}

Write-Step "AUTH LOGIN"
$loginResult = Invoke-JsonPost -Url "$BaseUrl/api/auth/login" -Body @{
    email = $Email
    password = $Password
}

if (-not $loginResult.Ok) {
    if ($loginResult.StatusCode) {
        Write-Host ("STATUS : " + $loginResult.StatusCode) -ForegroundColor Red
    }
    Write-Host ("ERROR  : " + $loginResult.ErrorText) -ForegroundColor Red
    if ($loginResult.ErrorBody) {
        Write-Host ("BODY   : " + $loginResult.ErrorBody) -ForegroundColor Red
    }
    Show-ServiceLogs -Services @("auth-api") -Tail 120
    throw "Login failed"
}

$login = $loginResult.Data

if (-not $login.token) {
    throw "Login failed: token not returned"
}

$token = $login.token
$headers = @{ Authorization = "Bearer $token" }

Write-Host "Login OK" -ForegroundColor Green
Write-Host ("Token prefix: " + $token.Substring(0, [Math]::Min(20, $token.Length)) + "...") -ForegroundColor DarkGray

Write-Step "PROCESS FLOW"
foreach ($text in $Texts) {
    $result = Invoke-JsonPost -Url "$BaseUrl/api/process" -Headers $headers -Body @{ text = $text }

    Write-Host ("INPUT        : " + $text) -ForegroundColor DarkCyan
    Write-Host ("REQUEST URL  : " + $result.Url) -ForegroundColor DarkGray
    Write-Host ("REQUEST BODY : " + $result.RequestBody) -ForegroundColor DarkGray

    if ($result.Ok) {
        Write-Host ("STATUS       : " + $result.StatusCode) -ForegroundColor Green
        Write-Host ("OUTPUT       : " + ($result.Data | ConvertTo-Json -Compress -Depth 10)) -ForegroundColor Green
    }
    else {
        if ($result.StatusCode) {
            Write-Host ("STATUS       : " + $result.StatusCode) -ForegroundColor Red
        }
        Write-Host "OUTPUT       : FAILED" -ForegroundColor Red
        Write-Host ("ERROR        : " + $result.ErrorText) -ForegroundColor Red

        if ($result.ErrorBody) {
            Write-Host ("ERROR BODY   : " + $result.ErrorBody) -ForegroundColor Red
        }

        if ($result.StatusCode -ge 500) {
            Show-ServiceLogs -Services @("auth-api", "data-api") -Tail 120
        }
    }
}

Write-Step "INTERNAL TOKEN CHECK"
if ([string]::IsNullOrWhiteSpace($env:INTERNAL_TOKEN)) {
    Write-Host "Skipped: env INTERNAL_TOKEN is not set" -ForegroundColor Yellow
}
else {
    $body = @{ text = "backend test" } | ConvertTo-Json -Compress

    try {
        Invoke-WebRequest -Method Post `
            -Uri "$DataApiUrl/api/transform" `
            -ContentType "application/json" `
            -Body $body | Out-Null
        Write-Host "FAIL: request without header unexpectedly succeeded" -ForegroundColor Red
    }
    catch {
        Write-Host "OK: request without header rejected" -ForegroundColor Green
    }

    try {
        Invoke-WebRequest -Method Post `
            -Uri "$DataApiUrl/api/transform" `
            -ContentType "application/json" `
            -Headers @{ "X-Internal-Token" = "wrong-token" } `
            -Body $body | Out-Null
        Write-Host "FAIL: request with invalid header unexpectedly succeeded" -ForegroundColor Red
    }
    catch {
        Write-Host "OK: request with invalid header rejected" -ForegroundColor Green
    }

    try {
        $transformResponse = Invoke-RestMethod -Method Post `
            -Uri "$DataApiUrl/api/transform" `
            -ContentType "application/json" `
            -Headers @{ "X-Internal-Token" = $env:INTERNAL_TOKEN } `
            -Body $body

        Write-Host ("VALID HEADER OUTPUT : " + ($transformResponse | ConvertTo-Json -Compress)) -ForegroundColor Green
    }
    catch {
        Write-Host "FAIL: request with valid header was rejected" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Step "PROCESSING LOG"
Show-ProcessingLog

Write-Step "DONE"
Write-Host "All checks completed" -ForegroundColor Green


