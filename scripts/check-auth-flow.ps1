param(
    [string]$BaseUrl = "http://127.0.0.1:8080",
    [string]$Email = "user@example.com",
    [string]$Password = "Pass12345!",
    [string[]]$Texts = @("hello", "WinWin Travel", "backend test")
)

$ErrorActionPreference = "Stop"

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

Write-Host "=== REGISTER ===" -ForegroundColor Cyan
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

Write-Host "`n=== LOGIN ===" -ForegroundColor Cyan
$login = Invoke-JsonPost -Url "$BaseUrl/api/auth/login" -Body @{
    email = $Email
    password = $Password
}
Write-Host "Login OK" -ForegroundColor Green

$token = $login.token
if (-not $token) {
    throw "JWT token was not returned"
}

Write-Host "`n=== PROCESS ===" -ForegroundColor Cyan
foreach ($text in $Texts) {
    $response = Invoke-JsonPost -Url "$BaseUrl/api/process" -Body @{ text = $text } -Headers @{
        Authorization = "Bearer $token"
    }

    Write-Host ("INPUT  : {0}" -f $text)
    Write-Host ("OUTPUT : {0}" -f ($response | ConvertTo-Json -Compress))
}

Write-Host "`n=== PROCESSING LOG ===" -ForegroundColor Cyan
$pg = docker ps --format "{{.Names}}" | Select-String "postgres" | Select-Object -First 1
if (-not $pg) {
    throw "Postgres container was not found"
}

$pg = $pg.ToString().Trim()
docker exec -i $pg psql -U appuser -d appdb -c "select id, user_email, input_text, output_text, created_at from processinglog order by id desc limit 10;"
