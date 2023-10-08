:: DESCRIPTION
:: Creates an exFAT empty ramdrive of size N gigabytes (hack the script to change the size) in memory, using ImDisk (Windows).

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
imdisk -a -s %RAMDRIVE_SIZE_IN_GIGABYTES%g -m R: -p "/fs:exfat /v:RAMDRIVE /q /y"