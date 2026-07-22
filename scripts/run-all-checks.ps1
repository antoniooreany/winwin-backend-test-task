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

    Invoke-RestMethod -Method Post `
        -Uri $Url `
        -ContentType "application/json" `
        -Headers $Headers `
        -Body ($Body | ConvertTo-Json -Compress)
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
    docker compose down -v
    if ($LASTEXITCODE -ne 0) { throw "docker compose down failed" }

    docker compose up -d --build
    if ($LASTEXITCODE -ne 0) { throw "docker compose up failed" }

    Start-Sleep -Seconds 15
}

Write-Step "HTTP PREFLIGHT"

$authPort = Test-NetConnection localhost -Port 8080 -WarningAction SilentlyContinue
$dataPort = Test-NetConnection localhost -Port 8081 -WarningAction SilentlyContinue

if (-not $authPort.TcpTestSucceeded) {
    throw "auth-api is not reachable on localhost:8080"
}

if (-not $dataPort.TcpTestSucceeded) {
    Write-Host "Warning: data-api is not reachable on localhost:8081" -ForegroundColor Yellow
}

Write-Step "AUTH REGISTER"
try {
    $null = Invoke-JsonPost -Url "$BaseUrl/api/auth/register" -Body @{
        email = $Email
        password = $Password
    }
    Write-Host "Register OK" -ForegroundColor Green
}
catch {
    Write-Host "Register skipped (user may already exist)" -ForegroundColor Yellow
}

Write-Step "AUTH LOGIN"
$login = Invoke-JsonPost -Url "$BaseUrl/api/auth/login" -Body @{
    email = $Email
    password = $Password
}

if (-not $login.token) {
    throw "Login failed: token not returned"
}

$token = $login.token
$headers = @{ Authorization = "Bearer $token" }

Write-Host "Login OK" -ForegroundColor Green
Write-Host ("Token prefix: " + $token.Substring(0, [Math]::Min(20, $token.Length)) + "...") -ForegroundColor DarkGray

Write-Step "PROCESS FLOW"
foreach ($text in $Texts) {
    Remove-Variable response -ErrorAction SilentlyContinue

    try {
        $response = Invoke-JsonPost -Url "$BaseUrl/api/process" -Headers $headers -Body @{ text = $text }

        Write-Host ("INPUT  : " + $text) -ForegroundColor DarkCyan
        Write-Host ("OUTPUT : " + ($response | ConvertTo-Json -Compress)) -ForegroundColor Green
    }
    catch {
        Write-Host ("INPUT  : " + $text) -ForegroundColor DarkCyan
        Write-Host "OUTPUT : FAILED" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
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
