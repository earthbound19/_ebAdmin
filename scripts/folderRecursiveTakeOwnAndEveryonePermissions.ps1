# DESCRIPTION
# Takes a folder name parameter, and recursively sets the current user (whatever account is logged in or running this command) as the owner. Also recursively grants full access to Everyone (for that folder and everything in it). This can resolve unexpected lockout from even opening files in situations where those permissions are a bug from overkill and go wrong (like a data drive with your files where the only security intended is your physical access to the drive -- and somehow something ended up giving read-only access to Administrators or System).

# DEPENDENCIES
# - You not screwing things up by using this in a situation it should not be used in
# - takeown

# USAGE
# With this script in your PATH, from a PowerShell with execute permissions that will allow this script, run it with these parameters:
# - REQUIRED. `-sourceFolderName <nameOfFolder>` -- name of folder to operate on.
# - OPTIONAL. `-password SNAULHORF` -- bypass prompt to verify you want to perform these operations on sourceFolderName. For it to work, the parameter to the switch must be that word: SNAULHORF. If you run this script without the `-password` parameter, or provide the wrong password, it will prompt you for the password.
# - OPTIONAL. `-log` -- switch. On completion, write completion event to .txt log based on `-sourceFolderName`.
# For example, to run it on a folder named testFiles, and be prompted for the password to verify you want to do this, run:
#    folderRecursiveTakeOwnAndEveryonePermissions.ps1 -sourceFolderName testFiles
# To do the same and provide the password to bypass the prompt, run:
#    folderRecursiveTakeOwnAndEveryonePermissions.ps1 -sourceFolderName testFiles -password SNAULHORF
# To do the same and add logging, run:
#    folderRecursiveTakeOwnAndEveryonePermissions.ps1 -sourceFolderName testFiles -password SNAULHORF -log
# If this script is not in your path, specify the full absolute path to it, then any parameters.


# CODE
Param(
	# required parameter to script: -sourceFolderName, which is the name of the folder to operate on:
	[Parameter(Mandatory=$True)]
    [string]$sourceFolderName,
	# optional named parameter to script: -password to bypass prompt to rlly to things:
    [string]$password,
	# optional named parameter to script: -log, which instructs to write operation completion log to text file based on sourceFolderName:
	[Switch]$log
    )

# check for existence of source folder; print notification and exit if it wasn't found.
if (-not(Test-Path -Path $sourceFolderName)) {
"
Whoops! The folder $sourceFolderName was not found. Exit.
"
	exit 1
}

# if it was not provided via paramater -password (or it was provided but is incorrect), prompt for a given password to do any operations; if what is typed does not match, exit.
if (-not($password -eq 'SNAULHORF'))
{
$password = Read-Host -Prompt "
NOTE: for the folder $sourceFolderName, this will recursively set the current user (whatever account is logged in or running this command) as the owner. It will also grant full access to Everyone, for that folder and everything in it. You may not want to do this in system folders. If you know what you are doing and accept this, enter the word SNAULHORF to continue
"
}

if ( $password -ne 'SNAULHORF' )
{
    Write-Output 'Typing mismatch. Exit.'
	exit 2
}

$logFileName = $sourceFolderName+"_permissions_change_log.txt"

# function to grant Everyone full control of a folder, passed as a string which is its name:
function Grant-Everyone-Full-Access {
    param (
		[string]$folder
    )
    # use get-item because some of the folders have '[' or ']' character and Powershell throws exception; try to do a get-acl or set-acl on them:
    $item = gi -literalpath $folder 
    $acl = $item.GetAccessControl() 
    $permission = "Everyone","FullControl","Allow"
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($rule)
    $item.SetAccessControl($acl)
}

# WIPE ACL of folder and everything in it; re: https://stackoverflow.com/a/12801923/1397555
# Reset the folder to just its inherited permissions
icacls $sourceFolderName /reset
# disable inheritance and remove all inherited permissions:
icacls $sourceFolderName /inheritance:r
# set current user as owner for the specified folder and everything in it:
takeown /R /D Y /F $sourceFolderName

# grant full access permission to Everyone for everything in the folder:
Grant-Everyone-Full-Access -folder $sourceFolderName
# Recursively grant full access permission to Everyone for everything in the folder:
$folders = gci $sourceFolderName -recurse | % {$_.FullName}
foreach($folder in $folders)
{
	Grant-Everyone-Full-Access -folder $folder
}

# Write completion event to log if parameter was passed asking to do so:
if ( $PSBoundParameters.ContainsKey('log') ) {
	Write-Output "LOG of folderRecursiveTakeOwnAndEveryonePermissions.ps1 : completed for folder $sourceFolderName" > $logFileName
}
