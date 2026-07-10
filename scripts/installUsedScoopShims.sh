# DESCRIPTION
# Installs all the scoop packages / utilities / shims I commonly use.

# USAGE
# First run:
# From a PowerShell terminal:
#    installScoop.ps1
# Then from any regular terminal interfacing with windows cmd (MSYS2 bash / windows cmd) :
#    scoop bucket add main
#    scoop bucket add versions
# Then run this script without any parameter:
#    installUsedScoopShims.sh


# CODE
# NOTES
# - "main/clink" is useless as a scoop package unless you set it to autorun. See comments in clink_set_prefs.bat

scoopShims=(
"main/clink"
"ffmpeg-gyan-nightly"		# re https://www.gyan.dev/ffmpeg/builds/ and the recommendation at https://www.gyan.dev/ffmpeg/builds/#about-these-builds -- IF THAT THROWS a not found error try "versions/ffmpeg-gyan-nightly"
# "versions/ffmpeg-nightly"		# possible alternate for the above
ghostscript
"main/imagemagick"
"main/graphicsmagick"
"main/jq"
)

for element in ${scoopShims[@]}
do
	echo "----------------------------------------------------"
	echo "Attempting to install $element via scoop . . ."
	scoop install $element
done