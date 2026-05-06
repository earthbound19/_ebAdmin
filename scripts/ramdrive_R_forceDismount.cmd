: DESCRIPTION
:: Force dismounts a ramdrive R: assumed to be created earlier via imdisk or a ramdrive create batch. Uses ImDisk (Windows). Prompts user with y/n before dismounting; dismounts if given y and does not if given n.

:: DEPENDENCIES
:: imdisk 2.1.1 or newer must be installed and in your PATH. Older versions may fail to format the ramdrive in the same command it is created, as this script attempts to do.

:: USAGE
:: Copy this elsewhere and customize it per your wants to a ramdrive automatically at system start (for example with task scheduler). Or, double-click the script. Or, run it from cmd, AS AN ADMINISTRATOR:
::    ramdrive_R_forceDismount.cmd
:: NOTES


:: CODE
@echo off
echo WARNING: This will FORCE dismount ramdrive R:
echo This may cause data loss if you have open files on this drive!
echo
echo "This will force dismount ramdrive R:"
echo "Type YES (or yes) and press Enter to continue, or any other key to cancel."
set /p CONFIRM=
if /i not "%CONFIRM%"=="YES" (
	echo.
    echo Operation cancelled.
    exit /b 0
)

imdisk -D -m R:

if errorlevel 2 (
    echo.
    echo Operation cancelled. No changes were made.
    exit /b 0
)

if errorlevel 0 (
	echo.
    echo SUCCESS? Errorlevel 0 after attempt to force dismount Ramdrive R:
	echo Hopefully that dismounted successfully.
)