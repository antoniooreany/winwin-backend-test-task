param(
    [Parameter(Mandatory = $true)][string]$VmHost,
    [string]$User = "opc",
    [string]$SshKeyPath = $(if ($env:OCI_SSH_KEY) { $env:OCI_SSH_KEY } else { "$HOME\.ssh\id_ed25519_oci" }),
    [string]$RemoteDir = "/home/$User/winwin-backend-test-task",
    [switch]$Quiet,
    [switch]$SkipBuild,
    [string]$OciProfile = "DEFAULT",
    [string]$Region = "eu-milan-1"
)

$ErrorActionPreference = "Stop"

function Run-Step {
    param([string]$Message, [scriptblock]$Action)
    Write-Host "==> $Message" -ForegroundColor Cyan
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "Step failed: $Message"
    }
}

function Invoke-RobocopySafe {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target
    )

    if (-not $Quiet) {
        Write-Host "    robocopy: $Source -> $Target" -ForegroundColor DarkGray
        robocopy $Source $Target /E /XD target .git .idea .vscode /XF *.jar *.class *.log *.bak.* | Out-Host
    }
    else {
        robocopy $Source $Target /E /XD target .git .idea .vscode /XF *.jar *.class *.log *.bak.* > $null
    }
    $rc = $LASTEXITCODE

    if ($rc -ge 8) {
        throw "robocopy failed for '$Source' with exit code $rc"
    }

    $global:LASTEXITCODE = 0
}

if (-not (Test-Path $SshKeyPath)) {
    throw "SSH private key not found: $SshKeyPath"
}

$sshOptions = @(
    "-i", $SshKeyPath,
    "-o", "StrictHostKeyChecking=accept-new"
)

$scpOptions = @(
    "-i", $SshKeyPath,
    "-o", "StrictHostKeyChecking=accept-new"
)

$repoRoot = (Get-Location).Path
$stageRoot = Join-Path $env:TEMP "winwin-oci-deploy-stage"

Run-Step "Preparing local staging directory" {
    if (Test-Path $stageRoot) {
        Remove-Item $stageRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $stageRoot | Out-Null
    $global:LASTEXITCODE = 0
}

Run-Step "Collecting deployable files into staging directory" {
    $itemsToCopy = @(
        ".env.example",
        "docker-compose.yml",
        ".version",
        "auth-api",
        "data-api",
        "scripts"
    ) | Where-Object { Test-Path $_ }

    foreach ($item in $itemsToCopy) {
        $source = Join-Path $repoRoot $item
        $target = Join-Path $stageRoot $item

        if (Test-Path $source -PathType Container) {
            Invoke-RobocopySafe -Source $source -Target $target
        }
        else {
            Write-Host "    copy: $source -> $target" -ForegroundColor DarkGray
            Copy-Item $source $target -Force
        }
    }

    $global:LASTEXITCODE = 0
}

Run-Step "Checking SSH connectivity to $User@$VmHost" {
    ssh @sshOptions "$User@$VmHost" "echo connected"
}

Run-Step "Ensuring remote directory exists" {
    ssh @sshOptions "$User@$VmHost" "mkdir -p '$RemoteDir'"
}

Run-Step "Uploading staged files to remote host" {
    if ($Quiet) {
        scp @scpOptions -r "$stageRoot\." "$User@${VmHost}:$RemoteDir/" > $null
    }
    else {
        scp @scpOptions -r "$stageRoot\." "$User@${VmHost}:$RemoteDir/"
    }
}

Run-Step "Preparing .env on remote host" {
    ssh @sshOptions "$User@$VmHost" "cd '$RemoteDir' && if [ ! -f .env ]; then cp .env.example .env; fi"
}

Run-Step "Checking Docker availability" {
    ssh @sshOptions "$User@$VmHost" "docker --version && (docker compose version || docker-compose version)"
}

if (-not $SkipBuild) {
    Run-Step "Deploying stack with docker compose" {
        ssh @sshOptions "$User@$VmHost" "cd '$RemoteDir' && (docker compose up -d --build || docker-compose up -d --build)"
    }
}
else {
    Run-Step "Deploying stack without rebuild" {
        ssh @sshOptions "$User@$VmHost" "cd '$RemoteDir' && (docker compose up -d || docker-compose up -d)"
    }
}

Run-Step "Showing remote compose status" {
    ssh @sshOptions "$User@$VmHost" "cd '$RemoteDir' && (docker compose ps || docker-compose ps)"
}

Run-Step "Cleaning local staging directory" {
    if (Test-Path $stageRoot) {
        Remove-Item $stageRoot -Recurse -Force
    }
    $global:LASTEXITCODE = 0
}

Write-Host ""
Write-Host "OCI deploy completed." -ForegroundColor Green
Write-Host "Host: $VmHost"
Write-Host "Remote dir: $RemoteDir"
Write-Host "Region parameter: $Region"
Write-Host "OCI profile parameter: $OciProfile"



