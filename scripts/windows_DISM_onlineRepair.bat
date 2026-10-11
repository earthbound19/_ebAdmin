:: DESCRIPTION
:: Performs a Windows image repair / cleanup, then system file scan and repair.

:: USAGE
:: From a command prompt with administrative privileges, run this script:
::    windows_DISM_onlineRepair.bat
:: REFERENCE URLS
:: - https://support.microsoft.com/en-us/help/947821/fix-windows-update-errors-by-using-the-dism-or-system-update-readiness-tool
:: - https://davescomputertips.com/sfc-fails-to-fix-errors-what-now/

:: CODE
net stop wuauserv
net stop cryptsvc
net stop bits
net stop msiserver
ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
ren C:\Windows\System32\catroot2 catroot2.old
net start wuauserv
net start cryptsvc
net start bits
net start msiserver

Dism /Online /Cleanup-Image /CheckHealth
Dism /Online /Cleanup-Image /ScanHealth
:: Dism /Online /Cleanup-Image /RestoreHealth
:: OR e.g.; re: https://www.windowscentral.com/how-use-dism-command-line-utility-repair-windows-10-image
:: Dism /Online /Cleanup-Image /RestoreHealth /Source:C:\Recovery\whatever path\Winre.wim


echo.
echo also try this command also from an admin prompt:
echo DISM /Online /Cleanup-Image /RestoreHealth /Source:Y:\path_to\extracted\windowsISO\sources\install.wim /LimitAccess
echo.
echo and then:
echo SFC /scannow