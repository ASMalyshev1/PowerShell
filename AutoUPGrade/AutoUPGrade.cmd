cd /d "D:\Scripts\AutoUPGrade"
::
:: MIKROTIK
echo ## Install Script AutoUPGrade> AutoUPGrade.rsc
echo. >> AutoUPGrade.rsc
echo ## Create Script AutoUPGrade >> AutoUPGrade.rsc
echo.>> AutoUPGrade.rsc
echo :if ([:len [/system script find name="AutoUPGrade"]] ^> 0) do={/system script remove AutoUPGrade};>> AutoUPGrade.rsc
echo | set /p="/system script add name=AutoUPGrade policy=read,write,policy,test source= {">> AutoUPGrade.rsc
echo # /tool fetch mode=http url=http://www.asmalyshev.ru/MikroTik/AutoUPGrade/AutoUPGrade.rsc dst-path=AutoUPGrade.rsc;>> AutoUPGrade.rsc
echo # /import file-name=AutoUPGrade.rsc;>> AutoUPGrade.rsc
echo.>> AutoUPGrade.rsc
echo /system package update>> AutoUPGrade.rsc
echo set channel=stable>> AutoUPGrade.rsc
echo check-for-updates once>> AutoUPGrade.rsc
echo :delay 1s;>> AutoUPGrade.rsc
echo :if ( [get status] = "New version is available") do={ install }>> AutoUPGrade.rsc
echo };>> AutoUPGrade.rsc
echo :if ([:len [/system scheduler find name="AutoUPGrade"]] ^> 0) do={/system scheduler remove AutoUPGrade};>> AutoUPGrade.rsc
echo /system scheduler add name=AutoUPGrade on-event="/system script run AutoUPGrade" start-time=01:00:00 interval=1d policy=read,write,policy,test>> AutoUPGrade.rsc
echo /file remove AutoUPGrade.rsc;>> AutoUPGrade.rsc
::
ncftpput -u magakbru_asmalyshev -p 0Cm24ae1 -P 21 77.222.61.167 /public_html/MikroTik/AutoUPGrade AutoUPGrade.rsc
del /q AutoUPGrade.rsc