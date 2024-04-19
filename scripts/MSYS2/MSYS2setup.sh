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
# Also see KNOWN ISSUES here.
# KNOWN ISSUES
# You may need to run this script from an Administrator prompt to do install things, but then apparently config copies only copy and work properly after running this install script as a regular user. YOU MAY be able to work around that by running the MSYS2 installer as Administrator, then answering "yes" when it asks you if you want to run the MSYS2 terminal, which will open it to the current user.


# CODE
# TO DO:
# - fix the KNOWN ISSUE listed above if possible.
# - activate native symlinks via uncomment line in msys2_shell.cmd?
# - integrate mintty-colors or themes from the ../mintty-colors folder?
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

# packages I may in the future use:
# mingw-w64-x86_64-libc++
# mingw-w64-x86_64-boost
# mingw-w64-x86_64-gcc

for element in ${MSYS2_packages[@]}
do
	# UNINSTALL option:
	# pacman -R --noconfirm $element
	pacman -S --noconfirm $element
done

# copy profile customizations into MSYS2 user root:
cp ./.bashrc ~
cp ./.minttyrc ~

# get MSYS2 install root path; sed expression that captures MSYS2 install location, PERHAPS ERRONEOUSLY assuming that it's installed in a directory two up from what is returned by $WD; so check for existence of files there, and warn if not found. But if found, don't announce anything: just copy the files we want to copy over them:
MSYS2installDir="$WD"
MSYS2installDir=$(dirname $MSYS2installDir)
MSYS2installDir=$(dirname $MSYS2installDir)
if [ -f $MSYS2installDir/msys2_shell.cmd ] && [ -f $MSYS2installDir/msys2.ini ] && [ -f $MSYS2installDir/mingw64.ini ] && [ -f $MSYS2installDir/mingw32.ini ]
then
	cp msys2_shell.cmd $MSYS2installDir
	cp msys2.ini $MSYS2installDir
	cp mingw64.ini $MSYS2installDir
	cp mingw32.ini $MSYS2installDir
else
	echo "!----------------!"
	echo "PROBLEM: one or more of these files was not found in the MSYS2 install directory:"
	echo "msys2_shell.cmd msys2.ini mingw64.ini mingw32.ini"
	echo "To copy custom configuration, locate those files manually, and copy the files from the path of this script to that location."
	echo "!----------------!"
	echo ""
fi


echo "DONE. If MSYS2 is not up to date, you may wish to run these commands, then exit the MSYS2 terminal, and run them again:"
echo "pacman -Syy"
echo "pacman -Suu"

echo "You may also wish to double-click either install_MSYS2_right_click_menu.reg or install_MSYS2_ruby_right_click_menu.reg to add right-click folder background and folder menus that will open the MSYS2 / MinGW terminals."


# DEVELOPER NOTES
# Some reference on that:
# h/t: https://www.rjh.io/blog/20190722-msys2_setup/
# The right-click menu provided via my fork of a tool: https://github.com/earthbound19/msys2-mingw-shortcut-menus
#
# In my Cygwin setup and I don't know why:
# libmpfr-devel, libgmp-devel, lynx
# gcc-g++, but I hope just gcc here is equivalent
# chere
#
# vim is in this list because it includes xxd. But, um . . also vim? :|
#
# I hoped this would include iostream.h; nope:
# mingw-w64-x86_64-gcc