function Get-ProjectRoot {
    if ($PSScriptRoot) {
        return (Split-Path $PSScriptRoot -Parent)
    }
    return (Get-Location).Path
}

function Get-LatestFullVerificationLog {
    param(
        [string]$ProjectPath = (Get-ProjectRoot)
    )

    $logDir = Join-Path $ProjectPath ".logs"
    if (!(Test-Path $logDir)) {
        return $null
    }

    return Get-ChildItem $logDir -File -Filter "full-verification-*.log" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Invoke-FullVerificationShort {
    param(
        [string]$ProjectPath = (Get-ProjectRoot)
    )

    $scriptPath = Join-Path $ProjectPath "scripts\full-verification.ps1"
    $logDir = Join-Path $ProjectPath ".logs"
    $null = New-Item -ItemType Directory -Force -Path $logDir
    $logFile = Join-Path $logDir ("full-verification-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

    Push-Location $ProjectPath
    try {
        powershell -ExecutionPolicy Bypass -File $scriptPath *>&1 | Out-File -FilePath $logFile -Encoding utf8

        $summary = Select-String -Path $logFile `
            -Pattern '^(== .+ ==)$','^\[PASS\]','^\[FAIL\]','^Passed:','^Failed:','^RESULT:' |
            ForEach-Object { $_.Line }

        foreach ($line in $summary) {
            if ($line -match '^RESULT:\s+PASS') {
                Write-Host $line -ForegroundColor Green
            }
            elseif ($line -match '^RESULT:\s+FAIL') {
                Write-Host $line -ForegroundColor Red
            }
            elseif ($line -match '^\[FAIL\]') {
                Write-Host $line -ForegroundColor Red
            }
            elseif ($line -match '^\[PASS\]') {
                Write-Host $line -ForegroundColor Green
            }
            else {
                Write-Host $line
            }
        }

        Write-Host ""
        Write-Host "Log: $logFile" -ForegroundColor DarkGray
    }
    finally {
        Pop-Location
    }
}

function Show-FullVerificationFailures {
    param(
        [string]$ProjectPath = (Get-ProjectRoot),
        [int]$Before = 3,
        [int]$After = 10
    )

    $latestLog = Get-LatestFullVerificationLog -ProjectPath $ProjectPath
    if (-not $latestLog) {
        Write-Host "No full-verification log files found" -ForegroundColor Yellow
        return
    }

    Write-Host "Log: $($latestLog.FullName)" -ForegroundColor DarkGray
    Write-Host ""

    $summary = Select-String -Path $latestLog.FullName `
        -Pattern '^\[FAIL\]','^Passed:','^Failed:','^RESULT:' |
        ForEach-Object { $_.Line }

    if ($summary) {
        $summary | ForEach-Object {
            if ($_ -match '^RESULT:\s+FAIL' -or $_ -match '^\[FAIL\]') {
                Write-Host $_ -ForegroundColor Red
            }
            else {
                Write-Host $_
            }
        }
    }

    $failMatches = Select-String -Path $latestLog.FullName `
        -Pattern '^\[FAIL\]' `
        -Context $Before,$After

    if ($failMatches) {
        Write-Host ""
        Write-Host "Context:" -ForegroundColor Cyan
        $failMatches | ForEach-Object {
            $_.Context.PreContext
            $_.Line
            $_.Context.PostContext
            ""
        }
    }
    else {
        Write-Host ""
        Write-Host "No FAIL blocks found in latest log." -ForegroundColor Green
    }
}
