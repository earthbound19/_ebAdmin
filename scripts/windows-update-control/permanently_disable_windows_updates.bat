:: Author: tsgrgo
:: Completely disable Windows Update
:: Must be launched via CmdT as TrustedInstaller (Enable All Privileges)
:: CmdT: https://github.com/wesmar/CmdT/releases
::
:: NOTES / KNOWN BEHAVIORS
:: -----------------------
:: - This script will not self-elevate. If the context check below fails,
::   it prints a diagnostic and exits with code 1. Launch it via:
::       cmdt -cli "%~nx0"
::   or select it from the CmdT GUI.
::
:: - The service-stop loop retries each service up to 7 times (2s apart)
::   if it is still RUNNING or STOP_PENDING. Some services -- notably
::   WaaSMedicSvc -- can resist being stopped if a failure action is
::   mid-flight or a scheduled task re-triggers them. If a service will
::   not stop within the retry budget, the script reports it, skips to
::   the next service, and continues. A stuck service means the machine
::   has an SCM-level problem this script cannot fix by waiting longer.
::
:: - The rename step for wuaueng.dll / WaaSMedicSvc.dll takes ownership
::   away from TrustedInstaller temporarily, renames the file, then hands
::   ownership back. If the script is interrupted between those steps,
::   the file may be left owned by Administrators. Re-running the script
::   (or enable updates.bat) will recover.

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

:: --- Disable update related services --------------------------------------
for %%i in (wuauserv, UsoSvc, uhssvc, WaaSMedicSvc) do (
	set /a TRIES=0
	:wu_stop_retry
	sc config %%i start= disabled
	sc failure %%i reset= 0 actions= ""
	net stop %%i
	(sc query %%i | find "RUNNING" || sc query %%i | find "STOP_PENDING") && (
		set /a TRIES+=1
		if !TRIES! geq 7 (
			echo.
			echo WARNING: %%i did not stop after 7 attempts.
			echo          It may be wedged or being restarted by a scheduled task.
			echo          Skipping it and continuing with the remaining services.
			echo          Run 'sc query %%i' after this script to inspect its state.
			echo.
		) else (
			echo %%i still running, retrying ^(!TRIES!/7^)...
			timeout /t 2 >nul
			goto :wu_stop_retry
		)
	)
)

:: --- Brute force rename services ------------------------------------------
for %%i in (WaaSMedicSvc, wuaueng) do (
	takeown /f C:\Windows\System32\%%i.dll && icacls C:\Windows\System32\%%i.dll /grant *S-1-1-0:F
	rename C:\Windows\System32\%%i.dll %%i_BAK.dll
	icacls C:\Windows\System32\%%i_BAK.dll /setowner "NT SERVICE\TrustedInstaller" && icacls C:\Windows\System32\%%i_BAK.dll /remove *S-1-1-0
)

:: --- Update registry ------------------------------------------------------
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v FailureActions /t REG_BINARY /d 000000000000000000000000030000001400000000000000c0d4010000000000e09304000000000000000000 /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f

:: --- Delete downloaded update files ---------------------------------------
erase /f /s /q c:\windows\softwaredistribution\*.* && rmdir /s /q c:\windows\softwaredistribution

:: --- Disable all update related scheduled tasks ---------------------------
powershell -NoProfile -Command $paths = @( ^
'\Microsoft\Windows\InstallService*', ^
'\Microsoft\Windows\UpdateOrchestrator*', ^
'\Microsoft\Windows\UpdateAssistant*', ^
'\Microsoft\Windows\WaaSMedic*', ^
'\Microsoft\Windows\WindowsUpdate*', ^
'\Microsoft\WindowsUpdate*' ^
); ^
foreach ($path in $paths) { Get-ScheduledTask -TaskPath $path ^| Disable-ScheduledTask -ErrorAction SilentlyContinue }

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