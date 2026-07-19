$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

Write-Host "Running auth-api tests..." -ForegroundColor Cyan
mvn -f .\auth-api\pom.xml test
if ($LASTEXITCODE -ne 0) {
    Write-Error "auth-api tests failed."
    exit $LASTEXITCODE
}

Write-Host "Running data-api tests..." -ForegroundColor Cyan
mvn -f .\data-api\pom.xml test
if ($LASTEXITCODE -ne 0) {
    Write-Error "data-api tests failed."
    exit $LASTEXITCODE
}

Write-Host "Unit tests completed successfully." -ForegroundColor Green
