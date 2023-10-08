:: DESCRIPTION
:: Installs all packages I commonly use from chocolatey.

:: DEPENDENCIES
:: `chocolatey`, with all its dependencies.
:: See installChocolatey_instructions.txt to get chocolatey installed.

:: USAGE
:: Modify the list of packages (broken over newlines in a loop for easier editing) per your wants. (There may also be a commented list of packages to potentially use, which you may want to shuffle into the actual used list.) Then, run this script from a Windows CMD prompt:
::    installUsedChocolateyPackages.bat
:: NOTES
:: To list installed packages, run:
::    choco list --local-only


:: CODE
@echo off 

setlocal EnableDelayedExpansion
set n=0
for %%a in (
hub
7zip.install
openssh
clink
jq
) do (
   choco install %%a -y
)

REM POTENTIAL PACKAGES list:
REM chocolateygui
REM paint.net
REM vlc
REM chromium
REM treesizefree
REM libreoffice-fresh
REM ccleaner
REM strawberryperl
REM ruby
REM pdfcreator
REM malwarebytes
REM putty.install