# DESCRIPTION
# Commands to install wanted tools and custom configuration for a Cygwin install.

# USAGE
# Maybe don't use this. I have come to far prefer MSYS2 over Cygwin. See MSYS2setup.sh. But if you use this, run it from the directory with the installer, with this script and the other files it needs (CYGWIN_fstab, my.minttyrc.settings.txt) in your PATH, or copy the Cygwin installer to this directory before executing this script. Comment out the line for the Cygwin installer version you don't want to use.
# Then open the Cygwin prompt, cd to this path, and run the script without any parameter:
#    cygwinSetup.sh


# CODE
installParams="-q -P Perl -P gcc-g++ -P make -P diffutils -P libmpfr-devel -P libgmp-devel -P libmpc-devel -P bc -P lynx -P chere"

# ./Cygwin_setup-x86.exe $installParams
./Cygwin_setup-x86_64.exe $installParams

# re: https://stackoverflow.com/a/12010346/1397555
chere -i -t mintty -s bash

lynx -source rawgit.com/transcode-open/apt-cyg/master/apt-cyg > apt-cyg
dos2unix apt-cyg
install apt-cyg /bin

# temporarily switch apt-cyg mirror to source that has XXD; install that and switch it back:
apt_cyg_mirror=`apt-cyg mirror`
apt-cyg mirror "ftp://mirrors.syringanetworks.net/Cygwin/"
apt-cyg install xxd
apt-cyg mirror "$apt_cyg_mirror"

username=`whoami`
echo "Username is $username. OVERWRITING configuration of /home/$username/.minttyrc with my.minttyrc.settings.txt. Continue?"
echo "!============================================================"
read -p "DO YOU WISH TO CONTINUE running this script? : y/n" CONDITION;
if [ "$CONDITION" == "y" ]; then
		echo Ok! Attempting overwrite . . .
		cat ./my.minttyrc.settings.txt > /home/$username/.minttyrc
		echo Done. Exit and restart the shell after all of the remaining commands complete, to see if the configuration \"stuck.\"
	else
		echo D\'oh!; exit;
fi

# Overwrites fstab that comes with bad evil pointlessly restrictive
# (for my purposes) permissions defaults with defaults we actually want;
# RE: https://superuser.com/a/392598/130772 :
cp ./CYGWIN_fstab /etc/fstab

# DESTROY . . . okay, just rename . . . the utils I use a lot but adopt in _ebSuperBin from MSYS2, but which here cause problems; this first rename is funny because not finding it is exactly what will happen:
mv /usr/bin/find.exe /usr/bin/no-find.exe
mv /usr/bin/sed.exe /usr/bin/no-sed.exe
mv /usr/bin/sort.exe /usr/bin/no-sort.exe
# "You are all unique, you are all different!"
mv /usr/bin/uniq.exe /usr/bin/no-uniq.exe
# "...I'm not."