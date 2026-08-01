$ErrorActionPreference = "Stop"

$report = ".\full-verification-report.txt"
$passed = 0
$failed = 0

Remove-Item $report -ErrorAction SilentlyContinue

function Write-Report {
    param([string]$Message)
    $Message | Tee-Object -FilePath $report -Append | Out-Host
}

function Pass-Step {
    param([string]$Message)
    $script:passed++
    Write-Report "[PASS] $Message"
}

function Fail-Step {
    param([string]$Message)
    $script:failed++
    Write-Report "[FAIL] $Message"
}

function Info-Step {
    param([string]$Message)
    Write-Report ""
    Write-Report "== $Message =="
}

function Get-Json {
    param([string]$Url)
    $raw = & curl.exe -fsS $Url 2>&1
    if ($LASTEXITCODE -ne 0) { throw "curl failed for $Url : $raw" }
    return $raw | ConvertFrom-Json
}

function Post-Json {
    param(
        [string]$Url,
        [string]$JsonBody,
        [string[]]$Headers = @()
    )

    $args = @("-fsS", "-X", "POST", $Url, "-H", "Content-Type: application/json")
    foreach ($header in $Headers) {
        $args += @("-H", $header)
    }
    $args += @("-d", $JsonBody)

    $raw = & curl.exe @args 2>&1
    if ($LASTEXITCODE -ne 0) { throw "curl POST failed for $Url : $raw" }
    return $raw
}

function Get-StatusCode {
    param(
        [string]$Url,
        [string]$JsonBody,
        [string[]]$Headers = @()
    )

    $args = @("-s", "-o", "NUL", "-w", "%{http_code}", "-X", "POST", $Url, "-H", "Content-Type: application/json")
    foreach ($header in $Headers) {
        $args += @("-H", $header)
    }
    $args += @("-d", $JsonBody)

    return (& curl.exe @args)
}

try {
    Info-Step "Preconditions"
    Write-Report "Make sure Docker Desktop is running."

    Info-Step "Git sanity check"
    git status --short | Tee-Object -FilePath $report -Append | Out-Host
    if ($LASTEXITCODE -eq 0) {
        Pass-Step "Git status checked"
    } else {
        throw "Git status failed"
    }

    Info-Step "Clean previous environment"
    docker compose down -v | Tee-Object -FilePath $report -Append | Out-Host
    if ($LASTEXITCODE -eq 0) {
        Pass-Step "Previous Docker Compose environment removed"
    } else {
        throw "docker compose down -v failed"
    }

    Info-Step "Build auth-api"
    mvn -f auth-api/pom.xml clean package -DskipTests | Tee-Object -FilePath $report -Append | Out-Host
    if ($LASTEXITCODE -eq 0) {
        Pass-Step "auth-api built successfully"
    } else {
        throw "auth-api build failed"
    }

    Info-Step "Build data-api"
    mvn -f data-api/pom.xml clean package -DskipTests | Tee-Object -FilePath $report -Append | Out-Host
    if ($LASTEXITCODE -eq 0) {
        Pass-Step "data-api built successfully"
    } else {
        throw "data-api build failed"
    }

    Info-Step "Ensure service JAR files exist"
    if (Test-Path ".\auth-api\target\auth-api-0.0.1-SNAPSHOT.jar") {
        Pass-Step "auth-api JAR exists"
    } else {
        throw "auth-api JAR missing"
    }

    if (Test-Path ".\data-api\target\data-api-0.0.1-SNAPSHOT.jar") {
        Pass-Step "data-api JAR exists"
    } else {
        throw "data-api JAR missing"
    }

    Info-Step "Start the stack"
    docker compose up -d --build | Tee-Object -FilePath $report -Append | Out-Host
    if ($LASTEXITCODE -eq 0) {
        Pass-Step "Docker Compose stack started"
    } else {
        throw "docker compose up failed"
    }

    docker compose ps | Tee-Object -FilePath $report -Append | Out-Host

    Info-Step "Wait for auth-api health"
    $authReady = $false
    for ($i = 0; $i -lt 45; $i++) {
        try {
            $authHealth = Get-Json "http://127.0.0.1:8080/health"
            if ($authHealth.status -eq "ok" -and $authHealth.service -eq "auth-api") {
                $authReady = $true
                break
            }
        } catch {}
        Start-Sleep -Seconds 2
    }
    if ($authReady) {
        Pass-Step "auth-api health check passed"
    } else {
        docker compose logs auth-api | Tee-Object -FilePath $report -Append | Out-Host
        throw "auth-api did not become healthy"
    }

    Info-Step "Wait for data-api health"
    $dataReady = $false
    for ($i = 0; $i -lt 45; $i++) {
        try {
            $dataHealth = Get-Json "http://127.0.0.1:8081/health"
            if ($dataHealth.status -eq "ok" -and $dataHealth.service -eq "data-api") {
                $dataReady = $true
                break
            }
        } catch {}
        Start-Sleep -Seconds 2
    }
    if ($dataReady) {
        Pass-Step "data-api health check passed"
    } else {
        docker compose logs data-api | Tee-Object -FilePath $report -Append | Out-Host
        throw "data-api did not become healthy"
    }

    Info-Step "Show health responses"
    $authHealthFinal = Get-Json "http://127.0.0.1:8080/health"
    $dataHealthFinal = Get-Json "http://127.0.0.1:8081/health"
    ($authHealthFinal | ConvertTo-Json -Compress) | Tee-Object -FilePath $report -Append | Out-Host
    ($dataHealthFinal | ConvertTo-Json -Compress) | Tee-Object -FilePath $report -Append | Out-Host
    Pass-Step "Health endpoints returned valid JSON"

    Info-Step "Register user"
    $email = "reviewer+$([guid]::NewGuid().ToString('N').Substring(0,8))@example.com"
    $password = "Pass12345!"
    $registerJson = @{ email = $email; password = $password } | ConvertTo-Json -Compress

    $registerCode = & curl.exe -s -o NUL -w "%{http_code}" -X POST "http://127.0.0.1:8080/api/auth/register" -H "Content-Type: application/json" -d $registerJson
    if ($registerCode -eq "201") {
        Pass-Step "Registration returned HTTP 201"
    } else {
        throw "Unexpected registration status: $registerCode"
    }

    Info-Step "Login user"
    $loginJson = @{ email = $email; password = $password } | ConvertTo-Json -Compress
    $loginRaw = Post-Json -Url "http://127.0.0.1:8080/api/auth/login" -JsonBody $loginJson
    $loginResponse = $loginRaw | ConvertFrom-Json
    $token = $loginResponse.token
    if ($token) {
        Pass-Step "Login returned JWT token"
    } else {
        throw "JWT token was not returned"
    }

    Info-Step "Call protected process endpoint"
    $processJson = @{ text = "hello" } | ConvertTo-Json -Compress
    $processRaw = Post-Json -Url "http://127.0.0.1:8080/api/process" -JsonBody $processJson -Headers @("Authorization: Bearer $token")
    $processResponse = $processRaw | ConvertFrom-Json
    ($processResponse | ConvertTo-Json -Compress) | Tee-Object -FilePath $report -Append | Out-Host
    if ($processResponse.result -eq "olleh") {
        Pass-Step "Protected endpoint returned expected result"
    } else {
        throw "Unexpected process result: $($processResponse.result)"
    }

    Info-Step "Database verification"
    $dbOutput = docker exec winwin-backend-test-task-postgres-1 psql -U appuser -d appdb -c "SELECT id, user_email, input_text, output_text, created_at FROM processinglog ORDER BY id DESC LIMIT 5;"
    $dbOutput | Tee-Object -FilePath $report -Append | Out-Host
    $dbJoined = ($dbOutput | Out-String)
    if ($dbJoined -match [regex]::Escape($email) -and $dbJoined -match 'hello' -and $dbJoined -match 'olleh') {
        Pass-Step "processinglog contains expected persisted row"
    } else {
        throw "processinglog does not contain expected row"
    }

    Info-Step "Negative scenario: no JWT"
    $code = Get-StatusCode -Url "http://127.0.0.1:8080/api/process" -JsonBody $processJson
    if ($code -eq "401" -or $code -eq "403") {
        Pass-Step "Protected endpoint correctly rejected request without JWT ($code)"
    } else {
        throw "Unexpected status without JWT: $code"
    }

    Info-Step "Negative scenario: direct access to data-api without internal token"
    $code = Get-StatusCode -Url "http://127.0.0.1:8081/api/transform" -JsonBody $processJson
    if ($code -eq "403") {
        Pass-Step "data-api correctly rejected request without internal token (403)"
    } else {
        throw "Unexpected status without internal token: $code"
    }

    Info-Step "Negative scenario: wrong internal token"
    $code = Get-StatusCode -Url "http://127.0.0.1:8081/api/transform" -JsonBody $processJson -Headers @("X-Internal-Token: wrong-token")
    if ($code -eq "403") {
        Pass-Step "data-api correctly rejected request with wrong internal token (403)"
    } else {
        throw "Unexpected status with wrong internal token: $code"
    }
}
catch {
    Fail-Step $_.Exception.Message
}
finally {
    Info-Step "Stop the stack"
    docker compose down | Tee-Object -FilePath $report -Append | Out-Host
    if ($LASTEXITCODE -eq 0) {
        Pass-Step "Docker Compose stack stopped"
    } else {
        Fail-Step "Docker Compose shutdown failed"
    }

    Write-Report ""
    Write-Report "=============================="
    Write-Report "Full Verification Summary"
    Write-Report "Passed: $passed"
    Write-Report "Failed: $failed"
    if ($failed -eq 0) {
        Write-Report "RESULT: PASS"
    } else {
        Write-Report "RESULT: FAIL"
    }
    Write-Report "=============================="
}

