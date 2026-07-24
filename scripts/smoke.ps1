$ErrorActionPreference = "Stop"

function Write-Result {
    param(
        [string]$Status,
        [string]$Message
    )
    Write-Host "[$Status] $Message"
}

function Invoke-JsonRequest {
    param(
        [string]$Method,
        [string]$Uri,
        [object]$Body = $null,
        [hashtable]$Headers = @{}
    )

    $params = @{
        Method      = $Method
        Uri         = $Uri
        Headers     = $Headers
        ErrorAction = "Stop"
    }

    if ($null -ne $Body) {
        $params["ContentType"] = "application/json"
        $params["Body"] = ($Body | ConvertTo-Json -Compress)
    }

    Invoke-RestMethod @params
}

$passed = 0
$failed = 0

Write-Host ""
Write-Host "== Git sanity check =="
git status --short
if ($LASTEXITCODE -eq 0) {
    Write-Result "PASS" "Git status checked"
    $passed++
} else {
    Write-Result "FAIL" "Git status could not be checked"
    $failed++
}

Write-Host ""
Write-Host "== Ensure service JAR files exist =="
if ((Test-Path ".\auth-api\target\auth-api-0.0.1-SNAPSHOT.jar") -and (Test-Path ".\data-api\target\data-api-0.0.1-SNAPSHOT.jar")) {
    Write-Result "PASS" "Required JAR files are available"
    $passed++
} else {
    Write-Result "FAIL" "Required JAR files are missing. Build the services first."
    $failed++
    exit 1
}

Write-Host ""
Write-Host "== Docker Compose reset =="
docker compose down -v
docker compose up -d --build
if ($LASTEXITCODE -eq 0) {
    Write-Result "PASS" "Docker Compose started"
    $passed++
} else {
    Write-Result "FAIL" "Docker Compose startup failed"
    $failed++
    exit 1
}

Write-Host ""
Write-Host "== Wait for services =="
$authReady = $false
$dataReady = $false

for ($i = 0; $i -lt 30; $i++) {
    try {
        $authHealth = Invoke-RestMethod -Method GET -Uri "http://localhost:8080/health" -ErrorAction Stop
        if ($authHealth.status -eq "ok" -and $authHealth.service -eq "auth-api") {
            $authReady = $true
            break
        }
    } catch {}
    Start-Sleep -Seconds 2
}

for ($i = 0; $i -lt 30; $i++) {
    try {
        $dataHealth = Invoke-RestMethod -Method GET -Uri "http://localhost:8081/health" -ErrorAction Stop
        if ($dataHealth.status -eq "ok" -and $dataHealth.service -eq "data-api") {
            $dataReady = $true
            break
        }
    } catch {}
    Start-Sleep -Seconds 2
}

if ($authReady) { Write-Result "PASS" "auth-api health is ready"; $passed++ } else { Write-Result "FAIL" "auth-api health is not ready"; $failed++ }
if ($dataReady) { Write-Result "PASS" "data-api health is ready"; $passed++ } else { Write-Result "FAIL" "data-api health is not ready"; $failed++ }

if (-not ($authReady -and $dataReady)) {
    docker compose logs
    docker compose down
    exit 1
}

Write-Host ""
Write-Host "== Register user =="
$email = "reviewer@example.com"
$password = "Pass12345!"
try {
    $null = Invoke-WebRequest -Method POST -Uri "http://localhost:8080/api/auth/register" -ContentType "application/json" -Body (@{ email = $email; password = $password } | ConvertTo-Json -Compress) -ErrorAction Stop
    Write-Result "PASS" "User registration request succeeded"
    $passed++
} catch {
    Write-Result "FAIL" "User registration request failed"
    $failed++
}

Write-Host ""
Write-Host "== Login user =="
$token = $null
try {
    $login = Invoke-JsonRequest -Method POST -Uri "http://localhost:8080/api/auth/login" -Body @{ email = $email; password = $password }
    $token = $login.token
    if ($token) {
        Write-Result "PASS" "Login request succeeded"
        $passed++
        Write-Result "PASS" "JWT token received"
        $passed++
    } else {
        Write-Result "FAIL" "JWT token was not returned"
        $failed++
    }
} catch {
    Write-Result "FAIL" "Login request failed"
    $failed++
}

Write-Host ""
Write-Host "== Call protected process endpoint =="
try {
    $process = Invoke-JsonRequest -Method POST -Uri "http://localhost:8080/api/process" -Headers @{ Authorization = "Bearer $token" } -Body @{ text = "hello" }
    if ($null -ne $process) {
        Write-Result "PASS" "Protected endpoint accepted JWT"
        $passed++
        Write-Result "PASS" "Protected endpoint returned a response body"
        $passed++
    } else {
        Write-Result "FAIL" "Protected endpoint returned no body"
        $failed++
    }
} catch {
    Write-Result "FAIL" "Protected endpoint request failed"
    $failed++
}

Write-Host ""
Write-Host "== Negative check without JWT =="
try {
    $null = Invoke-JsonRequest -Method POST -Uri "http://localhost:8080/api/process" -Body @{ text = "hello" }
    Write-Result "FAIL" "Protected endpoint accepted request without JWT"
    $failed++
} catch {
    $code = $null
    try { $code = [int]$_.Exception.Response.StatusCode } catch {}
    if ($code -eq 403) {
        Write-Result "PASS" "Protected endpoint correctly rejected request without JWT (403)"
        $passed++
    } else {
        Write-Result "FAIL" "Protected endpoint rejected request, but status was not 403"
        $failed++
    }
}

Write-Host ""
Write-Host "== Negative check: direct access to data-api =="
try {
    $null = Invoke-JsonRequest -Method POST -Uri "http://localhost:8081/api/transform" -Body @{ text = "hello" }
    Write-Result "FAIL" "data-api accepted direct request without internal token"
    $failed++
} catch {
    $code = $null
    try { $code = [int]$_.Exception.Response.StatusCode } catch {}
    if ($code -eq 403) {
        Write-Result "PASS" "data-api correctly rejected direct access without internal token (403)"
        $passed++
    } else {
        Write-Result "FAIL" "data-api rejected request, but status was not 403"
        $failed++
    }
}

Write-Host ""
Write-Host "=============================="
Write-Host "Smoke Test Summary"
Write-Host "Passed: $passed"
Write-Host "Failed: $failed"
if ($failed -eq 0) {
    Write-Host "RESULT: PASS"
} else {
    Write-Host "RESULT: FAIL"
}

Write-Host ""
Write-Host "== Docker Compose shutdown =="
docker compose down
if ($LASTEXITCODE -eq 0) {
    Write-Result "PASS" "Docker Compose stopped"
} else {
    Write-Result "FAIL" "Docker Compose shutdown failed"
}
Write-Host "=============================="
