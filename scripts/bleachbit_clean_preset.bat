:: Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
	echo.
	echo ! ==
    echo ERROR: This script must be run as Administrator.
    echo Please right-click on the script and select "Run as administrator",
	echo or run it from a CMD prompt started with Administrator privileges.
    echo.
    pause
    exit /b 1
)

"%userprofile%\AppData\Local\BleachBit\bleachbit_console.exe" --clean --preset