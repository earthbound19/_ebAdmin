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


echo "Copying system config files.."
# Get MSYS2 install root path using cygpath
MSYS2installDir=$(cygpath -m /)
# Ensure trailing slash is consistent for the -f tests
MSYS2installDir="${MSYS2installDir%/}/"
# echo MSYS2installDir is $MSYS2installDir

if [ -f "${MSYS2installDir}msys2_shell.cmd" ] && [ -f "${MSYS2installDir}msys2.ini" ] && [ -f "${MSYS2installDir}mingw64.ini" ] && [ -f "${MSYS2installDir}mingw32.ini" ]
then
    cp msys2_shell.cmd "$MSYS2installDir"
    cp msys2.ini "$MSYS2installDir"
    cp mingw64.ini "$MSYS2installDir"
    cp mingw32.ini "$MSYS2installDir"
    cd "$MSYS2installDir"
else
    echo "!----------------!"
    echo "PROBLEM: one or more files not found in: $MSYS2installDir"
    echo "!----------------!"
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

echo "Installing packages from list of used ones.."

for element in "${MSYS2_packages[@]}"
do
	pacman -S --noconfirm "$element"
done

echo "SYSTEM SETUP DONE. If MSYS2 is not up to date, you may wish to run these commands, then exit the MSYS2 terminal, and run them again:"
echo "pacman -Syy"
echo "pacman -Suu"
echo ""
echo "ALSO, if you have not already, you may wish to run the custom MSYS2 user setup via setup_MSYS2_local_user.sh."