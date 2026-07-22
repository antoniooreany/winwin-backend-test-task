$ErrorActionPreference = "Stop"

$AuthBase = "http://localhost:8080"
$DataBase = "http://localhost:8081"

$RegisterEndpoint = "$AuthBase/api/auth/register"
$LoginEndpoint    = "$AuthBase/api/auth/login"
$ProcessEndpoint  = "$AuthBase/api/process"
$TransformEndpoint = "$DataBase/api/transform"
$AuthHealth       = "$AuthBase/health"
$DataHealth       = "$DataBase/health"

$TestEmail = "smoke.user.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())@example.com"
$TestPassword = "Password123!"

$Passed = 0
$Failed = 0
$KeepContainersOnFailure = $true

function Pass($msg) {
  $script:Passed++
  Write-Host "[PASS] $msg" -ForegroundColor Green
}

function Fail($msg) {
  $script:Failed++
  Write-Host "[FAIL] $msg" -ForegroundColor Red
}

function Step($msg) {
  Write-Host "`n== $msg ==" -ForegroundColor Cyan
}

function Assert-True($condition, $successMsg, $failMsg) {
  if ($condition) {
    Pass $successMsg
  }
  else {
    Fail $failMsg
  }
}

function Wait-HttpOk($url, $name, $timeoutSec = 90) {
  $start = Get-Date

  while (((Get-Date) - $start).TotalSeconds -lt $timeoutSec) {
    try {
      $resp = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 5
      $body = $resp.Content

      if ($resp.StatusCode -eq 200) {
        try {
          $json = $body | ConvertFrom-Json
          if ($json.status -eq "ok" -or $json.status -eq "OK" -or $json.status -eq "up" -or $json.status -eq "UP") {
            Pass "$name health is ready"
            return $true
          }
        }
        catch {
          Pass "$name health endpoint returned HTTP 200"
          return $true
        }
      }
    }
    catch {
      Start-Sleep -Seconds 2
    }
  }

  Fail "$name health did not become ready within $timeoutSec sec"
  return $false
}

try {
  Step "Git sanity check"
  $gitStatus = git status --porcelain
  if ($LASTEXITCODE -ne 0) { throw "git status failed" }

  if ([string]::IsNullOrWhiteSpace(($gitStatus | Out-String))) {
    Pass "Working tree is clean"
  }
  else {
    Write-Host "[WARN] Working tree is not clean" -ForegroundColor Yellow
    $gitStatus
  }

  Step "Ensure service JAR files exist"
  if (-not (Test-Path "auth-api/target/auth-api-0.0.1-SNAPSHOT.jar")) {
    Write-Host "[INFO] Building auth-api JAR" -ForegroundColor Cyan
    mvn -f auth-api/pom.xml clean package -DskipTests
    if ($LASTEXITCODE -ne 0) { throw "auth-api build failed" }
  }

  if (-not (Test-Path "data-api/target/data-api-0.0.1-SNAPSHOT.jar")) {
    Write-Host "[INFO] Building data-api JAR" -ForegroundColor Cyan
    mvn -f data-api/pom.xml clean package -DskipTests
    if ($LASTEXITCODE -ne 0) { throw "data-api build failed" }
  }

  Pass "Required JAR files are available"

  Step "Docker Compose reset"
  docker compose down -v --remove-orphans | Out-Null
  docker compose up --build -d
  if ($LASTEXITCODE -ne 0) { throw "docker compose up failed" }
  Pass "Docker Compose started"

  Step "Wait for services"
  $authUp = Wait-HttpOk -url $AuthHealth -name "auth-api"
  $dataUp = Wait-HttpOk -url $DataHealth -name "data-api"

  if (-not ($authUp -and $dataUp)) {
    throw "One or more services did not become healthy"
  }

  Step "Register user"
  $registerBody = @{
    email    = $TestEmail
    password = $TestPassword
  } | ConvertTo-Json -Compress

  try {
    $registerResp = Invoke-RestMethod `
      -Uri $RegisterEndpoint `
      -Method Post `
      -ContentType "application/json" `
      -Body $registerBody `
      -TimeoutSec 15
    Pass "User registration request succeeded"
  }
  catch {
    Fail "User registration request failed: $($_.Exception.Message)"
    throw
  }

  Step "Login user"
  $loginBody = @{
    email    = $TestEmail
    password = $TestPassword
  } | ConvertTo-Json -Compress

  try {
    $loginResp = Invoke-RestMethod `
      -Uri $LoginEndpoint `
      -Method Post `
      -ContentType "application/json" `
      -Body $loginBody `
      -TimeoutSec 15
    Pass "Login request succeeded"
  }
  catch {
    Fail "Login request failed: $($_.Exception.Message)"
    throw
  }

  $jwt = $null
  if ($loginResp.token) { $jwt = $loginResp.token }
  elseif ($loginResp.accessToken) { $jwt = $loginResp.accessToken }
  elseif ($loginResp.jwt) { $jwt = $loginResp.jwt }

  Assert-True ($null -ne $jwt -and $jwt.Length -gt 20) "JWT token received" "JWT token not found in login response"

  if (-not $jwt) {
    throw "No JWT token in login response"
  }

  Step "Call protected process endpoint"
  $processBody = @{
    text = "hello"
  } | ConvertTo-Json -Compress

  try {
    $processResp = Invoke-RestMethod `
      -Uri $ProcessEndpoint `
      -Method Post `
      -ContentType "application/json" `
      -Headers @{ Authorization = "Bearer $jwt" } `
      -Body $processBody `
      -TimeoutSec 20
    Pass "Protected endpoint accepted JWT"
  }
  catch {
    Fail "Protected endpoint failed with JWT: $($_.Exception.Message)"
    throw
  }

  $processJson = $processResp | ConvertTo-Json -Depth 10
  Assert-True ($processJson.Length -gt 0) "Protected endpoint returned a response body" "Protected endpoint response body is empty"

  Step "Negative check without JWT"
  try {
    Invoke-RestMethod `
      -Uri $ProcessEndpoint `
      -Method Post `
      -ContentType "application/json" `
      -Body $processBody `
      -TimeoutSec 15 | Out-Null

    Fail "Protected endpoint unexpectedly allowed request without JWT"
  }
  catch {
    $statusCode = $null

    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
      $statusCode = [int]$_.Exception.Response.StatusCode
    }

    if ($statusCode -eq 401 -or $statusCode -eq 403) {
      Pass "Protected endpoint correctly rejected request without JWT ($statusCode)"
    }
    else {
      Fail "Protected endpoint rejected unauthenticated request with unexpected status: $statusCode"
    }
  }

  Step "Negative check: direct access to data-api"
  try {
    Invoke-RestMethod `
      -Uri $TransformEndpoint `
      -Method Post `
      -ContentType "application/json" `
      -Body $processBody `
      -TimeoutSec 15 | Out-Null

    Fail "data-api unexpectedly allowed direct access without internal token"
  }
  catch {
    $statusCode = $null

    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
      $statusCode = [int]$_.Exception.Response.StatusCode
    }

    if ($statusCode -eq 401 -or $statusCode -eq 403) {
      Pass "data-api correctly rejected direct access without internal token ($statusCode)"
    }
    else {
      Fail "data-api rejected direct access with unexpected status: $statusCode"
    }
  }
}
catch {
  Write-Host "`nSmoke test terminated with error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
  Write-Host "`n==============================" -ForegroundColor White
  Write-Host "Smoke Test Summary" -ForegroundColor White
  Write-Host "Passed: $Passed" -ForegroundColor Green
  Write-Host "Failed: $Failed" -ForegroundColor Red

  if ($Failed -eq 0) {
    Write-Host "RESULT: PASS" -ForegroundColor Green

    Step "Docker Compose shutdown"
    docker compose down | Out-Null
    Pass "Docker Compose stopped"
  }
  else {
    if ($KeepContainersOnFailure) {
      Step "Docker Compose preserved for debugging"
      Write-Host "Containers were left running because the smoke test failed." -ForegroundColor Yellow
      Write-Host "Use the commands below to inspect the failure:" -ForegroundColor Yellow
      Write-Host "  docker compose ps" -ForegroundColor Yellow
      Write-Host "  docker compose logs --tail=200 auth-api" -ForegroundColor Yellow
      Write-Host "  docker compose logs --tail=200 data-api" -ForegroundColor Yellow
      Write-Host "  docker compose logs --tail=200 postgres" -ForegroundColor Yellow
      Write-Host "  curl http://localhost:8080/health" -ForegroundColor Yellow
      Write-Host "  curl http://localhost:8081/health" -ForegroundColor Yellow
      Write-Host "  git status --short" -ForegroundColor Yellow
      Write-Host "  git diff -- .gitignore README.md KNOWN-ISSUES.md CONTRIBUTING.md docs/verification.md docs/architecture.md docs/decisions.md scripts/smoke.ps1" -ForegroundColor Yellow
      Write-Host "When finished, clean up manually with:" -ForegroundColor Yellow
      Write-Host "  docker compose down -v" -ForegroundColor Yellow
    }
    else {
      Step "Docker Compose shutdown"
      docker compose down | Out-Null
      Pass "Docker Compose stopped"
    }

    Write-Host "RESULT: FAIL" -ForegroundColor Red
  }

  Write-Host "==============================" -ForegroundColor White
}
