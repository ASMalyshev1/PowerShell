cd /d "D:\Scripts\VPNBook"
::
wget.exe -c http://www.vpnbook.com/freevpn -O freevpn.txt --tries=1
for /f "Tokens=5 delims=></" %%a in ('findstr /i "password" freevpn.txt') do set Password=%%a
echo | set /p="%Password%"> VPNBookPass.txt
IF EXIST vpnbooksrv.txt (del /q vpnbooksrv.txt)
for /f "Tokens=4 delims=></" %%a in ('findstr /i "strong" freevpn.txt ^| findstr /i "vpnbook.com" ^| sort') do echo %%a>>  vpnbooksrv.txt
IF EXIST vpnbooksrvnum.txt (del /q vpnbooksrvnum.txt)
IF EXIST VPNBookSrvArray.txt (del /q VPNBookSrvArray.txt)
for /f "Tokens=* delims=" %%a in ('findstr /i "vpnbook.com" vpnbooksrv.txt') do echo | set /p="%%a,">> VPNBookSrvArray.txt
IF EXIST vpnbooksrvnum.txt (del /q vpnbooksrvnum.txt)
for /f "Tokens=* delims=" %%a in ('findstr /i /n "vpnbook.com" vpnbooksrv.txt') do echo | set /p="%%a,">> vpnbooksrvnum.txt
for /f "Tokens=3 delims=:," %%a in ('findstr /i /n "1:" vpnbooksrvnum.txt') do set vpnbooksrv=%%a
del /q freevpn.txt
del /q vpnbooksrv.txt
del /q vpnbooksrvnum.txt
:: MIKROTIK
echo ## Install Script AntiBlockSites> VPNBook.rsc
echo ##>> VPNBook.rsc
echo ## /tool fetch mode=http url=http://www.asmalyshev.ru/MikroTik/VPNBook/VPNBook.rsc dst-path=VPNBook.rsc;>> VPNBook.rsc
echo ## /import file-name=VPNBook.rsc;>> VPNBook.rsc
echo. >> VPNBook.rsc
echo :if ([:len [/ip firewall nat find out-interface="vpnbook" action="masquerade"]] ^> 0) do={/ip firewall nat remove [/ip firewall nat find out-interface="vpnbook" action="masquerade"]};>> VPNBook.rsc
echo :if ([:len [/ip firewall mangle find new-routing-mark="BlackList"]] ^> 0) do={/ip firewall mangle remove [/ip firewall mangle find new-routing-mark="BlackList"]};>> VPNBook.rsc
echo :if ([:len [/ip route find routing-mark="BlackList"]] ^> 0) do={/ip route remove [/ip route find routing-mark="BlackList"]};>> VPNBook.rsc
echo :if ([:len [/interface pptp-client find name="vpnbook"]] ^> 0) do={/interface pptp-client remove [/interface pptp-client find name="vpnbook"]};>> VPNBook.rsc
echo :if ([:len [/ppp profile find name="vpnbook"]] ^> 0) do={/ppp profile remove [/ppp profile find name="vpnbook"]};>> VPNBook.rsc
echo /ppp profile add name="vpnbook" change-tcp-mss=yes use-encryption=yes;>> VPNBook.rsc
echo /interface pptp-client add name="vpnbook" max-mtu=1400 max-mru=1400 mrru=disabled connect-to=%vpnbooksrv% user="vpnbook" password="%password%" profile=vpnbook add-default-route=no dial-on-demand=no allow=mschap2 disabled=no>> VPNBook.rsc
echo.>> VPNBook.rsc
echo ## Import BlackList.rsc >> VPNBook.rsc
echo.>> VPNBook.rsc
echo /tool fetch mode=http url=http://www.asmalyshev.ru/MikroTik/VPNBook/BlackList.rsc dst-path=BlackList.rsc;>> VPNBook.rsc
echo /import file-name=BlackList.rsc;>> VPNBook.rsc
echo :delay 1s;>> VPNBook.rsc
echo :if ([:len [/file find name="BlackList.rsc"]] ^> 0) do={/file remove BlackList.rsc};>> VPNBook.rsc
echo.>> VPNBook.rsc
echo /ip firewall nat>> VPNBook.rsc
echo add chain=srcnat action=masquerade out-interface=vpnbook>> VPNBook.rsc
echo.>> VPNBook.rsc
echo /ip firewall mangle>> VPNBook.rsc
echo add chain=prerouting action=mark-routing new-routing-mark=BlackList passthrough=no \>> VPNBook.rsc
echo dst-address-list=BlackList>> VPNBook.rsc
echo.>> VPNBook.rsc
echo /ip route>> VPNBook.rsc
echo add disabled=no distance=1 dst-address=0.0.0.0/0 gateway=vpnbook \>> VPNBook.rsc
echo routing-mark=BlackList scope=30 target-scope=10>> VPNBook.rsc
echo.>> VPNBook.rsc
echo ## Create Script VPNBookPass >> VPNBook.rsc
echo.>> VPNBook.rsc
echo :if ([:len [/system script find name="VPNBookPass"]] ^> 0) do={/system script remove VPNBookPass};>> VPNBook.rsc
echo | set /p="/system script add name=VPNBookPass policy=read,write,policy,test source= {">> VPNBook.rsc
echo :local interface "vpnbook";>> VPNBook.rsc
echo :local FilePassName "VPNBookPass.txt";>> VPNBook.rsc
echo :local FileSrvName "VPNBookSrvArray.txt";>> VPNBook.rsc
echo :local FileBlackListName "BlackList.rsc";>> VPNBook.rsc
echo :local PassNameUrl "http://www.asmalyshev.ru/MikroTik/VPNBook/$FilePassName";>> VPNBook.rsc
echo :local PassSrvUrl "http://www.asmalyshev.ru/MikroTik/VPNBook/$FileSrvName";>> VPNBook.rsc
echo :local BlackListNameUrl "http://www.asmalyshev.ru/MikroTik/VPNBook/$FileBlackListName";>> VPNBook.rsc
echo. >> VPNBook.rsc
echo :if ([/interface pptp-client get $interface running] = false) do={>> VPNBook.rsc
echo 		/tool fetch mode=http url=$PassNameUrl dst-path=$FilePassName;>> VPNBook.rsc
echo 		/tool fetch mode=http url=$BlackListNameUrl dst-path=$FileBlackListName;>> VPNBook.rsc
echo 		/tool fetch mode=http url=$PassSrvUrl dst-path=$FileSrvName;>> VPNBook.rsc
echo 		/import file-name=$FileBlackListName;>> VPNBook.rsc
echo 		:delay 1s;>> VPNBook.rsc
echo 		:local VPNPassword [/file get $FilePassName contents];>> VPNBook.rsc
echo 		:local SrvArray [/file get $FileSrvName contents];>> VPNBook.rsc
echo 		:local HostsSrv [:toarray "$SrvArray"];>> VPNBook.rsc
echo			:foreach x in=$HostsSrv do={>> VPNBook.rsc
echo 			:if ([/interface pptp-client get $interface running] = false) do={>> VPNBook.rsc
echo 			/interface pptp-client set vpnbook connect-to=$x password=$VPNPassword;>> VPNBook.rsc
echo 			:delay 10s;};};>> VPNBook.rsc
echo 		:if ([:len [/file find name="$FilePassName"]] ^> 0) do={/file remove $FilePassName};>> VPNBook.rsc
echo 		:if ([:len [/file find name="$FileSrvName"]] ^> 0) do={/file remove $FileSrvName};>> VPNBook.rsc
echo 		:if ([:len [/file find name="$FileBlackListName"]] ^> 0) do={/file remove $FileBlackListName};>> VPNBook.rsc
echo | set /p="};">> VPNBook.rsc
echo }>> VPNBook.rsc
echo :if ([:len [/system scheduler find name="VPNBookPass"]] ^> 0) do={/system scheduler remove VPNBookPass};>> VPNBook.rsc
echo /system scheduler add name=VPNBookPass on-event="/system script run VPNBookPass" interval=5m policy=read,write,policy,test>> VPNBook.rsc
echo.>> VPNBook.rsc
echo ## Create Script VPNBook >> VPNBook.rsc
echo.>> VPNBook.rsc
echo :if ([:len [/system script find name="VPNBook"]] ^> 0) do={/system script remove VPNBook};>> VPNBook.rsc
echo | set /p="/system script add name=VPNBook policy=read,write,policy,test source= {">> VPNBook.rsc
echo # /tool fetch mode=http url=http://www.asmalyshev.ru/MikroTik/VPNBook/VPNBook.rsc dst-path=VPNBook.rsc;>> VPNBook.rsc
echo # /import file-name=VPNBook.rsc;>> VPNBook.rsc
echo.>> VPNBook.rsc
echo :local FileName "VPNBook.rsc";>> VPNBook.rsc
echo :local NameUrl "http://www.asmalyshev.ru/MikroTik/VPNBook/$FileName";>> VPNBook.rsc
echo. >> VPNBook.rsc 
echo 		/tool fetch mode=http url=$NameUrl dst-path=$FileName;>> VPNBook.rsc
echo 		/import file-name=$FileName;>> VPNBook.rsc
echo 		:delay 1s;>> VPNBook.rsc
echo 		:if ([:len [/file find name="$FileName"]] ^> 0) do={/file remove $FileName};>> VPNBook.rsc
echo | set /p="};">> VPNBook.rsc
echo :if ([:len [/system scheduler find name="VPNBook"]] ^> 0) do={/system scheduler remove VPNBook};>> VPNBook.rsc
echo /system scheduler add name=VPNBook on-event="/system script run VPNBook" start-time=03:00:00 interval=1d policy=read,write,policy,test>> VPNBook.rsc
::
ncftpput -u magakbru_asmalyshev -p 0Cm24ae1 -P 21 77.222.61.167 /public_html/MikroTik/VPNBook VPNBook.rsc
ncftpput -u magakbru_asmalyshev -p 0Cm24ae1 -P 21 77.222.61.167 /public_html/MikroTik/VPNBook BlackList.rsc
ncftpput -u magakbru_asmalyshev -p 0Cm24ae1 -P 21 77.222.61.167 /public_html/MikroTik/VPNBook VPNBookPass.txt
ncftpput -u magakbru_asmalyshev -p 0Cm24ae1 -P 21 77.222.61.167 /public_html/MikroTik/VPNBook VPNBookSrvArray.txt
del /q VPNBook.rsc
del /q VPNBookPass.txt
del /q VPNBookSrvArray.txt