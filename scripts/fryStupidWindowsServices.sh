# DESCRIPTION
# Disables contemptible or useless Windows services. This script is very shotgun "blast everything I even slightly don't like," including things you might want to keep around.

# WARNING
# May break essential system functionality or services that programs rely on. Use at your own risk.

# USAGE
# - Read the NOTES comment.
# - Don't use this script unless you're very sure that no harm or unwanted operations will come to your operating system or programs if you use it. If you're sure of that, then: from a cmd prompt with administrative privileges, and with `paexec` in your path:
# - find and extract one NSUDO.bat / utility, e.g. https://nsudo.m2team.org/en-us/
# - run that batch to get that utility
# - point it to MSYS2 e.g. "C:\msys64\msys2_shell.cmd -msys"
# - From that MSYS2 super-elavated terminal, run this script (you may need to cd to the directory with it first) :
#    fryStupidWindowsServices.sh
# Possible alternate route to merely disable unwanted services:
# - run NSUDO.bat to get an NT/System Authority-priviledge prompt
# - run autoruns.exe (a utility that Microsoft bought from a developer) and
# - uncheck services you don't want to run, and anything else you don't want to run.
# OR from that NT/System Authority-privilege prompt run:
#    sc delete "service name"
# NOTES
# As of Aug. 2018 (or earlier), Windows malignantly re-enables windows update and the commands here that seek to disable that don't work--services that switch windows update back on cannot be disabled.
# re: https://answers.microsoft.com/en-us/windows/forum/windows_10-other_settings/windows-10-windows-update-keeps-turning-it-self
# However, if you find one NSUDO tool and run MSYS2 from it as TrustedInstaller with "Enable all Privileges," this script will disable those. You have to be a super-duper admin destroy user (as noted above) like that.
# Example service control commands:
#    sc config "AeLookupSvc" start= demand
#    sc config "NgcSvc" start= disabled

# CODE
rm -rf "C:\windows10update"

disableServices=(
NgcSvc
DoSvc
NgcCtnrSvc
Themes
LicenseManager
TabletInputService
tiledatamodelsvc
CscService
wuauserv
WaaSMedicSvc
wscsvc
WerSvc
SysMain
SwitchBoard
FontCache
ehRecvr
ehSched
WMPNetworkSvc
FontCache3.0.0.0
HomeGroupListener
HomeGroupProvider
WinDefend
AdobeUpdateService
IEEtwCollectorService
wlidsvc
CDPSvc
tiledatamodelsvc
tapi
TrkWks
wcncsvc
TrkWks
Dnscache
fdPHost
SharedAccess
GraphicsPerfSvc
edgeupdatem
SEMgrSvc
RasAuto
RasMan
SessionEnv
TermService
UmRdpService
RemoteRegistry
shpamsvc
SgrmBroker
MessagingService_339cb
PimIndexMaintenanceSvc_339cb
BcastDVRUserService_339cb
UdkUserSvc_339cb
UserDataSvc_339cb
UnistoreSvc_339cb
UevAgentService
WalletService
Sense
FontCache3.0.0.0
WinRM
SecurityHealthService
XboxGipSvc
XblAuthManager
XblGameSave
XboxNetApiSvc
AJRouter
gusvc
gupdate
gupdatem
dbupdate
dbupdatem
WatAdminSvc
osrss
UsoSvc
sedsvc
wisvc
nvUpdatusService
brave
bravem
embeddedmode
fhsvc
DiagTrack
RetailDemo
WerSvc
MozillaMaintenance
BITS
)

# previously listed:
# WSearch

for element in ${disableServices[@]}
do
	echo RUNNING COMMAND\:
	echo SC STOP $element
	SC STOP $element
	echo RUNNING COMMAND\:
	echo SC CONFIG $element start= disabled
	SC CONFIG $element start= disabled
done

onDemandServices=(
Fax
Mcx2Svc
StorSvc
WPCSvc
)

for element in ${onDemandServices[@]}
do
	echo RUNNING COMMAND\:
	echo SC STOP $element
	SC STOP $element
	echo RUNNING COMMAND\:
	echo SC CONFIG $element start= demand
	SC CONFIG $element start= demand
done

echo DONE. See also disable_per_user_services.reg.