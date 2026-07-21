$ErrorActionPreference = 'Stop'

function Write-Section($title) {
  Write-Host "`n==============================" -ForegroundColor Cyan
  Write-Host $title -ForegroundColor Cyan
  Write-Host "==============================" -ForegroundColor Cyan
}

function Run-Step($title, $scriptBlock) {
  Write-Section $title
  try {
    & $scriptBlock
  } catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
  }
}

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$reportDir = Join-Path (Get-Location) 'audit-output'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$report = Join-Path $reportDir "project-audit-$ts.md"

$lines = New-Object System.Collections.Generic.List[string]
function Add-Line([string]$text='') { $lines.Add($text) | Out-Null }
function Add-CodeBlock($lang, [string[]]$content) {
  Add-Line "```$lang"
  foreach ($line in $content) { Add-Line $line }
  Add-Line '```'
}

Add-Line "# Project audit report"
Add-Line ""
Add-Line "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
Add-Line ""

Run-Step 'Git branches and status' {
  $out = git status --short --branch 2>&1
  $out | ForEach-Object { $_ }
  Add-Line '## Git status'
  Add-CodeBlock 'text' $out

  $out2 = git branch -vv 2>&1
  $out2 | ForEach-Object { $_ }
  Add-Line '## Branches'
  Add-CodeBlock 'text' $out2

  $out3 = git log --oneline --decorate -n 20 2>&1
  $out3 | ForEach-Object { $_ }
  Add-Line '## Recent commits'
  Add-CodeBlock 'text' $out3
}

Run-Step 'Flyway and schema clues in repo' {
  $cmds = @(
    'Select-String -Path auth-api/pom.xml -Pattern "flyway"',
    'Select-String -Path data-api/pom.xml -Pattern "flyway"',
    'Get-ChildItem -Recurse auth-api/src/main/resources | Select-Object FullName',
    'Get-ChildItem -Recurse data-api/src/main/resources | Select-Object FullName',
    'Select-String -Path auth-api/src/main/resources/* -Pattern "ddl-auto|flyway|datasource|jdbc|hibernate"',
    'Select-String -Path data-api/src/main/resources/* -Pattern "ddl-auto|flyway|datasource|jdbc|hibernate"',
    'git log --all -- auth-api/src/main/resources/db',
    'git log --all -- data-api/src/main/resources/db',
    'git log --all -- "*flyway*"'
  )
  Add-Line '## Flyway and configuration evidence'
  foreach ($c in $cmds) {
    Add-Line "### $c"
    $out = powershell -NoProfile -Command $c 2>&1
    $out | ForEach-Object { $_ }
    Add-CodeBlock 'text' $out
  }
}

Run-Step 'Inspect built jars for migration resources' {
  $jarCmds = @(
    'jar tf auth-api/target/auth-api-0.0.1-SNAPSHOT.jar | Select-String "db/|flyway|application"',
    'jar tf data-api/target/data-api-0.0.1-SNAPSHOT.jar | Select-String "db/|flyway|application"'
  )
  Add-Line '## Built jar contents'
  foreach ($c in $jarCmds) {
    Add-Line "### $c"
    $out = powershell -NoProfile -Command $c 2>&1
    $out | ForEach-Object { $_ }
    Add-CodeBlock 'text' $out
  }
}

Run-Step 'Docker Compose status and logs' {
  $cmds = @(
    'docker compose ps',
    'docker compose logs auth-api --tail 200',
    'docker compose logs data-api --tail 200',
    'docker compose logs postgres --tail 100'
  )
  Add-Line '## Docker state and logs'
  foreach ($c in $cmds) {
    Add-Line "### $c"
    $out = powershell -NoProfile -Command $c 2>&1
    $out | ForEach-Object { $_ }
    Add-CodeBlock 'text' $out
  }
}

Run-Step 'HTTP checks' {
  $registerBody = '{"email":"audit-user@example.com","password":"Pass12345!"}'
  $loginBody = '{"email":"audit-user@example.com","password":"Pass12345!"}'
  $textBody = '{"text":"hello"}'

  $health1 = curl.exe -sS http://localhost:8080/health 2>&1
  $health2 = curl.exe -sS http://localhost:8081/health 2>&1
  $register = curl.exe -sS -X POST http://localhost:8080/api/auth/register -H "Content-Type: application/json" -d $registerBody 2>&1
  $login = curl.exe -sS -X POST http://localhost:8080/api/auth/login -H "Content-Type: application/json" -d $loginBody 2>&1

  $token = ''
  try {
    $loginJson = $login | ConvertFrom-Json
    if ($loginJson.token) { $token = $loginJson.token }
  } catch {}

  $withJwt = if ($token) {
    curl.exe -sS -X POST http://localhost:8080/api/process -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d $textBody 2>&1
  } else {
    @('JWT token was not parsed from login response.')
  }
  $withoutJwt = curl.exe -sS -X POST http://localhost:8080/api/process -H "Content-Type: application/json" -d $textBody 2>&1
  $directData = curl.exe -sS -X POST http://localhost:8081/api/transform -H "Content-Type: application/json" -d $textBody 2>&1

  $sets = @{
    'GET /health auth-api' = $health1
    'GET /health data-api' = $health2
    'POST /api/auth/register' = $register
    'POST /api/auth/login' = $login
    'POST /api/process with JWT' = $withJwt
    'POST /api/process without JWT' = $withoutJwt
    'POST /api/transform direct' = $directData
  }

  Add-Line '## HTTP verification'
  foreach ($k in $sets.Keys) {
    Write-Host "--- $k ---" -ForegroundColor Yellow
    $sets[$k] | ForEach-Object { $_ }
    Add-Line "### $k"
    Add-CodeBlock 'text' @($sets[$k])
  }
}

Run-Step 'PostgreSQL schema inspection' {
  $psqlCmds = @(
    'docker exec winwin-backend-test-task-postgres-1 psql -U appuser -d appdb -c "\\dt"',
    'docker exec winwin-backend-test-task-postgres-1 psql -U appuser -d appdb -c "SELECT table_name FROM information_schema.tables WHERE table_schema = ''public'' ORDER BY table_name;"',
    'docker exec winwin-backend-test-task-postgres-1 psql -U appuser -d appdb -c "SELECT * FROM flyway_schema_history;"',
    'docker exec winwin-backend-test-task-postgres-1 psql -U appuser -d appdb -c "SELECT COUNT(*) FROM users;"',
    'docker exec winwin-backend-test-task-postgres-1 psql -U appuser -d appdb -c "SELECT COUNT(*) FROM processing_log;"'
  )
  Add-Line '## Database inspection'
  foreach ($c in $psqlCmds) {
    Add-Line "### $c"
    $out = powershell -NoProfile -Command $c 2>&1
    $out | ForEach-Object { $_ }
    Add-CodeBlock 'text' $out
  }
}

Run-Step 'Final write' {
  Set-Content -Path $report -Value $lines -Encoding UTF8
  Write-Host "Audit report written to: $report" -ForegroundColor Green
}
