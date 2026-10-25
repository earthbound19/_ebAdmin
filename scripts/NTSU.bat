:: DESCRIPTION
:: NT Super User, or NTSU. Opens a CMD or Windows "command prompt" with "NT Authority/System" privileges. It may allow you to do things an Administrator terminal can't. A better optino is CMDT. NSudo is also valid but no longer in development.

:: DEPENDENCIES
:: paexec may need a particular Windows service to be running as it uses "remote" execution locally.

:: USAGE
:: You may need to run this from a command prompt or account with administrative privileges, or right-click it and "Run as Administrator:"
::    NTSU.bat


:: CODE
paexec -i -s cmd

:: Or alternately? :
:: paexec \\localhost -i -s cmd.exe