param(
    [Parameter(Mandatory = $true)][string]$VmHost,
    [string]$Protocol = "http",
    [int]$TimeoutSec = 300
)

$ErrorActionPreference = "Stop"
$authBaseUrl = "{0}://{1}:8080" -f $Protocol, $VmHost
$dataBaseUrl = "{0}://{1}:8081" -f $Protocol, $VmHost
$deadline = (Get-Date).AddSeconds($TimeoutSec)

function Wait-HttpOk {
    param(
        [string]$Url,
        [datetime]$Deadline
    )

    do {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                return $true
            }
        }
        catch {
            Start-Sleep -Seconds 3
        }
    } while ((Get-Date) -lt $Deadline)

    return $false
}

Write-Host "==> Waiting for auth-api health endpoint..." -ForegroundColor Cyan
if (-not (Wait-HttpOk -Url "$authBaseUrl/actuator/health" -Deadline $deadline)) {
    throw "Timed out waiting for $authBaseUrl/actuator/health"
}

Write-Host "==> Waiting for data-api health endpoint..." -ForegroundColor Cyan
if (-not (Wait-HttpOk -Url "$dataBaseUrl/actuator/health" -Deadline $deadline)) {
    throw "Timed out waiting for $dataBaseUrl/actuator/health"
}

Write-Host "==> Running remote verification..." -ForegroundColor Cyan
& .\scripts\verify-local.ps1 `
  -AuthBaseUrl $authBaseUrl `
  -DataBaseUrl $dataBaseUrl `
  -Report ".\smoke-report-oci.txt"

Write-Host ""
Write-Host "OCI verification completed." -ForegroundColor Green
Write-Host "Auth base URL: $authBaseUrl"
Write-Host "Data base URL: $dataBaseUrl"
