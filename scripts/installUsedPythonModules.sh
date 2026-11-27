# DESCRIPTION
# Installs all the Python modules I commonly use.

# USAGE
# Run without any parameter:
#    installUsedPythonModules.sh

# CODE
python -m pip install --upgrade pip

# alphabetic list of used packages:
pythonModules=(
argparse
cairosvg
ciecam02
coloraide
coloraide_extras
colorgram.py
colormap
colorspacious
colour-science
customtkinter
dotenv
easydev
extended_configparser
faker
Foundation
gibberish
global_hotkeys
more_itertools
numpy
openpyxl
pathlib
pillow
pyautogui
pyfxr
pyobjc-core
pyobjc-framework-Quartz
pyodbc
PyQt6
pywin32
scikit-learn
scipy
scour
screeninfo
spectra
spotipy
truststore
)

# possible future-use modules:
# matplotlib

# PACKAGE NOTES:
# - colour-science is installed as colour-science, but imported as colour: https://github.com/colour-science/colour#installation -- https://github.com/colour-science/colour#54examples. To add to confusion, there may be another separate package named colour, which imports as Color (but not colour?) re: https://github.com/vaab/colour
# - Pillow is a maintained fork of PIL and imports as name PIL.
# - Quartz may be a Mac-exclusive package, and you should (maybe?) expect to see install of it error out on Windows.
# - pyobjc-framework-Quartz or pyobjc may be wanted in that case instead, re: https://stackoverflow.com/questions/50948134/modulenotfounderror-no-module-named-quartz

# Uncomment whichever applies to your python version:
# pipExeName=pip
pipExeName=pip

for element in ${pythonModules[@]}
do
	echo "----------------------------------------------------"
	echo "Attempting to install $element via $pipExeName . . ."
	# pipe yes command to bypass yes prompt:
	yes | $pipExeName install $element
done