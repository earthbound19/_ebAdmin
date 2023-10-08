# DESCRIPTION
# Performs administrative setup per my preferences for MacOS development etc.

# USAGE
# Examine every line and uncomment what you want, and comment out what you don't want. If you don't know what every line does, don't use this script. Then run this without any parameters:
#    macDevSetup.sh
# Then follow the prompt to really AKTULLY do things if you want (requires a password it tells you).
# NOTES
# If it's your preference, revert from newer MacOS Zsh shell to bash with this command:
#
#    chsh -s /bin/bash
#
# To go to Zsh again, run:
#
#    chsh -s /bin/zshcd


# CODE
echo ""
echo "WARNING: WARNING. Um, warning. If you want to run this script, type SNURFBLIM and then press ENTER or RETURN."
read -p "TYPE HERE: " SILLYWORD

if ! [ "$SILLYWORD" == "SNURFBLIM" ]
then
	echo ""
	echo Typing mismatch\; exit.
	exit
else
	echo continuing . .
fi


# pushd . >/dev/null
# NOPE: maybe asdf instead:
# install n node version manager; re: https://github.com/tj/n/issues/169
# cd ~
# curl -L https://git.io/n-install | bash
# TO UNINSTALL:
# ~/n/n-uninstall
# n latest
# popd >/dev/null

./install_global_node_modules.sh
./installUsedBrewPackages.sh

# Enable "Allow from Anywhere" in app gatekeeper on macOS Sierra (seriously, Apple, you are AWOL with your controls--I have to enable even the *option* to install apps from anywhere by entering a super-user terminal command?! Isn't that anti-competitive?), re: http://osxdaily.com/2016/09/27/allow-apps-from-anywhere-macos-gatekeeper/
# USE WITH CAUTION:
sudo spctl --master-disable
# to revert that: sudo spctl --master-enable
# DISABLES ALL app checking:
defaults write com.apple.LaunchServices LSQuarantine -bool NO
# TO ENABLE THAT AGAIN: end that with YES instead.
# re: https://appletoolbox.com/why-is-macos-catalina-verifying-applications-before-i-can-open-them/

# Enable cut-paste in Mac Finder (why would you *not* have that there by default, Apple?) :
defaults write com.apple.finder AllowCutForItems 1

# Enable show all files:
defaults write com.apple.finder AppleShowAllFiles YES

# Disable "HAY TEH APP CRASHED" dialogue--except I'm not sure it actually does--maybe after a reboot?
defaults write com.apple.CrashReporter DialogType none
# OR make it a slightly less annoying notification:
# defaults write com.apple.CrashReporter UseUNC 1


# OPTIONAL COMMANDS that castrate foistware which I don't use:
pushd . >/dev/null
cd ~/Applications
sudo chmod 000 ./Messages.app
sudo chmod 000 ./Mail.app
sudo chmod 000 ./Maps.app
sudo chmod 000 ./News.app
sudo chmod 000 ./Notes.app
# sudo chmod 000 ./Stickies.app
sudo chmod 000 ./Stocks.app
# sudo chmod 000 ./TextEdit.app
popd >/dev/null

# homebrew sbin:
printf '
export PATH="/usr/local/sbin:$PATH"
' >> ~/.bash_profile

printf "" >> ~/.bash_profile
printf "# Reduces homebrew auto-update on _every flipping install of anything_ annoyance:" >> ~/.bash_profile
printf "export HOMEBREW_NO_AUTO_UPDATE=1" >> ~/.bash_profile
printf "export BASH_SILENCE_DEPRECATION_WARNING=1" >> ~/.bash_profile

printf '

# openimageIO:
export DYLD_LIBRARY_PATH="${OCIO_EXECROOT}/lib:${DYLD_LIBRARY_PATH}"

# Put GNU coreutils from brew in path before other Mac tools of the same name; re https://formulae.brew.sh/formula/coreutils :
PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"
PATH=$(brew --prefix)/opt/findutils/libexec/gnubin:$PATH
PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"

' >> ~/.bash_profile

# see: pyenvFrameworkInstallMac.sh
# tcl-tk for python idle? :
# # for python idle in pyenv:
# export LDFLAGS="-L/usr/local/opt/tcl-tk/lib"
# export CPPFLAGS="-I/usr/local/opt/tcl-tk/include"
# export PATH=$PATH:/usr/local/opt/tcl-tk/bin
# Then launch IDLE interactive shell with:
# pyenv-idle.py
# -- although just:
# idle
# -- may work!

# NOTE: ntfs-3g location: /usr/local/Cellar/ntfs-3g/2017.3.23

# Possible additional commands to setup asdf:
# git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.6.0
# echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bash_profile
# asdf plugin-add nodejs
# asdf install nodejs 10.13.0
# asdf global nodejs 10.13.0
# xcode-select --install
# RE: https://github.com/pyenv/pyenv/issues/1219 :
# sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
# /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
# git config user.email "earthbound19@users.noreply.github.com"
# git credential-osxkeychain 
# git config --global credential.helper osxkeychain
# curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash


# REFERENCE FOR OTHER TOOLS
# date format "Phrase content" for PhraseExpress text expander for mac, for hotkey/sequence to type full date and time:
#     {#datetime -f yyyy.mm.dd dddd t am/pm}

# command for Atom open-terminal-here package on Mac (requires ttab to be installed) which allows opening any path to terminal by shortcut:
# ttab && cd "$PWD"

# path change notes:
# see: https://coolestguidesontheplanet.com/add-shell-path-osx/
# 
# and / or http://hathaway.cc/post/69201163472/how-to-edit-your-path-environment-variables-on-mac

# DISABLE blasted dysfunctional IPv6.
# To list the network servics, run: networksetup -listallnetworkservices
# To re-enable, use -setv6automatic instead of -setv6off
# networksetup -setv6off "USB 10/100/1000 LAN"
# networksetup -setv6off Wi-Fi