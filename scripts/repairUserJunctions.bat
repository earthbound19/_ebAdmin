@echo off
setlocal EnableDelayedExpansion

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run as Administrator.
    pause & exit /b 1
)

set /p TARGET_USER=Enter the target username: 
set "UP=C:\Users\%TARGET_USER%"

if not exist "%UP%" (
    echo [ERROR] User profile not found: %UP%
    pause & exit /b 1
)

echo.
echo [1/4] Removing broken junctions (if they exist)...
if exist "%UP%\AppData\Local\Application Data" (
    rmdir "%UP%\AppData\Local\Application Data"
    echo   Removed: AppData\Local\Application Data
)
if exist "%UP%\Application Data" (
    rmdir "%UP%\Application Data"
    echo   Removed: Application Data
)
if exist "%UP%\AppData\Local\History" (
    rmdir "%UP%\AppData\Local\History"
    echo   Removed: AppData\Local\History
)
if exist "%UP%\AppData\Local\Temporary Internet Files" (
    rmdir "%UP%\AppData\Local\Temporary Internet Files"
    echo   Removed: AppData\Local\Temporary Internet Files
)

echo.
echo [2/4] Recreating junctions with correct targets...
cd /d "%UP%\AppData\Local"
mklink /j "Application Data" .
mklink /j "History" ".\Microsoft\Windows\History"
mklink /j "Temporary Internet Files" ".\Microsoft\Windows\Temporary Internet Files"

echo.
echo [3/4] Recreating root-level junction...
cd /d "%UP%"
if exist "%UP%\AppData\Roaming" (
    mklink /j "Application Data" "%UP%\AppData\Roaming"
) else (
    echo   [SKIP] AppData\Roaming not found, cannot create root Application Data.
)

echo.
echo [4/4] Restoring protection (deny everyone)...
icacls "%UP%\AppData\Local\Application Data" /deny "Everyone":(OI)(CI)(RX) /t /c /l 2>nul
icacls "%UP%\Application Data" /deny "Everyone":(OI)(CI)(RX) /t /c /l 2>nul

echo.
echo ========================================================
echo Repair completed.
echo ========================================================
pause