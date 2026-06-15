<#
.SYNOPSIS
Install CloakBrowser for Hermes on Windows without admin rights.

.DESCRIPTION
Installs the Python cloakbrowser package into the current user's Python site,
downloads the patched Chromium binary into %USERPROFILE%\.cloakbrowser, and
prints the Hermes CDP configuration command. No Windows Service, Program Files
write, or administrator elevation is required.
#>
[CmdletBinding()]
param(
    [string]$Python = "python",
    [switch]$SkipPackageInstall,
    [switch]$SkipBinaryInstall
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Require-Command([string]$Command) {
    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $cmd) {
        throw "Required command '$Command' was not found on PATH. Install Python or pass -Python <path>."
    }
}

Require-Command $Python

Write-Step "Python version"
& $Python --version

if (-not $SkipPackageInstall) {
    Write-Step "Installing cloakbrowser into the current user's Python site"
    & $Python -m pip install --user --upgrade cloakbrowser
}

if (-not $SkipBinaryInstall) {
    Write-Step "Downloading/verifying CloakBrowser patched Chromium binary"
    & $Python -m cloakbrowser install
}

Write-Step "CloakBrowser binary info"
& $Python -m cloakbrowser info

Write-Step "Done"
Write-Host "Start the CDP server with:" -ForegroundColor Green
Write-Host "  powershell -ExecutionPolicy Bypass -File .\start-cloakbrowser-server-windows.ps1"
Write-Host "Then configure Hermes with:" -ForegroundColor Green
Write-Host "  hermes config set browser.cdp_url http://127.0.0.1:9222"
