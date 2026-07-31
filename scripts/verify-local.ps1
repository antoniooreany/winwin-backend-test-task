$ErrorActionPreference = "Stop"

$passed = 0
$failed = 0
$email = "reviewer+$([guid]::NewGuid().ToString('N').Substring(0,8))@example.com"
$password = "Pass12345!"
$report = ".\smoke-report.txt"
$authBaseUrl = "http://127.0.0.1:8080"
$dataBaseUrl = "http://127.0.0.1:8081"

Remove-Item $report -ErrorAction SilentlyContinue

function Log($msg) { $msg | Tee-Object -FilePath $report -Append }
function Pass($msg) { $script:passed++; Log "[PASS] $msg" }
function Fail($msg) { $script:failed++; Log "[FAIL] $msg" }
function Section($msg) { Log ""; Log "== $msg ==" }

function Get-JsonCurl {
    param([string]$Method,[string]$Url,[string]$Body = "",[string[]]$Headers = @())
    $args = @("-sS", "-X", $Method, $Url)
    foreach ($h in $Headers) { $args += @("-H", $h) }
    if ($Body -ne "") { $args += @("-d", $Body) }
    & curl.exe @args
}

function Get-StatusCurl {
    param([string]$Method,[string]$Url,[string]$Body = "",[string[]]$Headers = @())
    $args = @("-sS", "-o", "NUL", "-w", "%{http_code}", "-X", $Method, $Url)
    foreach ($h in $Headers) { $args += @("-H", $h) }
    if ($Body -ne "") { $args += @("-d", $Body) }
    [int](& curl.exe @args)
}

Section "Git sanity check"
git status --short | Tee-Object -FilePath $report -Append | Out-Host
Pass "Git status checked"

Section "Build services"
mvn -f auth-api/pom.xml clean package -DskipTests | Tee-Object -FilePath $report -Append | Out-Host
if ($LASTEXITCODE -ne 0) { Fail "auth-api build failed"; exit 1 } else { Pass "auth-api built successfully" }

mvn -f data-api/pom.xml clean package -DskipTests | Tee-Object -FilePath $report -Append | Out-Host
if ($LASTEXITCODE -ne 0) { Fail "data-api build failed"; exit 1 } else { Pass "data-api built successfully" }

Section "Ensure service JAR files exist"
if ((Test-Path ".\auth-api\target\auth-api-0.0.1-SNAPSHOT.jar") -and (Test-Path ".\data-api\target\data-api-0.0.1-SNAPSHOT.jar")) {
    Pass "Required JAR files are available"
} else {
    Fail "Required JAR files are missing"
    exit 1
}

Section "Docker Compose reset"
docker compose down -v | Tee-Object -FilePath $report -Append | Out-Host
docker compose up -d --build | Tee-Object -FilePath $report -Append | Out-Host
if ($LASTEXITCODE -eq 0) { Pass "Docker Compose started" } else { Fail "Docker Compose startup failed"; exit 1 }

Section "Wait for services"
$authReady = $false
$dataReady = $false

for ($i = 0; $i -lt 60; $i++) {
    try {
        $auth = (& curl.exe -fsS "$authBaseUrl/health") | ConvertFrom-Json
        if ($auth.status -eq "ok" -and $auth.service -eq "auth-api") { $authReady = $true; break }
    } catch {}
    Start-Sleep -Seconds 2
}

for ($i = 0; $i -lt 60; $i++) {
    try {
        $data = (& curl.exe -fsS "$dataBaseUrl/health") | ConvertFrom-Json
        if ($data.status -eq "ok" -and $data.service -eq "data-api") { $dataReady = $true; break }
    } catch {}
    Start-Sleep -Seconds 2
}

if ($authReady) { Pass "auth-api health is ready" } else { Fail "auth-api health is not ready" }
if ($dataReady) { Pass "data-api health is ready" } else { Fail "data-api health is not ready" }

if (-not ($authReady -and $dataReady)) {
    docker compose logs | Tee-Object -FilePath $report -Append | Out-Host
    docker compose down | Tee-Object -FilePath $report -Append | Out-Host
    exit 1
}

Section "Register user"
$registerBody = "{""email"":""$email"",""password"":""$password""}"
$registerStatus = Get-StatusCurl -Method "POST" -Url "$authBaseUrl/api/auth/register" -Body $registerBody -Headers @("Content-Type: application/json")
if ($registerStatus -eq 201) { Pass "Registration returned HTTP 201" } else { Fail "Registration returned HTTP $registerStatus" }

Section "Login user"
$loginBody = "{""email"":""$email"",""password"":""$password""}"
try {
    $login = (Get-JsonCurl -Method "POST" -Url "$authBaseUrl/api/auth/login" -Body $loginBody -Headers @("Content-Type: application/json")) | ConvertFrom-Json
    $token = $login.token
    if ($token) { Pass "Login returned JWT token" } else { Fail "Login response did not contain token" }
} catch {
    Fail "Login request failed"
}

Section "Call protected process endpoint"
$processBody = "{""text"":""hello""}"
try {
    $process = (Get-JsonCurl -Method "POST" -Url "$authBaseUrl/api/process" -Body $processBody -Headers @("Authorization: Bearer $token", "Content-Type: application/json")) | ConvertFrom-Json
    if ($process.result -eq "olleh") { Pass "Protected endpoint returned expected result" } else { Fail "Protected endpoint returned unexpected result: $($process.result)" }
} catch {
    Fail "Protected endpoint request failed"
}

Section "Database verification"
$pgContainer = docker compose ps -q postgres
if (-not $pgContainer) {
    Fail "Postgres container not found"
} else {
    $dbQuery = "SELECT id, user_email, input_text, output_text, created_at FROM processinglog ORDER BY created_at DESC LIMIT 5;"
    docker exec $pgContainer psql -U appuser -d appdb -c $dbQuery | Tee-Object -FilePath $report -Append | Out-Host
    $dbOutput = docker exec $pgContainer psql -U appuser -d appdb -t -A -F "|" -c $dbQuery
    if ($dbOutput -match [regex]::Escape($email) -and $dbOutput -match "hello" -and $dbOutput -match "olleh") {
        Pass "processinglog contains expected persisted row"
    } else {
        Fail "processinglog does not contain expected persisted row"
    }
}

Section "Negative check without JWT"
$noJwtStatus = Get-StatusCurl -Method "POST" -Url "$authBaseUrl/api/process" -Body $processBody -Headers @("Content-Type: application/json")
if ($noJwtStatus -eq 401 -or $noJwtStatus -eq 403) { Pass "Protected endpoint correctly rejected request without JWT ($noJwtStatus)" } else { Fail "Protected endpoint returned unexpected status without JWT: $noJwtStatus" }

Section "Negative check: direct access to data-api"
$directStatus = Get-StatusCurl -Method "POST" -Url "$dataBaseUrl/api/transform" -Body $processBody -Headers @("Content-Type: application/json")
if ($directStatus -eq 403) { Pass "data-api correctly rejected direct access without internal token (403)" } else { Fail "data-api returned unexpected status without internal token: $directStatus" }

Section "Negative check: wrong internal token"
$wrongTokenStatus = Get-StatusCurl -Method "POST" -Url "$dataBaseUrl/api/transform" -Body $processBody -Headers @("Content-Type: application/json", "X-Internal-Token: wrong-token")
if ($wrongTokenStatus -eq 403) { Pass "data-api correctly rejected wrong internal token (403)" } else { Fail "data-api returned unexpected status with wrong internal token: $wrongTokenStatus" }

Section "Docker Compose shutdown"
docker compose down | Tee-Object -FilePath $report -Append | Out-Host
Pass "Docker Compose stopped"

Log ""
Log "=============================="
Log "Smoke Test Summary"
Log "Passed: $passed"
Log "Failed: $failed"
if ($failed -eq 0) { Log "RESULT: PASS" } else { Log "RESULT: FAIL"; exit 1 }


