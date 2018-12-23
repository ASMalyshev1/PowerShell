wget.exe -c http://www.vpnbook.com/freevpn -O freevpn.txt --tries=1
for /f "Tokens=5 delims=></" %%a in ('findstr /i "password" freevpn.txt') do set Password=%%a
del /q freevpn.txt
echo | set /p="%Password%"> VPNBookPass.txt
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
echo /interface pptp-client add name="vpnbook" max-mtu=1400 max-mru=1400 mrru=disabled connect-to=euro217.vpnbook.com user="vpnbook" password="%password%" profile=vpnbook add-default-route=no dial-on-demand=no allow=mschap2 disabled=no>> VPNBook.rsc
echo.>> VPNBook.rsc
echo /ip firewall nat>> VPNBook.rsc
echo add chain=srcnat action=masquerade out-interface=vpnbook>> VPNBook.rsc
echo.>> VPNBook.rsc
echo /ip firewall mangle>> VPNBook.rsc
echo add chain=prerouting action=mark-routing new-routing-mark=BlackList passthrough=yes \>> VPNBook.rsc
echo dst-address-list=BlackList>> VPNBook.rsc
echo.>> VPNBook.rsc
echo /ip route>> VPNBook.rsc
echo add disabled=no distance=1 dst-address=0.0.0.0/0 gateway=vpnbook \>> VPNBook.rsc
echo routing-mark=BlackList scope=30 target-scope=10>> VPNBook.rsc
echo.>> VPNBook.rsc
echo ## Import BlackList.rsc >> VPNBook.rsc
echo.>> VPNBook.rsc
echo /tool fetch mode=http url=http://www.asmalyshev.ru/MikroTik/VPNBook/BlackList.rsc dst-path=BlackList.rsc;>> VPNBook.rsc
echo /import file-name=BlackList.rsc;>> VPNBook.rsc
echo :delay 1s;>> VPNBook.rsc
echo /file remove BlackList.rsc;>> VPNBook.rsc
echo.>> VPNBook.rsc
echo ## Create Script VPNBookPass >> VPNBook.rsc
echo.>> VPNBook.rsc
echo :if ([:len [/system script find name="VPNBookPass"]] ^> 0) do={/system script remove VPNBookPass};>> VPNBook.rsc
echo | set /p="/system script add name=VPNBookPass policy=read,write,policy,test source= {">> VPNBook.rsc
echo :local interface "vpnbook";>> VPNBook.rsc
echo :local FilePassName "VPNBookPass.txt";>> VPNBook.rsc
echo :local FileBlackListName "BlackList.rsc";>> VPNBook.rsc
echo :local PassNameUrl "http://www.asmalyshev.ru/MikroTik/VPNBook/$FilePassName";>> VPNBook.rsc
echo :local BlackListNameUrl "http://www.asmalyshev.ru/MikroTik/VPNBook/$FileBlackListName";>> VPNBook.rsc
echo. >> VPNBook.rsc 
echo :if ([/interface pptp-client get $interface running] = false) do={>> VPNBook.rsc
echo 		/tool fetch mode=http url=$PassNameUrl dst-path=$FilePassName;>> VPNBook.rsc
echo 		/tool fetch mode=http url=$BlackListNameUrl dst-path=$FileBlackListName;>> VPNBook.rsc
echo 		/import file-name=$FileBlackListName;>> VPNBook.rsc
echo 		:delay 1s;>> VPNBook.rsc
echo 		:local VPNPassword [/file get $FilePassName contents];>> VPNBook.rsc
echo 		/interface pptp-client set  vpnbook password=$VPNPassword;>> VPNBook.rsc
echo 		:delay 1s;>> VPNBook.rsc
echo 		/file remove $FilePassName;>> VPNBook.rsc
echo 		/file remove $FileBlackListName;>> VPNBook.rsc
echo | set /p="};">> VPNBook.rsc
echo }>> VPNBook.rsc
echo :if ([:len [/system scheduler find name="VPNBookPass"]] ^> 0) do={/system scheduler remove VPNBookPass};>> VPNBook.rsc
echo /system scheduler add name=VPNBookPass on-event="/system script run VPNBookPass" interval=5m policy=read,write,policy,test>> VPNBook.rsc
echo.>> VPNBook.rsc
echo ## Create Script VPNBook >> VPNBook.rsc
echo.>> VPNBook.rsc
echo :if ([:len [/system script find name="VPNBook"]] ^> 0) do={/system script remove VPNBook};>> VPNBook.rsc
echo | set /p="/system script add name=VPNBook policy=read,write,policy,test source= {">> VPNBook.rsc
echo :local FileName "VPNBook.rsc";>> VPNBook.rsc
echo :local FileBlackListName "BlackList.rsc";>> VPNBook.rsc
echo :local NameUrl "http://www.asmalyshev.ru/MikroTik/VPNBook/$FileName";>> VPNBook.rsc
echo :local BlackListNameUrl "http://www.asmalyshev.ru/MikroTik/VPNBook/$FileBlackListName";>> VPNBook.rsc
echo. >> VPNBook.rsc 
echo 		/tool fetch mode=http url=$NameUrl dst-path=$FileName;>> VPNBook.rsc
echo 		/tool fetch mode=http url=$BlackListNameUrl dst-path=$FileBlackListName;>> VPNBook.rsc
echo 		/import file-name=$FileName;>> VPNBook.rsc
echo 		/import file-name=$FileBlackListName;>> VPNBook.rsc
echo 		:delay 1s;>> VPNBook.rsc
echo 		/file remove $FileName;>> VPNBook.rsc
echo 		/file remove $FileBlackListName;>> VPNBook.rsc
echo | set /p="};">> VPNBook.rsc
echo :if ([:len [/system scheduler find name="VPNBook"]] ^> 0) do={/system scheduler remove VPNBook};>> VPNBook.rsc
echo /system scheduler add name=VPNBook on-event="/system script run VPNBook" start-time=03:00:00 interval=1d policy=read,write,policy,test>> VPNBook.rsc
::
ncftpput -u magakbru_asmalyshev -p 0Cm24ae1 -P 21 77.222.61.167 /public_html/MikroTik/VPNBook VPNBook.rsc
ncftpput -u magakbru_asmalyshev -p 0Cm24ae1 -P 21 77.222.61.167 /public_html/MikroTik/VPNBook BlackList.rsc
ncftpput -u magakbru_asmalyshev -p 0Cm24ae1 -P 21 77.222.61.167 /public_html/MikroTik/VPNBook VPNBookPass.txt
del /q VPNBookPass.txt
::del /q VPNBook.rsc