# DESCRIPTION
# Installs desired msys2 packages and does other customization setup.

# USAGE
# Run this script without any parameters:
#    MSYS2setup.sh
# NOTES
# This overwrites .ini and bash profile files with settings from the same directory this script is kept in. Those settings include:
# - inheriting SYSTEM environment variables on terminal launch
# - terminal font, color, and mouse interaction preferences
# - installing registry keys that provide right-click "MSYS2 Bash here" (also for compiler/dev environment) menus
# - if you don't get the mentioned right-click menu after running this, try right-clicking the .reg file to install it and then click "Merge," or try running this script again from a terminal launched with administrator privileges.
#
# Also see KNOWN ISSUES here.
#
# Some reference:
# h/t: https://www.rjh.io/blog/20190722-msys2_setup/
# The right-click menu provided via my fork of a tool: https://github.com/earthbound19/msys2-mingw-shortcut-menus
#
# KNOWN ISSUES
# You may need to run this script from an Administrator prompt to do install things, but then apparently config copies only copy and work properly after running this install script as a regular user. YOU MAY be able to work around that by running the MSYS2 installer as Administrator, then answering "yes" when it asks you if you want to run the MSYS2 terminal, which will open it to the current user.


# CODE
# TO DO:
# - fix the KNOWN ISSUE listed above if possible.
# - activate native symlinks via uncomment line in msys2_shell.cmd?
# - integrate mintty-colors or themes from the ../mintty-colors folder?

# Function: copy file to $1 if user responds y/Y; assumes a global variable $MSYS2installDir:
copy_to_msys2() {
    if [ -f "$MSYS2installDir/$1" ]; then
        read -p "Overwrite $MSYS2installDir/$1 with custom configuration y/n?: " USERINPUT
        if [ "$USERINPUT" = 'y' ] || [ "$USERINPUT" = 'Y' ]; then
            cp -f "$1" "$MSYS2installDir"
            echo "$1 copied."
        fi
    else
        cp -f "$1" "$MSYS2installDir"
        echo "$1 copied."
    fi
}

# == BEGIN MSYS2 USER CUSTOMIZATIONS == 
# copy profile customizations into MSYS2 user root:
MSYS2installDir=~
copy_to_msys2 .bashrc
copy_to_msys2 .minttyrc

# redefine install dir for the copy_to_msys2 function, for the following;
# get MSYS2 install root path; sed expression that captures MSYS2 install location, PERHAPS ERRONEOUSLY assuming that it's installed in a directory two up from what is returned by $WD; so check for existence of files there, and warn if not found. But if found, don't announce anything: just copy the files we want to copy over them:
MSYS2installDir="$WD"
MSYS2installDir=$(dirname $MSYS2installDir)
MSYS2installDir=$(dirname $MSYS2installDir)

copy_to_msys2 msys2.ini
copy_to_msys2 msys2_shell.cmd
copy_to_msys2 mingw64.ini
copy_to_msys2 mingw32.ini
# == END MSYS2 USER CUSTOMIZATIONS == 

# == BEGIN MSYS2 PACKAGES INSTALL AND UPGRADE == 
echo "u go kaboomy haha now you dead moldy voldy -Snep"

MSYS2_packages=(
vim
perl
p7zip
gcc
make
diffutils
bc
)

for element in ${MSYS2_packages[@]}
do
	# UNINSTALL option:
	# pacman -R --noconfirm $element
	pacman -S --noconfirm $element
done
# == END MSYS2 PACKAGES INSTALL AND UPGRADE == 


echo "DONE. If MSYS2 is not up to date, you may wish to run these commands, then exit the MSYS2 terminal, and run them again:"
echo "pacman -Syy"
echo "pacman -Suu"

echo "You may also wish to double-click either install_MSYS2_right_click_menu.reg or install_MSYS2_ruby_right_click_menu.reg to add right-click folder background and folder menus that will open the MSYS2 / MinGW terminals."