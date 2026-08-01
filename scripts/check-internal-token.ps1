param(
    [string]$DataApiUrl = "http://127.0.0.1:8081",
    [string]$ValidToken = "change-me-in-readme-or-env",
    [string]$Text = "hello"
)

$ErrorActionPreference = "Stop"

$body = @{ text = $Text } | ConvertTo-Json -Compress

Write-Host "=== WITHOUT HEADER ===" -ForegroundColor Cyan
try {
    Invoke-RestMethod -Method Post `
        -Uri "$DataApiUrl/api/transform" `
        -ContentType "application/json" `
        -Body $body
    Write-Host "Unexpected: request without header was accepted" -ForegroundColor Red
}
catch {
    Write-Host "OK: request without header rejected" -ForegroundColor Green
}

Write-Host "`n=== WITH INVALID HEADER ===" -ForegroundColor Cyan
try {
    Invoke-RestMethod -Method Post `
        -Uri "$DataApiUrl/api/transform" `
        -ContentType "application/json" `
        -Headers @{ "X-Internal-Token" = "wrong-token" } `
        -Body $body
    Write-Host "Unexpected: request with invalid header was accepted" -ForegroundColor Red
}
catch {
    Write-Host "OK: request with invalid header rejected" -ForegroundColor Green
}

Write-Host "`n=== WITH VALID HEADER ===" -ForegroundColor Cyan
$response = Invoke-RestMethod -Method Post `
    -Uri "$DataApiUrl/api/transform" `
    -ContentType "application/json" `
    -Headers @{ "X-Internal-Token" = $ValidToken } `
    -Body $body

$response | ConvertTo-Json -Compress
