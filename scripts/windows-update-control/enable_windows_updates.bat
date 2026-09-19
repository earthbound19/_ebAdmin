:: Author: tsgrgo
:: Modified: must be launched via CmdT as TrustedInstaller (Enable All Privileges)
:: Re-enable Windows auto updates and undo all changes by 'disable updates.bat'
:: CmdT: https://github.com/wesmar/CmdT/releases

@echo off
setlocal EnableDelayedExpansion

:: --- Verify context: identity + required privileges -----------------------
set "WHOAMI="
for /f "tokens=*" %%u in ('whoami') do set "WHOAMI=%%u"
set "HAS_TAKEOWN="
set "HAS_RESTORE="
for /f "tokens=*" %%p in ('whoami /priv ^| findstr /i "SeTakeOwnershipPrivilege"') do set "HAS_TAKEOWN=1"
for /f "tokens=*" %%p in ('whoami /priv ^| findstr /i "SeRestorePrivilege"')     do set "HAS_RESTORE=1"

if /i not "%WHOAMI%"=="nt authority\system" goto :bad_context
if not defined HAS_TAKEOWN goto :bad_context
if not defined HAS_RESTORE goto :bad_context

echo Running as %WHOAMI% with required privileges. Proceeding...

:: --- Enable update related services ---------------------------------------
sc config wuauserv start= auto
sc config UsoSvc start= auto
sc config uhssvc start= delayed-auto

:: --- Restore renamed services ---------------------------------------------
for %%i in (WaaSMedicSvc, wuaueng) do (
	takeown /f C:\Windows\System32\%%i_BAK.dll && icacls C:\Windows\System32\%%i_BAK.dll /grant *S-1-1-0:F
	rename C:\Windows\System32\%%i_BAK.dll %%i.dll
	icacls C:\Windows\System32\%%i.dll /setowner "NT SERVICE\TrustedInstaller" && icacls C:\Windows\System32\%%i.dll /remove *S-1-1-0
)

:: --- Update registry ------------------------------------------------------
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 3 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v FailureActions /t REG_BINARY /d 840300000000000000000000030000001400000001000000c0d4010001000000e09304000000000000000000 /f
reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f

:: --- Enable all update related scheduled tasks ----------------------------
powershell -NoProfile -Command $paths = @( ^
'\Microsoft\Windows\InstallService*', ^
'\Microsoft\Windows\UpdateOrchestrator*', ^
'\Microsoft\Windows\UpdateAssistant*', ^
'\Microsoft\Windows\WaaSMedic*', ^
'\Microsoft\Windows\WindowsUpdate*', ^
'\Microsoft\WindowsUpdate*' ^
); ^
foreach ($path in $paths) { Get-ScheduledTask -TaskPath $path ^| Enable-ScheduledTask -ErrorAction SilentlyContinue }

echo Finished
pause
exit /b 0

:bad_context
echo.
echo ============================================================
echo  ERROR: Not running with the required privileges.
echo  This script must be launched via CmdT as TrustedInstaller
echo  with the full privilege set enabled.
echo.
echo  How to run it:
echo    cmdt -cli "%~nx0"
echo  (or open the CmdT GUI and select this file)
echo.
echo  Current user: %WHOAMI%
if not defined HAS_TAKEOWN echo  SeTakeOwnershipPrivilege: MISSING
if not defined HAS_RESTORE echo  SeRestorePrivilege:     MISSING
echo ============================================================
echo.
pause
exit /b 1