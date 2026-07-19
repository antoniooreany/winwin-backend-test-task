$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

$SmokeScript = if (Test-Path .\scripts\smoke.ps1) {
    ".\scripts\smoke.ps1"
} elseif (Test-Path .\scripts\smoke-v3.ps1) {
    ".\scripts\smoke-v3.ps1"
} else {
    $null
}

if (-not $SmokeScript) {
    Write-Error "Smoke test script not found. Expected .\scripts\smoke.ps1 or .\scripts\smoke-v3.ps1"
    exit 1
}

Write-Host "Running smoke tests via $SmokeScript ..." -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File $SmokeScript
if ($LASTEXITCODE -ne 0) {
    Write-Error "Smoke tests failed."
    exit $LASTEXITCODE
}

Write-Host "Smoke tests completed successfully." -ForegroundColor Green
