@echo off
setlocal DisableDelayedExpansion

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Run as Administrator.
    pause & exit /b 1
)

set /p TARGET_USER=Enter target username: 
if "%TARGET_USER%"=="" exit /b 1

set "UP=C:\Users\%TARGET_USER%"
if not exist "%UP%" (
    echo [ERROR] Profile not found: %UP%
    pause & exit /b 1
)

if /i "%USERNAME%"=="%TARGET_USER%" (
    echo.
    echo [WARNING] You are repairing the profile of the CURRENTLY logged-on user.
    echo Some files may be in use, and permission resets may not fully apply until you sign out.
    echo.
    set /p "CONFIRM=Continue anyway? ^(Y/N^): "
    if /i not "%CONFIRM%"=="Y" (
        echo Cancelled.
        pause & exit /b 0
    )
)

echo.
echo Fixing ONLY these real data folders (junctions will NOT be touched):
echo   Desktop, Documents, Downloads, Pictures, Music, Videos
echo.

for %%D in (Desktop Documents Downloads Pictures Music Videos) do (
    if exist "%UP%\%%D" (
        echo [FIX] %UP%\%%D
        takeown /f "%UP%\%%D" /r /d y >nul 2>&1
        icacls "%UP%\%%D" /reset /t /c /l >nul 2>&1
        icacls "%UP%\%%D" /grant "%TARGET_USER%":^(OI^)^(CI^)F /t >nul 2>&1
    ) else (
        echo [SKIP] %UP%\%%D (not found)
    )
)

echo.
echo Done. AppData and junction points were NOT modified.
pause

:debugend