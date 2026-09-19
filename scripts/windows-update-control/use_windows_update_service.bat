:: Author: tsgrgo
:: Re-enable the Windows Update Service so apps that depend on it can run.
:: Must be launched via CmdT as TrustedInstaller (Enable All Privileges)
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

:: --- Restore renamed service ----------------------------------------------
for %%i in (wuaueng) do (
	takeown /f C:\Windows\System32\%%i_BAK.dll && icacls C:\Windows\System32\%%i_BAK.dll /grant *S-1-1-0:F
	rename C:\Windows\System32\%%i_BAK.dll %%i.dll
	icacls C:\Windows\System32\%%i.dll /setowner "NT SERVICE\TrustedInstaller" && icacls C:\Windows\System32\%%i.dll /remove *S-1-1-0
)

:: --- Change service config ------------------------------------------------
sc config wuauserv start= auto

echo.
echo Enabled Windows Update Service
echo You can now use software that relies on the Windows Update Service.
echo When finished, you can run the disabler again.
echo More info in README
echo.
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