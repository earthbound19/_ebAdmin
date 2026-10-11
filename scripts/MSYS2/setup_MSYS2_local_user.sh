#!/bin/bash
# DESCRIPTION
# Sets up local user configuration files and context menu for MSYS2.

# USAGE
# Run this script as a regular user, meaning without administrator privileges:
#    ./setup_MSYS2_local_user.sh
# What this sets up:
# - overwrites .bashrc and .minttyrc files in the current user's home directory, if they are present, with custom configs. See those files in the same directory as this script.
# - registers a context menu to open an MSYS2 bash terminal in the current (clicked) directory or folder.


# CODE
# Enforce non-admin privileges check; warn and throw if an admin:
net session >/dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "!----------------!"
	echo "ERROR: This script must not be run with Administrator privileges, because"
	echo "running as admin targets the Administrator profile for setup instead of"
	echo "your user setup. Restart MSYS2 as a regular non-admin user, and run this"
	echo "script again."
	echo "!----------------!"
	exit 1
fi

# Copy profile customizations into MSYS2 user root (~):
cp ./.bashrc ~
cp ./.minttyrc ~

# Import the right-click menu registry file using Windows cmd with path conversion
REG_FILE="install_MSYS2_right_click_menu.reg"
if [ -f "$REG_FILE" ]; then
	reg import install_MSYS2_right_click_menu.reg
	echo "Imported $REG_FILE successfully."
else
	echo "!----------------!"
	echo "PROBLEM: $REG_FILE not found in the current directory."
	echo "!----------------!"
fi

echo "USER SETUP DONE. If you have not already, you may wish to run the system MSYS2 setup (or configuration) via setup_MSYS2_local_system_and_packages.sh."
echo "You may also wish to install_MSYS2_ruby_right_click_menu.reg (by double-clicking it) if you need the Ruby menu as well."