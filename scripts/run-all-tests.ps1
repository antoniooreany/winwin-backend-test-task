$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

Write-Host "Running all tests..." -ForegroundColor Cyan

& .\scripts\run-unit-tests.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-smoke-tests.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "All tests completed successfully." -ForegroundColor Green
