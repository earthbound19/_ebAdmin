# DESCRIPTION
# Installs all the Python modules I commonly use.

# USAGE
# Run without any parameter:
#    installUsedPythonModules.sh


# CODE
python -m pip install --upgrade pip

pythonModules=(
numpy
scipy
more_itertools
colorspacious
colour-science
spectra
ciecam02
colormap
colorgram.py
Quartz
Foundation
Pillow
easydev
scour
gibberish
faker
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
pipExeName=pip3

for element in ${pythonModules[@]}
do
	echo "----------------------------------------------------"
	echo "Attempting to install $element via $pipExeName . . ."
	$pipExeName install $element
done