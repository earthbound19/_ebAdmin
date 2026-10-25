<#
.SYNOPSIS
Scorched-earth removal of Microsoft Mouse and Keyboard Center.
.DESCRIPTION
This script attempts to kill processes, disable services, remove scheduled
tasks, uninstall the application, delete leftover folders, and scrub registry
keys related to the Microsoft Mouse & Keyboard Center.
.NOTES
Run as Administrator. Use -WhatIf for a dry run.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param()

# --- Setup ---
$ErrorActionPreference = 'Continue'
$AppName = "Microsoft Mouse and Keyboard Center"
$AppFolder = "$env:ProgramFiles\Microsoft Mouse and Keyboard Center"

function Write-Step { param($m) Write-Host "[..] $m" -ForegroundColor Yellow }
function Write-Ok { param($m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn2 { param($m) Write-Host "[!!] $m" -ForegroundColor Red }

# --- Admin Check ---
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warn2 "This script must be run as Administrator. Exiting."
    exit 1
}

Write-Host "`n=== Scorched-Earth Purge: $AppName ===`n" -ForegroundColor Cyan

# --- 1. Kill Processes ---
Write-Step "Killing related processes..."
$ProcessNames = @("mousekeyboardcenter", "ipoint", "itype", "mkchelper", "CEIP", "devcon")
foreach ($proc in $ProcessNames) {
    if (Get-Process -Name $proc -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess($proc, "Stop Process")) {
            Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
            Write-Ok "Killed process: $proc"
        }
    }
}

# --- 2. Disable Services ---
Write-Step "Disabling related services..."
$ServiceNames = @("MicrosoftMouseKeyboardCenter", "ipoint", "itype")
foreach ($svc in $ServiceNames) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess($svc, "Stop and Disable Service")) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Ok "Disabled service: $svc"
        }
    }
}

# --- 3. Remove Scheduled Tasks ---
Write-Step "Removing scheduled tasks..."
$TaskNames = @(
    "Microsoft_MKC_Logon_Task_ipoint",
    "Microsoft_MKC_Logon_Task_itype",
    "Microsoft_Hardware_Launch_ipoint_exe",
    "Microsoft_Hardware_Launch_itype_exe",
    "Microsoft_Hardware_Launch_mousekeyboardcenter_exe"
)
foreach ($task in $TaskNames) {
    if (Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess($task, "Unregister Scheduled Task")) {
            Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction SilentlyContinue
            Write-Ok "Removed task: $task"
        }
    }
}

# --- 4. Uninstall Application (Traditional) ---
Write-Step "Attempting traditional uninstall via setup.exe..."
$SetupExe = Join-Path $AppFolder "setup.exe"
if (Test-Path $SetupExe) {
    if ($PSCmdlet.ShouldProcess($SetupExe, "Run Uninstaller")) {
        Start-Process -FilePath $SetupExe -ArgumentList "/uninstall /quiet" -Wait -NoNewWindow
        Write-Ok "Uninstall command executed."
    }
} else {
    Write-Warn2 "Setup executable not found. Skipping."
}

# --- 5. Uninstall Appx / Provisioned Packages ---
Write-Step "Checking for Appx/Provisioned packages..."
$AppxPackage = Get-AppxPackage -Name "*MouseKeyboardCenter*" -AllUsers -ErrorAction SilentlyContinue
if ($AppxPackage) {
    foreach ($pkg in $AppxPackage) {
        if ($PSCmdlet.ShouldProcess($pkg.PackageFullName, "Remove AppxPackage")) {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
            Write-Ok "Removed Appx: $($pkg.Name)"
        }
    }
} else {
    Write-Step "No Appx packages found."
}

$ProvisionedPackage = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*MouseKeyboardCenter*" }
if ($ProvisionedPackage) {
    foreach ($prov in $ProvisionedPackage) {
        if ($PSCmdlet.ShouldProcess($prov.PackageName, "Remove Provisioned Package")) {
            Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue
            Write-Ok "Removed provisioned package: $($prov.DisplayName)"
        }
    }
} else {
    Write-Step "No provisioned packages found."
}

# --- 6. Delete Leftover Folders ---
Write-Step "Deleting leftover folders..."
$FoldersToDelete = @(
    $AppFolder,
    "$env:ProgramFiles(x86)\Microsoft Mouse and Keyboard Center",
    "$env:ProgramData\Microsoft\Mouse and Keyboard Center",
    "$env:LOCALAPPDATA\Microsoft\Mouse and Keyboard Center"
)
foreach ($folder in $FoldersToDelete) {
    if (Test-Path $folder) {
        if ($PSCmdlet.ShouldProcess($folder, "Remove Directory")) {
            Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
            Write-Ok "Deleted: $folder"
        }
    }
}

# --- 7. Scrub Registry Keys ---
Write-Step "Scrubbing registry keys..."
$RegKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Mouse and Keyboard Center",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Mouse and Keyboard Center",
    "HKLM:\SOFTWARE\Classes\Installer\Products\F33289F6C09283640899C22C3C195B7B",
    "HKLM:\SOFTWARE\Classes\Installer\Products\44DC76DA5E30127458CEECEA1EB745D2",
    "HKLM:\SOFTWARE\Classes\Installer\Products\868549AFC7932F441A4A3542A4D1463B",
    "HKLM:\SOFTWARE\Classes\Installer\Products\7CFA2D32E10C3144D9A9B0BA5F5296FB",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)
foreach ($key in $RegKeys) {
    if (Test-Path $key) {
        if ($PSCmdlet.ShouldProcess($key, "Remove Registry Key")) {
            Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
            Write-Ok "Deleted registry key: $key"
        }
    }
}

# --- 8. Remove Run Entries ---
Write-Step "Removing startup registry entries..."
$RunKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
if (Test-Path $RunKey) {
    $props = Get-ItemProperty -Path $RunKey -ErrorAction SilentlyContinue
    foreach ($prop in $props.PSObject.Properties) {
        if ($prop.Name -like "*MouseKeyboard*" -or $prop.Name -like "*mousekeyboard*") {
            if ($PSCmdlet.ShouldProcess($RunKey, "Remove Property: $($prop.Name)")) {
                Remove-ItemProperty -Path $RunKey -Name $prop.Name -Force -ErrorAction SilentlyContinue
                Write-Ok "Removed Run entry: $($prop.Name)"
            }
        }
    }
}

Write-Host "`n=== Purge Complete ===" -ForegroundColor Cyan
Write-Host "A reboot is recommended to finalize removal." -ForegroundColor Yellow