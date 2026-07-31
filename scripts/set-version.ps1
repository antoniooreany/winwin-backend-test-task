param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Set-Content -LiteralPath '.version' -Value $Version

$pomFiles = @(
    'auth-api/pom.xml',
    'data-api/pom.xml'
)

foreach ($pom in $pomFiles) {
    if (-not (Test-Path -LiteralPath $pom)) {
        throw "POM not found: $pom"
    }

    [xml]$xml = Get-Content -LiteralPath $pom
    $projectVersion = $xml.project.version

    if (-not $projectVersion) {
        throw "No <version> node found in $pom"
    }

    $xml.project.version = $Version
    $xml.Save((Resolve-Path $pom))
}

Write-Host "Updated .version and module POM versions to $Version" -ForegroundColor Green
