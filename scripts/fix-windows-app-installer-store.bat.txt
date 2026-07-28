@echo off
setlocal EnableExtensions
title Fix Windows App Installer and Microsoft Store

net session >nul 2>&1
if not "%errorlevel%"=="0" (
  echo Requesting administrator rights...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo.
echo === Fix Windows App Installer and Microsoft Store ===
echo This script clears broken local PAC proxy settings, restores the WindowsApps
echo alias path, re-registers Store/App Installer packages, starts install services,
echo refreshes winget sources, validates the Store catalog, and resets Store cache.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "$content = Get-Content -Raw -LiteralPath '%~f0'; $marker = '### POWERSHELL_PAYLOAD ###'; $idx = $content.LastIndexOf($marker); if ($idx -lt 0) { throw 'PowerShell payload marker not found.' }; $payload = $content.Substring($idx + $marker.Length); Invoke-Expression $payload"
set "ERR=%ERRORLEVEL%"

echo.
if "%ERR%"=="0" (
  echo Done. Try installing from Microsoft Store again.
) else (
  echo Fix script failed with exit code %ERR%.
)
echo.
pause
exit /b %ERR%

### POWERSHELL_PAYLOAD ###
$ErrorActionPreference = 'Continue'

function Write-Step {
    param([string] $Message)
    Write-Host ''
    Write-Host ('=== ' + $Message + ' ===') -ForegroundColor Cyan
}

function Start-StoreService {
    param([string] $Name)
    try {
        $service = Get-Service -Name $Name -ErrorAction Stop
        if ($service.Status -ne 'Running') {
            Start-Service -Name $Name -ErrorAction Continue
            Write-Host ('Started service: ' + $Name)
        } else {
            Write-Host ('Service already running: ' + $Name)
        }
    } catch {
        Write-Host ('Service unavailable ' + $Name + ': ' + $_.Exception.Message) -ForegroundColor Yellow
    }
}

$desktop = [Environment]::GetFolderPath('Desktop')

Write-Step 'Backup PATH and Internet Settings'
$userPathBackup = Join-Path $desktop 'user-path-backup-before-store-fix.txt'
$internetBackup = Join-Path $desktop 'internet-settings-before-store-fix.reg'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
Set-Content -Path $userPathBackup -Value $userPath -Encoding UTF8
& reg.exe export 'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings' $internetBackup /y | Out-Null
Write-Host ('User PATH backup: ' + $userPathBackup)
Write-Host ('Internet Settings backup: ' + $internetBackup)

Write-Step 'Clear broken local PAC proxy'
$internetSettings = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
$autoConfig = (Get-ItemProperty -Path $internetSettings -Name AutoConfigURL -ErrorAction SilentlyContinue).AutoConfigURL
if ($autoConfig) {
    Write-Host ('Current AutoConfigURL: ' + $autoConfig)
} else {
    Write-Host 'AutoConfigURL is not set.'
}

if ($autoConfig -and ($autoConfig -match '^https?://(127\.0\.0\.1|localhost)[:/]')) {
    try {
        $pacUri = [Uri] $autoConfig
        $pacPort = $pacUri.Port
        if ($pacPort -gt 0) {
            $owners = @(
                Get-NetTCPConnection -LocalPort $pacPort -ErrorAction SilentlyContinue |
                    Where-Object { $_.State -eq 'Listen' } |
                    Select-Object -ExpandProperty OwningProcess -Unique
            )
            foreach ($owner in $owners) {
                try {
                    $proc = Get-Process -Id $owner -ErrorAction Stop
                    Write-Host ('Local PAC listener: ' + $proc.ProcessName + ' pid=' + $proc.Id + ' path=' + $proc.Path) -ForegroundColor Yellow
                } catch {
                    Write-Host ('Local PAC listener pid=' + $owner) -ForegroundColor Yellow
                }
            }
        }
    } catch {
        Write-Host ('Could not inspect PAC listener: ' + $_.Exception.Message) -ForegroundColor Yellow
    }

    Remove-ItemProperty -Path $internetSettings -Name AutoConfigURL -ErrorAction Continue
    Write-Host ('Removed local PAC AutoConfigURL: ' + $autoConfig) -ForegroundColor Green
} elseif ($autoConfig) {
    Write-Host ('Keeping non-local AutoConfigURL: ' + $autoConfig) -ForegroundColor Yellow
}

Set-ItemProperty -Path $internetSettings -Name ProxyEnable -Type DWord -Value 0
Set-ItemProperty -Path $internetSettings -Name AutoDetect -Type DWord -Value 0
& netsh.exe winhttp reset proxy | Out-Null

$afterAutoConfig = (Get-ItemProperty -Path $internetSettings -Name AutoConfigURL -ErrorAction SilentlyContinue).AutoConfigURL
if ($afterAutoConfig) {
    Write-Host ('WARNING: AutoConfigURL is still set after cleanup: ' + $afterAutoConfig) -ForegroundColor Red
    Write-Host 'Turn off System Proxy/PAC in the proxy app, then run this script again.' -ForegroundColor Red
} else {
    Write-Host 'AutoConfigURL cleanup verified.'
}

Write-Step 'Restore WindowsApps alias path'
$windowsApps = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
$parts = @(
    $userPath -split ';' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
)
if (-not ($parts | Where-Object { $_ -ieq $windowsApps })) {
    [Environment]::SetEnvironmentVariable('Path', (($parts + $windowsApps) -join ';'), 'User')
    Write-Host ('Added WindowsApps to user PATH: ' + $windowsApps) -ForegroundColor Green
} else {
    Write-Host ('WindowsApps already in user PATH: ' + $windowsApps)
}
if ($env:Path -notlike ('*' + $windowsApps + '*')) {
    $env:Path = $env:Path + ';' + $windowsApps
}

Write-Step 'Start Store/AppX services'
$services = 'BITS','AppXSvc','ClipSVC','InstallService','LicenseManager','DoSvc','UsoSvc','TokenBroker','StateRepository'
foreach ($serviceName in $services) {
    Start-StoreService -Name $serviceName
}

Write-Step 'Close Store/App Installer processes before re-registration'
$busyProcesses = 'WinStore.App','AppInstaller','WindowsPackageManagerServer'
foreach ($processName in $busyProcesses) {
    Get-Process -Name $processName -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host ('Stopping process: ' + $_.ProcessName + ' pid=' + $_.Id)
        Stop-Process -Id $_.Id -Force -ErrorAction Continue
    }
}
Start-Sleep -Seconds 2

Write-Step 'Re-register Microsoft Store and App Installer packages'
$packages = 'Microsoft.DesktopAppInstaller','Microsoft.WindowsStore','Microsoft.StorePurchaseApp','Microsoft.Services.Store.Engagement'
foreach ($packageName in $packages) {
    $matchedPackages = @(Get-AppxPackage -AllUsers -Name $packageName)
    if (-not $matchedPackages) {
        Write-Host ('Missing package: ' + $packageName) -ForegroundColor Yellow
        continue
    }

    foreach ($package in $matchedPackages) {
        $manifest = Join-Path $package.InstallLocation 'AppxManifest.xml'
        if (Test-Path $manifest) {
            Write-Host ('Registering ' + $package.PackageFullName)
            try {
                Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction Stop
                Write-Host ('Registered ' + $package.PackageFullName)
            } catch {
                $message = $_.Exception.Message
                if ($message -match '0x80073D02') {
                    Write-Host ('Skipped re-registration because the package is currently in use: ' + $package.PackageFullName) -ForegroundColor Yellow
                } else {
                    Write-Host ('Package re-registration warning for ' + $package.PackageFullName + ': ' + $message) -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host ('Missing manifest: ' + $manifest) -ForegroundColor Yellow
        }
    }
}

Write-Step 'Refresh winget sources'
$winget = Join-Path $windowsApps 'winget.exe'
if (Test-Path $winget) {
    Write-Host 'winget version:'
    & $winget --version
    Write-Host 'Resetting winget sources...'
    & $winget source reset --force
    Write-Host 'Updating winget sources...'
    & $winget source update

    Write-Step 'Validate Microsoft Store catalog'
    Write-Host 'Checking Spotify product id 9NCBCSZSJRSB through msstore source...'
    & $winget show --id 9NCBCSZSJRSB --source msstore --accept-source-agreements
} else {
    Write-Host ('winget alias not found: ' + $winget) -ForegroundColor Red
}

Write-Step 'Reset Microsoft Store cache'
Start-Process -FilePath 'wsreset.exe' -Wait

Write-Step 'Final status'
$finalInternet = Get-ItemProperty -Path $internetSettings
[pscustomobject]@{
    ProxyEnable = $finalInternet.ProxyEnable
    AutoConfigURL = $finalInternet.AutoConfigURL
    AutoDetect = $finalInternet.AutoDetect
} | Format-List

Write-Host 'Fix completed. Open a new terminal so PATH changes take effect.'
Write-Host 'If Clash Verge or another proxy app re-enables System Proxy/PAC, turn that option off before installing Store apps.'
