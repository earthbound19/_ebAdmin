#!/bin/bash
# DESCRIPTION
# Installs often (or potentially often?) used MSYS2 packages in the install directories' global package repository, and updates configuration files in the MSYS2 installation directory (MSYS2 system scope customization).

# USAGE
# Run this script with administrator/root privileges from an MSYS2 bash terminal:
#    ./setup_MSYS2_local_system_and_packages.sh
# NOTES
# - this requires write access to the MSYS2 root installation directory (granted by admin privilege).
# - this overwrites .ini and shell script files in the MSYS2 root installation directory with custom configs. See the .ini and .cmd files alongside this script.


# CODE
# Require administrator privileges and exit if none
net session >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "!----------------!"
	echo "ERROR: This script must be run with Administrator privileges."
	echo "Restart your MSYS2 terminal as an Administrator and run this"
	echo "script again."
	echo "!----------------!"
	exit 1
fi

MSYS2_packages=(
vim
perl
p7zip
gcc
make
diffutils
bc
rsync
)

for element in "${MSYS2_packages[@]}"
do
	pacman -S --noconfirm "$element"
done

# Get MSYS2 install root path and copy system-level config files
MSYS2installDir="$WD"
MSYS2installDir=$(dirname "$MSYS2installDir")
MSYS2installDir=$(dirname "$MSYS2installDir")
if [ -f "$MSYS2installDir/msys2_shell.cmd" ] && [ -f "$MSYS2installDir/msys2.ini" ] && [ -f "$MSYS2installDir/mingw64.ini" ] && [ -f "$MSYS2installDir/mingw32.ini" ]
then
	cp msys2_shell.cmd "$MSYS2installDir"
	cp msys2.ini "$MSYS2installDir"
	cp mingw64.ini "$MSYS2installDir"
	cp mingw32.ini "$MSYS2installDir"
else
	echo "!----------------!"
	echo "PROBLEM: one or more of these files was not found in the MSYS2 install directory:"
	echo "msys2_shell.cmd msys2.ini mingw64.ini mingw32.ini"
	echo "To copy custom configuration, locate those files manually, and copy the files from the path of this script to that location."
	echo "!----------------!"
	echo ""
fi

echo "SYSTEM SETUP DONE. If MSYS2 is not up to date, you may wish to run these commands, then exit the MSYS2 terminal, and run them again:"
echo "pacman -Syy"
echo "pacman -Suu"
echo ""
echo "ALSO, if you have not already, you may wish to run the custom MSYS2 user setup via setup_MSYS2_local_user.sh."