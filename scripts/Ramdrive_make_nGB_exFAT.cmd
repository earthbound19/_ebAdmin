:: DESCRIPTION
:: Creates an exFAT empty ramdrive of size N gigabytes (hack the script to change the size) in memory, using ImDisk (Windows). Must be run as Administrator to format the new drive in the same step as creation.

:: DEPENDENCIES
:: imdisk must be installed and in your PATH.

:: USAGE
:: Copy this elsewhere and customize it per your wants to a ramdrive automatically at system start (for example with task scheduler). Or, double-click the script. Or, run it from cmd:
::    make_exFAT_ramdrive.cmd
:: NOTES
:: - The ramdrive is formatted as exFAT because that's a permissionless filesystem, which does away with permissions metadata overhead. Permissions will be created for files if they are copied out of the ramdrive to a typical permissioned file system like NTFS.
:: - Change the number in the RAMDRIVE_SIZE_IN_GIGABYTES variable assignment to change the drive size in gigabytes.

:: CODE
set RAMDRIVE_SIZE_IN_GIGABYTES=3

:: Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
	echo.
	echo ! ==
    echo ERROR: This script must be run as Administrator.
    echo Please right-click on the script or Command Prompt and select "Run as administrator".
    echo.
    pause
    exit /b 1
)

:: Check if R: drive already exists
if exist R:\ (
	echo.
    echo ERROR: Drive R: already exists!
    echo.
    pause
    exit /b 1
)

:: Create drive with "fixed" media type to prevent Windows from treating it as removable
imdisk -a -s %RAMDRIVE_SIZE_IN_GIGABYTES%g -m R: -p "/fs:exfat /v:RAMDRIVE /q /y"
:: another option if that fails: use -o fix:
:: imdisk -a -s %RAMDRIVE_SIZE_IN_GIGABYTES%g -m R: -o fix -p "/fs:exfat /v:RAMDRIVE /q /y"
if %errorlevel% equ 0 (
	echo.
	echo SUCCESS? Errorlevel 0 after attempt to create formatted ramdrive R:
	echo Hopefully that created successfully.
	echo.
	pause
)