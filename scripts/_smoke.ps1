param(
    [switch]$SkipDockerStart,
    [switch]$KeepRunning,
    [switch]$VerboseLogs,
    [switch]$RunMavenTests,
    [int]$DockerTimeoutSec = 120,
    [int]$HealthTimeoutSec = 90,
    [int]$LogTail = 100
)

$ErrorActionPreference = "Stop"

$AuthBase = "http://localhost:8080"
$DataBase = "http://localhost:8081"

$RegisterEndpoint = "$AuthBase/api/auth/register"
$LoginEndpoint    = "$AuthBase/api/auth/login"
$ProcessEndpoint  = "$AuthBase/api/process"

$AuthHealth = "$AuthBase/actuator/health"
$DataHealth = "$DataBase/actuator/health"

$TestEmail = "smoke.user.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())@example.com"
$TestPassword = "Password123!"

$Passed = 0
$Failed = 0
$ComposeStarted = $false
$SmokeFailed = $false
$StepResults = @()

$outputDir = Join-Path $PSScriptRoot "..\output"
$null = New-Item -ItemType Directory -Force -Path $outputDir
$LogFile = Join-Path $outputDir "smoke-logs.txt"

"" | Set-Content -Path $LogFile

function Write-LogLine([string]$message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $message"
    $line | Tee-Object -FilePath $LogFile -Append
}

function Pass($msg) {
    $script:Passed++
    Write-Host "[PASS] $msg" -ForegroundColor Green
    Write-LogLine "[PASS] $msg" | Out-Null
}

function Fail($msg) {
    $script:Failed++
    $script:SmokeFailed = $true
    Write-Host "[FAIL] $msg" -ForegroundColor Red
    Write-LogLine "[FAIL] $msg" | Out-Null
}

function Info($msg) {
    Write-Host "[INFO] $msg" -ForegroundColor Yellow
    Write-LogLine "[INFO] $msg" | Out-Null
}

function Step($msg) {
    Write-Host "`n== $msg ==" -ForegroundColor Cyan
    Write-LogLine ""
    Write-LogLine "== $msg ==" | Out-Null
}

function Add-StepResult($name, $status, $details) {
    $script:StepResults += [PSCustomObject]@{
        Step    = $name
        Status  = $status
        Details = $details
    }
}

function Assert-True($condition, $successMsg, $failMsg) {
    if ($condition) {
        Pass $successMsg
        return $true
    }

    Fail $failMsg
    return $false
}

function Test-CommandAvailable($name) {
    return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function Test-DockerReady {
    try {
        docker info *> $null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Get-DockerOsType {
    try {
        $osType = docker info --format '{{.OSType}}' 2>$null
        if ($LASTEXITCODE -eq 0) {
            return ($osType | Out-String).Trim()
        }
    } catch {
    }

    return $null
}

function Get-DockerCurrentContext {
    try {
        $current = docker context ls --format '{{if .Current}}{{.Name}}{{end}}' 2>$null |
            Where-Object { $_ -and $_.Trim().Length -gt 0 } |
            Select-Object -First 1

        if ($LASTEXITCODE -eq 0 -and $current) {
            return $current.Trim()
        }
    } catch {
    }

    return $null
}

function Test-DockerContextExists($contextName) {
    try {
        $contexts = docker context ls --format '{{.Name}}' 2>$null
        if ($LASTEXITCODE -ne 0) {
            return $false
        }

        return ($contexts | Where-Object { $_.Trim() -eq $contextName } | Measure-Object).Count -gt 0
    } catch {
        return $false
    }
}

function Set-DockerLinuxContext {
    $currentContext = Get-DockerCurrentContext
    $osType = Get-DockerOsType

    if ($osType -eq "linux") {
        Pass "Docker engine OS type is linux"
        if ($currentContext) {
            Info "Current Docker context: $currentContext"
        }
        return $true
    }

    Info "Docker engine OS type is '$osType'"
    Info "Attempting to switch Docker context to desktop-linux..."

    if (-not (Test-DockerContextExists "desktop-linux")) {
        Fail "Docker context 'desktop-linux' was not found"
        return $false
    }

    try {
        docker context use desktop-linux | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Fail "Failed to switch Docker context to desktop-linux"
            return $false
        }
    } catch {
        Fail "Failed to switch Docker context to desktop-linux: $($_.Exception.Message)"
        return $false
    }

    Start-Sleep -Seconds 3

    $newContext = Get-DockerCurrentContext
    $newOsType = Get-DockerOsType

    if ($newContext -eq "desktop-linux") {
        Pass "Docker context switched to desktop-linux"
    } else {
        Fail "Docker context switch did not take effect"
        return $false
    }

    if ($newOsType -eq "linux") {
        Pass "Docker engine OS type is linux after context switch"
        return $true
    }

    Fail "Docker engine is still not using linux containers"
    return $false
}

function Start-DockerIfNeeded([int]$timeoutSec = 120) {
    if (Test-DockerReady) {
        Pass "Docker daemon is available"
        return $true
    }

    if ($SkipDockerStart) {
        Fail "Docker daemon is not available and -SkipDockerStart was specified"
        return $false
    }

    Info "Docker daemon is not available. Attempting to start Docker Desktop..."

    $dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"

    if (Test-Path $dockerDesktopPath) {
        try {
            Start-Process $dockerDesktopPath | Out-Null
            Info "Docker Desktop launch command sent"
        } catch {
            Fail "Failed to launch Docker Desktop: $($_.Exception.Message)"
            return $false
        }
    } else {
        Fail "Docker daemon is unavailable and Docker Desktop was not found at: $dockerDesktopPath"
        return $false
    }

    $start = Get-Date
    while (((Get-Date) - $start).TotalSeconds -lt $timeoutSec) {
        Start-Sleep -Seconds 3
        if (Test-DockerReady) {
            Pass "Docker daemon became available"
            return $true
        }
    }

    Fail "Docker daemon did not become available within $timeoutSec sec"
    return $false
}

function Test-DockerComposeConfig {
    Step "Docker Compose config precheck"

    try {
        docker compose config | Tee-Object -FilePath $LogFile -Append | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Pass "docker compose config succeeded"
            Add-StepResult -name "Compose config precheck" -status "PASS" -details "docker compose config succeeded"
            return $true
        }

        Fail "docker compose config failed"
        Add-StepResult -name "Compose config precheck" -status "FAIL" -details "docker compose config failed"
        return $false
    } catch {
        Fail "docker compose config failed: $($_.Exception.Message)"
        Add-StepResult -name "Compose config precheck" -status "FAIL" -details $_.Exception.Message
        return $false
    }
}

function Wait-HttpOk($url, $name, $timeoutSec = 90) {
    $start = Get-Date

    while (((Get-Date) - $start).TotalSeconds -lt $timeoutSec) {
        try {
            $resp = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 5
            if ($resp.status -eq "UP") {
                Pass "$name health is UP"
                return $true
            }
        } catch {
            Start-Sleep -Seconds 2
        }
    }

    Fail "$name health did not become UP within $timeoutSec sec"
    return $false
}

function Show-DockerComposeLogs([int]$tail = 100) {
    Step "Docker Compose logs"

    try {
        docker compose ps | Tee-Object -FilePath $LogFile -Append
    } catch {
        Info "docker compose ps failed"
    }

    try {
        docker compose logs --tail $tail | Tee-Object -FilePath $LogFile -Append
    } catch {
        Info "docker compose logs failed"
    }
}

function Invoke-MavenTests($pomPath, $moduleName) {
    Step "Maven tests: $moduleName"

    try {
        mvn -f $pomPath test | Tee-Object -FilePath $LogFile -Append
        if ($LASTEXITCODE -eq 0) {
            Pass "$moduleName tests passed"
            Add-StepResult -name "Maven tests: $moduleName" -status "PASS" -details "mvn test passed"
            return $true
        }

        Fail "$moduleName tests failed"
        Add-StepResult -name "Maven tests: $moduleName" -status "FAIL" -details "mvn test failed"
        return $false
    } catch {
        Fail "$moduleName tests failed: $($_.Exception.Message)"
        Add-StepResult -name "Maven tests: $moduleName" -status "FAIL" -details $_.Exception.Message
        return $false
    }
}

try {
    Step "Git sanity check"
    git status | Tee-Object -FilePath $LogFile -Append
    if ($LASTEXITCODE -ne 0) {
        Fail "git status failed"
        Add-StepResult -name "Git sanity check" -status "FAIL" -details "git status failed"
        throw "git status failed"
    }
    Pass "Repository is accessible"
    Add-StepResult -name "Git sanity check" -status "PASS" -details "Repository is accessible"

    Step "Working tree check"
    $gitStatusPorcelain = git status --porcelain
    if ($LASTEXITCODE -ne 0) {
        Info "Could not evaluate working tree status"
        Add-StepResult -name "Working tree check" -status "WARN" -details "Could not evaluate working tree status"
    } elseif ([string]::IsNullOrWhiteSpace(($gitStatusPorcelain | Out-String))) {
        Pass "Working tree is clean"
        Add-StepResult -name "Working tree check" -status "PASS" -details "Working tree is clean"
    } else {
        Info "Working tree has uncommitted changes"
        Add-StepResult -name "Working tree check" -status "WARN" -details "Working tree has uncommitted changes"
    }

    Step "Tooling check"
    if (-not (Test-CommandAvailable "git")) {
        Fail "git command is not available"
        Add-StepResult -name "Tooling check" -status "FAIL" -details "git command is not available"
        throw "git command is not available"
    }
    if (-not (Test-CommandAvailable "docker")) {
        Fail "docker command is not available"
        Add-StepResult -name "Tooling check" -status "FAIL" -details "docker command is not available"
        throw "docker command is not available"
    }
    if ($RunMavenTests -and -not (Test-CommandAvailable "mvn")) {
        Fail "mvn command is not available"
        Add-StepResult -name "Tooling check" -status "FAIL" -details "mvn command is not available"
        throw "mvn command is not available"
    }
    Pass "Required commands are available"
    Add-StepResult -name "Tooling check" -status "PASS" -details "Required commands are available"

    if ($RunMavenTests) {
        $authTestsOk = Invoke-MavenTests -pomPath "auth-api/pom.xml" -moduleName "auth-api"
        if (-not $authTestsOk) {
            throw "auth-api Maven tests failed"
        }

        $dataTestsOk = Invoke-MavenTests -pomPath "data-api/pom.xml" -moduleName "data-api"
        if (-not $dataTestsOk) {
            throw "data-api Maven tests failed"
        }
    }

    Step "Docker readiness"
    if (-not (Start-DockerIfNeeded -timeoutSec $DockerTimeoutSec)) {
        Add-StepResult -name "Docker readiness" -status "FAIL" -details "Docker daemon is not available"
        throw "Docker daemon is not available"
    }
    Add-StepResult -name "Docker readiness" -status "PASS" -details "Docker daemon is available"

    Step "Docker Linux engine check"
    if (-not (Set-DockerLinuxContext)) {
        Add-StepResult -name "Docker Linux engine check" -status "FAIL" -details "Docker is not using the Linux engine/context required by this project"
        throw "Docker is not using the Linux engine/context required by this project"
    }
    Add-StepResult -name "Docker Linux engine check" -status "PASS" -details "Linux engine/context is active"

    if (-not (Test-DockerComposeConfig)) {
        throw "Docker Compose config precheck failed"
    }

    Step "Docker Compose reset"
    try {
        docker compose down --remove-orphans | Tee-Object -FilePath $LogFile -Append | Out-Null
    } catch {
        Info "docker compose down returned an error before startup; continuing"
    }

    docker compose up --build -d | Tee-Object -FilePath $LogFile -Append
    if ($LASTEXITCODE -ne 0) {
        Fail "Docker Compose failed to start"
        Add-StepResult -name "Docker Compose startup" -status "FAIL" -details "docker compose up failed"
        throw "docker compose up failed"
    }

    $script:ComposeStarted = $true
    Pass "Docker Compose started"
    Add-StepResult -name "Docker Compose startup" -status "PASS" -details "docker compose up succeeded"

    Step "Wait for services"
    $authUp = Wait-HttpOk -url $AuthHealth -name "auth-api" -timeoutSec $HealthTimeoutSec
    $dataUp = Wait-HttpOk -url $DataHealth -name "data-api" -timeoutSec $HealthTimeoutSec

    if (-not ($authUp -and $dataUp)) {
        Add-StepResult -name "Wait for services" -status "FAIL" -details "One or more services did not become healthy"
        throw "One or more services did not become healthy"
    }
    Add-StepResult -name "Wait for services" -status "PASS" -details "Both services became healthy"

    Step "Register user"
    $registerBody = @{
        email = $TestEmail
        password = $TestPassword
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Uri $RegisterEndpoint -Method Post -ContentType "application/json" -Body $registerBody -TimeoutSec 15 | Out-Null
        Pass "User registration request succeeded"
        Add-StepResult -name "Register user" -status "PASS" -details "Registration succeeded"
    } catch {
        Fail "User registration request failed: $($_.Exception.Message)"
        Add-StepResult -name "Register user" -status "FAIL" -details $_.Exception.Message
        throw
    }

    Step "Login user"
    $loginBody = @{
        email = $TestEmail
        password = $TestPassword
    } | ConvertTo-Json

    try {
        $loginResp = Invoke-RestMethod -Uri $LoginEndpoint -Method Post -ContentType "application/json" -Body $loginBody -TimeoutSec 15
        Pass "Login request succeeded"
        Add-StepResult -name "Login user" -status "PASS" -details "Login succeeded"
    } catch {
        Fail "Login request failed: $($_.Exception.Message)"
        Add-StepResult -name "Login user" -status "FAIL" -details $_.Exception.Message
        throw
    }

    $jwt = $null
    if ($loginResp.token) {
        $jwt = $loginResp.token
    } elseif ($loginResp.accessToken) {
        $jwt = $loginResp.accessToken
    } elseif ($loginResp.jwt) {
        $jwt = $loginResp.jwt
    }

    if (-not (Assert-True ($null -ne $jwt -and $jwt.Length -gt 20) "JWT token received" "JWT token not found in login response")) {
        Add-StepResult -name "JWT extraction" -status "FAIL" -details "JWT token not found in login response"
        throw "No JWT token in login response"
    }
    Add-StepResult -name "JWT extraction" -status "PASS" -details "JWT token received"

    Step "Call protected process endpoint"
    $processBody = @{
        text = "Hello from smoke test"
    } | ConvertTo-Json

    try {
        $processResp = Invoke-RestMethod `
            -Uri $ProcessEndpoint `
            -Method Post `
            -ContentType "application/json" `
            -Headers @{ Authorization = "Bearer $jwt" } `
            -Body $processBody `
            -TimeoutSec 20

        Pass "Protected endpoint accepted JWT"
    } catch {
        Fail "Protected endpoint failed with JWT: $($_.Exception.Message)"
        Add-StepResult -name "Protected endpoint with JWT" -status "FAIL" -details $_.Exception.Message
        throw
    }

    if (-not (Assert-True ($null -ne $processResp) "Protected endpoint returned a response body" "Protected endpoint response body is empty")) {
        Add-StepResult -name "Protected endpoint with JWT" -status "FAIL" -details "Empty response body"
        throw "Protected endpoint response body is empty"
    }

    $hasExpectedField = $false
    if ($null -ne $processResp.PSObject.Properties["result"]) {
        $hasExpectedField = $true
    }

    if (-not (Assert-True $hasExpectedField "Protected endpoint returned expected field 'result'" "Protected endpoint response does not contain expected field 'result'")) {
        Add-StepResult -name "Protected endpoint with JWT" -status "FAIL" -details "Expected field 'result' is missing"
        throw "Protected endpoint response does not contain expected field 'result'"
    }

    Add-StepResult -name "Protected endpoint with JWT" -status "PASS" -details "Protected endpoint returned expected field 'result'"

    Step "Negative check without JWT"
    try {
        Invoke-RestMethod -Uri $ProcessEndpoint -Method Post -ContentType "application/json" -Body $processBody -TimeoutSec 15 | Out-Null
        Fail "Protected endpoint unexpectedly allowed request without JWT"
        Add-StepResult -name "Negative check without JWT" -status "FAIL" -details "Unauthenticated request unexpectedly succeeded"
    } catch {
        $statusCode = $null

        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }

        if ($statusCode -eq 401 -or $statusCode -eq 403) {
            Pass "Protected endpoint correctly rejected request without JWT ($statusCode)"
            Add-StepResult -name "Negative check without JWT" -status "PASS" -details "Rejected with status $statusCode"
        } else {
            Fail "Protected endpoint rejected unauthenticated request with unexpected status: $statusCode"
            Add-StepResult -name "Negative check without JWT" -status "FAIL" -details "Unexpected status $statusCode"
        }
    }
}
catch {
    if ($_.Exception.Message) {
        Fail "Smoke test terminated with error: $($_.Exception.Message)"
    } else {
        Fail "Smoke test terminated with an unknown error"
    }

    if ($ComposeStarted -or $VerboseLogs) {
        Show-DockerComposeLogs -tail $LogTail
    }
}
finally {
    if ($KeepRunning) {
        Info "Docker Compose is left running because -KeepRunning was specified"
        Add-StepResult -name "Docker Compose shutdown" -status "SKIP" -details "Skipped because -KeepRunning was specified"
    } else {
        Step "Docker Compose shutdown"

        if ($ComposeStarted) {
            try {
                docker compose down | Tee-Object -FilePath $LogFile -Append | Out-Null
                Pass "Docker Compose stopped"
                Add-StepResult -name "Docker Compose shutdown" -status "PASS" -details "docker compose down succeeded"
            } catch {
                Fail "Docker Compose shutdown failed: $($_.Exception.Message)"
                Add-StepResult -name "Docker Compose shutdown" -status "FAIL" -details $_.Exception.Message
            }
        } else {
            Info "Docker Compose was not started, shutdown skipped"
            Add-StepResult -name "Docker Compose shutdown" -status "SKIP" -details "Compose was not started"
        }
    }

    Step "Step summary"
    $StepResults | Format-Table -AutoSize | Out-String | Tee-Object -FilePath $LogFile -Append | Write-Host

    Write-Host "`n==============================" -ForegroundColor White
    Write-Host "Smoke Test Summary" -ForegroundColor White
    Write-Host "Passed: $Passed" -ForegroundColor Green
    Write-Host "Failed: $Failed" -ForegroundColor Red
    Write-Host "Log file: $LogFile" -ForegroundColor White

    if ($Failed -eq 0) {
        Write-Host "RESULT: PASS" -ForegroundColor Green
        Write-Host "==============================" -ForegroundColor White
        exit 0
    } else {
        Write-Host "RESULT: FAIL" -ForegroundColor Red
        Write-Host "==============================" -ForegroundColor White
        exit 1
    }
}