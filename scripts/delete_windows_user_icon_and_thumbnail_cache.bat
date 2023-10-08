: DESCRIPTION
: Whereas the windows picture thumbnail and icon cache can get corrupt and thumbnails of some pictures stubbornly refuse to get recreated even after many cleanup tools "clear" the cache, it can only really be cleared with Explorer terminated. This script terminates explorer, deletes the user cache files, and restarts explorer. You may need to run it as Administrator.

: USAGE
: Run as Administrator.

: CODE
tasskill /f /im explorer.exe
cd /d %userprofile%\AppData\Local\Microsoft\Windows\Explorer 
attrib –h 
thumbcache_*.db 
del thumbcache_*.db 
start explorer