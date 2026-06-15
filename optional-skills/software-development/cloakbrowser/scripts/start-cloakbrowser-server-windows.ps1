<#
.SYNOPSIS
Start CloakBrowser as a local CDP endpoint for Hermes on Windows.

.DESCRIPTION
Runs the CloakBrowser patched Chromium binary with --remote-debugging-port so
Hermes browser tools can attach via browser.cdp_url. This is intentionally a
normal user process and does not require administrator rights.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\start-cloakbrowser-server-windows.ps1

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\start-cloakbrowser-server-windows.ps1 -Headed -Port 9223
#>
[CmdletBinding()]
param(
    [string]$Python = "python",
    [int]$Port = 9222,
    [string]$Address = "127.0.0.1",
    [string]$ProfileDir = "$HOME\.cloakbrowser\profile",
    [switch]$Headed,
    [switch]$Foreground,
    [string[]]$ExtraChromiumArgs = @()
)

$ErrorActionPreference = "Stop"

function Require-Command([string]$Command) {
    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $cmd) {
        throw "Required command '$Command' was not found on PATH. Install Python or pass -Python <path>."
    }
}

Require-Command $Python

$binary = & $Python -c "from cloakbrowser.download import ensure_binary; print(ensure_binary())"
$binary = ($binary | Select-Object -Last 1).Trim()
if (-not (Test-Path $binary)) {
    throw "CloakBrowser binary was not found at '$binary'. Run install-cloakbrowser-windows.ps1 first."
}

New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
Remove-Item -Force -ErrorAction SilentlyContinue \
    (Join-Path $ProfileDir "SingletonLock"), \
    (Join-Path $ProfileDir "SingletonCookie"), \
    (Join-Path $ProfileDir "SingletonSocket")

$argsList = @(
    "--remote-debugging-port=$Port",
    "--remote-debugging-address=$Address",
    "--user-data-dir=$ProfileDir",
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-dev-shm-usage"
)

if (-not $Headed) {
    $argsList += "--headless=new"
}
if ($ExtraChromiumArgs.Count -gt 0) {
    $argsList += $ExtraChromiumArgs
}

Write-Host "Starting CloakBrowser CDP endpoint:" -ForegroundColor Cyan
Write-Host "  Binary:  $binary"
Write-Host "  CDP:     http://${Address}:$Port"
Write-Host "  Profile: $ProfileDir"
Write-Host "  Mode:    $(if ($Headed) { 'headed' } else { 'headless=new' })"

if ($Foreground) {
    & $binary @argsList
} else {
    $process = Start-Process -FilePath $binary -ArgumentList $argsList -PassThru -WindowStyle Hidden
    Start-Sleep -Seconds 2
    try {
        $version = Invoke-RestMethod -Uri "http://${Address}:$Port/json/version" -TimeoutSec 5
        Write-Host "CloakBrowser is listening. Browser: $($version.Browser)" -ForegroundColor Green
        Write-Host "Configure Hermes: hermes config set browser.cdp_url http://${Address}:$Port"
    } catch {
        Write-Warning "Process started (PID $($process.Id)), but CDP did not respond yet: $_"
        Write-Warning "Check endpoint manually: curl http://${Address}:$Port/json/version"
    }
}
