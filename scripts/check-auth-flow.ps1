param(
    [string]$BaseUrl = "http://localhost:8080",
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

if (-not $login.token) {
    throw "Login failed: token not returned"
}

$token = $login.token
$headers = @{ Authorization = "Bearer $token" }

Write-Host "Login OK" -ForegroundColor Green

Write-Host "`n=== PROCESS ===" -ForegroundColor Cyan
foreach ($text in $Texts) {
    $response = Invoke-JsonPost -Url "$BaseUrl/api/process" -Headers $headers -Body @{
        text = $text
    }

    Write-Host ("INPUT  : " + $text) -ForegroundColor DarkCyan
    Write-Host ("OUTPUT : " + ($response | ConvertTo-Json -Compress)) -ForegroundColor Green
}

Write-Host "`n=== PROCESSING LOG ===" -ForegroundColor Cyan
$pg = docker compose ps -q postgres
if (-not $pg) {
    throw "Postgres container not found"
}

docker exec -i $pg psql -U appuser -d appdb -c "select id, user_email, input_text, output_text, created_at from processinglog order by id desc limit 10;"
