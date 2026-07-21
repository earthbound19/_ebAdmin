:: DESCRIPTION
:: Creates an exFAT empty ramdrive of size N gigabytes (hack the script to change the size) in memory, using ImDisk (Windows). Must be run as Administrator to format the new drive in the same step as creation.

:: DEPENDENCIES
:: imdisk must be installed and in your PATH.

:: USAGE
:: Copy this elsewhere and customize it per your wants to create a ramdrive automatically at system start (for example with task scheduler). Or, hack and double-click the script. Or, run it from cmd:
::    Ramdrive_make_nMB_exFAT.cmd
:: If you run it from cmd you may pass a parameter %1, which is the size of the ramdrive in megabytes (where 1000 megabytes would be approximately a gigabyte). For example to create a 1,500 megabyte ramdrive, run:
::    Ramdrive_make_nMB_exFAT.cmd 1500
:: NOTES
:: - The ramdrive is formatted as exFAT because that's a permissionless filesystem, which does away with permissions metadata overhead. Permissions will be created for files if they are copied out of the ramdrive to a typical permissioned file system like NTFS.
:: - If you specify a size for the drive that exceeds the exFAT partition maximum size, automatic formatting of the ramdrive may fail, and you may need to manually format it.
:: - Change the number in the RAMDRIVE_SIZE_IN_MILLION_BYTES variable assignment to change the drive size in million bytes. That may translate to ~megabytes, where 1,000 ~= 1 gigabyte, or 400 is ~400 megabytes.

:: CODE
@ECHO OFF

SET DEFAULT_RAMDRIVE_SIZE=1240
if "%1"=="" (
    set RAMDRIVE_SIZE_IN_MILLION_BYTES=%DEFAULT_RAMDRIVE_SIZE%
	echo "ramrdrive set to default (hard-coded) size %DEFAULT_RAMDRIVE_SIZE%."
) else (
    set RAMDRIVE_SIZE_IN_MILLION_BYTES=%1
	echo "ramrdrive is set via switch 1 to size %1."
)

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
imdisk -a -s %RAMDRIVE_SIZE_IN_MILLION_BYTES%m -m R: -p "/fs:exfat /v:RAMDRIVE /q /y"
:: another option if that fails: use -o fix:
:: imdisk -a -s %RAMDRIVE_SIZE_IN_MILLION_BYTES%g -m R: -o fix -p "/fs:exfat /v:RAMDRIVE /q /y"
if %errorlevel% equ 0 (
	echo.
	echo SUCCESS? Errorlevel 0 after attempt to create formatted ramdrive R:
	echo Hopefully that created successfully.
	echo.
	pause
)
