#Requires -RunAsAdministrator
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=== NTFS Permission Nuclear Reset Tool ===" -ForegroundColor Red
Write-Host "This script will forcefully take ownership and grant FULL CONTROL to Everyone" -ForegroundColor Yellow
Write-Host "for every file and folder on a specified drive letter (while also stripping" -ForegroundColor Yellow
Write-Host "all other permissions)." -ForegroundColor Yellow
Write-Host ""

# 1. Mandatory Drive Selection & Validation
$driveLetter = Read-Host -Prompt "Enter the target drive letter (e.g., E, F, G)"
$driveLetter = $driveLetter -replace '[^a-zA-Z]', '' # Strip non-letters

if ([string]::IsNullOrWhiteSpace($driveLetter)) {
    Write-Host "Operation cancelled. No drive letter provided." -ForegroundColor Red
    exit
}

$targetDrive = "$($driveLetter.ToUpper()):\"

if (!(Test-Path $targetDrive)) {
    Write-Host "Error: Drive '$targetDrive' does not exist or is not ready." -ForegroundColor Red
    exit
}

# Safety check: Prevent running on C:\ (OS drive)
if ($targetDrive -eq "C:\") {
    Write-Host "ABORT: You cannot run this on the system drive (C:\)!" -ForegroundColor Red
    exit
}

# Final confirmation prompt requiring explicit input
$confirmation = Read-Host -Prompt "WARNING: You are about to strip all custom permissions on $targetDrive. Type 'YES' to confirm"
if ($confirmation -ne 'YES') {
    Write-Host "Operation cancelled by user." -ForegroundColor Yellow
    exit
}

Write-Host "`nProcessing $targetDrive... This may take a while depending on drive size." -ForegroundColor Cyan

# 2. Take Ownership of the entire drive root and subcontainers
Write-Host "[1/3] Taking ownership..." -ForegroundColor Yellow
& takeown.exe /f $targetDrive /r /d y | Out-Null

# 3. Grant Administrators and SYSTEM full control explicitly
Write-Host "[2/3] Granting base administrative control..." -ForegroundColor Yellow
& icacls.exe $targetDrive /setowner "Administrators" /T /C /Q | Out-Null
& icacls.exe $targetDrive /grant "Administrators:(OI)(CI)F" /T /C /Q | Out-Null
& icacls.exe $targetDrive /grant "SYSTEM:(OI)(CI)F" /T /C /Q | Out-Null

# 4. Strip everything else and grant Everyone full control (Nuclear step)
Write-Host "[3/3] Stripping legacy SIDs and setting 'Everyone' full access..." -ForegroundColor Yellow
& icacls.exe $targetDrive /reset /T /C /Q | Out-Null
& icacls.exe $targetDrive /grant "Everyone:(OI)(CI)F" /T /C /Q | Out-Null

Write-Host "`nSuccess! Drive $targetDrive is now permissionless and fully accessible to Everyone." -ForegroundColor Green