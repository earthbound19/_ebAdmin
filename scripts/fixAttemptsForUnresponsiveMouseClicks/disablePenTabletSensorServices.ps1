<#
.SYNOPSIS
Lists and disables (does NOT delete) tablet, pen, handwriting, and sensor services.
.DESCRIPTION
Enumerates services whose names or display names match known Tablet PC / pen /
handwriting / sensor patterns, reports their current state, then stops and
disables them. Reversible via Set-Service -StartupType Manual/Automatic.

Use -WhatIf for a dry run. Use -ListOnly to just report without changing anything.
.NOTES
Run as Administrator.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$ListOnly
)

$ErrorActionPreference = 'Continue'

function Write-Step  { param($m) Write-Host "[..] $m" -ForegroundColor Yellow }
function Write-Ok    { param($m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn2 { param($m) Write-Host "[!!] $m" -ForegroundColor Red }

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warn2 "This script must be run as Administrator. Exiting."
    exit 1
}

# --- Service name patterns to match (case-insensitive) ---
# These cover the common re-enablers of touch/pen policy after a keyboard-center purge.
$Patterns = @(
    'TabletInputService',      # Touch Keyboard and Handwriting Panel Service
    'TabletPC',                # Tablet PC Input Service
    'TabletService',           # Generic tablet service
    'WbioSrvc',                # (not tablet, but sometimes paired) - remove if unwanted
    'SensrSvc',                # Sensor Service
    'SensorService',           # Sensor Monitoring Service
    'SensorDataService',       # Sensor Data Service
    'SensorsService',
    'Handwriting',
    'PenService',
    'WispService',             # Windows Ink / pen
    'ShellHWDetection'         # sometimes entangled with tablet input
)

Write-Host "`n=== Tablet / Pen / Sensor Service Audit ===`n" -ForegroundColor Cyan

# --- 1. Discover matching services ---
Write-Step "Scanning services..."

$AllServices = Get-Service -ErrorAction SilentlyContinue
$Matches = foreach ($svc in $AllServices) {
    $displayName = (Get-CimInstance Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue).DisplayName
    $hit = $false
    foreach ($p in $Patterns) {
        if ($svc.Name -like "*$p*" -or $displayName -like "*$p*") { $hit = $true; break }
    }
    if ($hit) {
        [PSCustomObject]@{
            Name        = $svc.Name
            DisplayName = $displayName
            Status      = $svc.Status
            StartType   = $svc.StartType
        }
    }
}

if (-not $Matches) {
    Write-Warn2 "No matching tablet/pen/sensor services found."
    return
}

# --- 2. List them ---
Write-Host "`nMatched services:`n" -ForegroundColor Cyan
$Matches | Format-Table -AutoSize

if ($ListOnly) {
    Write-Host "ListOnly specified - no changes made." -ForegroundColor Yellow
    return
}

# --- 3. Stop and disable each ---
Write-Host "`nStopping and disabling...`n" -ForegroundColor Cyan
foreach ($svc in $Matches) {
    if ($PSCmdlet.ShouldProcess($svc.Name, "Stop and disable")) {
        try {
            if ($svc.Status -ne 'Stopped') {
                Stop-Service -Name $svc.Name -Force -ErrorAction Stop
                Write-Ok "Stopped: $($svc.Name)  ($($svc.DisplayName))"
            } else {
                Write-Step "Already stopped: $($svc.Name)"
            }
            Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction Stop
            Write-Ok "Disabled: $($svc.Name)"
        } catch {
            Write-Warn2 "Failed on $($svc.Name): $($_.Exception.Message)"
        }
    }
}

# --- 4. Show final state ---
Write-Host "`nFinal state:`n" -ForegroundColor Cyan
$Matches | ForEach-Object {
    $cur = Get-Service -Name $_.Name -ErrorAction SilentlyContinue
    if ($cur) {
        [PSCustomObject]@{
            Name      = $cur.Name
            Status    = $cur.Status
            StartType = $cur.StartType
        }
    }
} | Format-Table -AutoSize

Write-Host "`nDone. Reboot recommended." -ForegroundColor Yellow
Write-Host "To reverse: Set-Service -Name <name> -StartupType Manual" -ForegroundColor Gray