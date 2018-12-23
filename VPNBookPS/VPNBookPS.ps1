Clear-Host
Set-Location $PSScriptRoot

$IW = Invoke-WebRequest -Uri 'http://www.vpnbook.com/freevpn' -Method Get
# VPNBookPass
Invoke-WebRequest -Uri 'https://twitter.com/vpnbook/' -Method Get -OutFile .\twitter.tmp
$twitter = (Select-String -path .\twitter.tmp  -Pattern "VPN password updated").Line|Select-Object -First 1
$VPNBookPass = ($twitter -split "Password: " -replace "</p>"|Select-Object -Last 1).trim()
#
#$VPNBookPass=(((($IW.ToString()).split(13).trim(10)|Select-String -Pattern "Password").Line|Select-Object -First 1).trim() -split ">") -split "<"|Select-Object -First 1 -Skip 4
$VPNBookSrvArray=((($IW.ToString()).split(13).trim(10)|Select-String -Pattern "<li><strong>").Line).Trim()|foreach {($_ -replace "<li><strong>").remove($($_ -replace "<li><strong>").IndexOf("<"))}|Sort-Object
$VPNBookPass|Out-File -FilePath .\VPNBookPass.txt -Encoding utf8 -Force
$VPNBookSrvArray|Out-File -FilePath .\VPNBookSrvArray.txt -Encoding utf8 -Force
$VPNBookSrv = $VPNBookSrvArray|Select-Object -First 1

Function Get-ImageText()
{
[CmdletBinding()]
Param(
        [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$True)]
		[String] $Path
)

Process{
            $SplatInput = @{
            Uri= "https://api.projectoxford.ai/vision/v1/ocr"
            Method = 'Post'
			InFile = $Path
			ContentType = 'application/octet-stream'
			}

            $Headers =  @{
			'Ocp-Apim-Subscription-Key' = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
			}

            Try{
            			# Call OCR API and feed the parameters to it.
				$Data = (Invoke-RestMethod @SplatInput -Headers $Headers -ErrorVariable +E)
				$Language = $Data.Language # Detected language
				$i=0; foreach($D in $Data.regions.lines){
				$i=$i+1;$s=''; 
				''|select @{n='LineNumber';e={$i}},@{n='LanguageCode';e={$Language}},@{n='Sentence';e={$D.words.text |%{$s=$s+"$_ "};$s}}}

            }
            Catch{
                "Something went wrong While extracting Text from Image, please try running the script again`nError Message : "+$E.Message
            }
    }
}
Function Translate-text()
{
[CmdletBinding()]
Param(
        [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$True)]
		[String] $Text,
        [String] [validateSet('Arabic','Hindi','Japanese','Russian','Spanish','French',`
        'English','Korean','Urdu','Italian','Portuguese','German','Chinese Simplified')
        ]$From,
        [String] [validateSet('Arabic','Hindi','Japanese','Russian','Spanish','French',`
        'English','Korean','Urdu','Italian','Portuguese','German','Chinese Simplified')
        ]$To
)
	Begin{
					# Language codes hastable
					$LangCodes = @{'Arabic'='ar'
					'Chinese Simplified'='zh-CHS'
					'English'='en'
					'French'='fr'
					'German'='de'
					'Hindi'='hi'
					'Italian'='it'
					'Japanese'='ja'
					'Korean'='ko'
					'Portuguese'='pt'
					'Russian'='ru'
					'Spanish'='es'
					'Urdu'='ur'
					}
					
					# Secret Client ID and Key you get after Subscription	
					$ClientID = 'XXXXXXXXXXXXXXXXXXXX'
					$client_Secret = ‘XXXXXXXXXXXXXXXXXXXX'
					
					# If ClientId or Client_Secret has special characters, UrlEncode before sending request
					$clientIDEncoded = [System.Web.HttpUtility]::UrlEncode($ClientID)
					$client_SecretEncoded = [System.Web.HttpUtility]::UrlEncode($client_Secret) 
	}
	Process{
				ForEach($T in $Text)
				{	
					Try{
							# Azure Data Market URL which provide access tokens
							$URI = "https://datamarket.accesscontrol.windows.net/v2/OAuth2-13"
							
							# Body and Content Type of the request
							$Body = "grant_type=client_credentials&client_id=$clientIDEncoded&client_secret=$client_SecretEncoded&scope=http://api.microsofttranslator.com"
							$ContentType = "application/x-www-form-urlencoded"
							# Invoke REST method to Azure URI 
							$Access_Token=Invoke-RestMethod -Uri $Uri -Body $Body -ContentType $ContentType -Method Post
							
							# Header value with the access_token just recieved
							$Header = "Bearer " + $Access_Token.access_token
							
							# Invoke REST request to Microsoft Translator Service
							[string] $EncodedText = [System.Web.HttpUtility]::UrlEncode($T)
							[string] $uri = "http://api.microsofttranslator.com/v2/Http.svc/Translate?text=" + $EncodedText + "&from=" + $LangCodes.Item($From) + "&to=" + $LangCodes.Item($To);
					
							$Result = Invoke-RestMethod -Uri $URI -Headers @{Authorization = $Header} -ErrorVariable Error
							Return $Result.string.'#text'
					}
					catch
					{
							"Something went wrong While Translating Text, please try running the script again`nError Message : "+$Error.Message	
					}
				}
	}

}

#<# MIKROTIK
@"
## Install Script AntiBlockSites
##
## /tool fetch mode=http url=http://www.asmalyshev.ru/MikroTik/VPNBook/VPNBook.rsc dst-path=VPNBook.rsc;
## /import file-name=VPNBook.rsc

:if ([:len [/ip firewall nat find out-interface="vpnbook" action="masquerade"]] > 0) do={/ip firewall nat remove [/ip firewall nat find out-interface="vpnbook" action="masquerade"]};
:if ([:len [/ip firewall mangle find new-routing-mark="BlackList"]] > 0) do={/ip firewall mangle remove [/ip firewall mangle find new-routing-mark="BlackList"]};
:if ([:len [/ip route find routing-mark="BlackList"]] > 0) do={/ip route remove [/ip route find routing-mark="BlackList"]};
:if ([:len [/interface pptp-client find name="vpnbook"]] > 0) do={/interface pptp-client remove [/interface pptp-client find name="vpnbook"]};
:if ([:len [/ppp profile find name="vpnbook"]] > 0) do={/ppp profile remove [/ppp profile find name="vpnbook"]};
/ppp profile add name="vpnbook" change-tcp-mss=yes use-encryption=yes;
/interface pptp-client add name="vpnbook" max-mtu=1400 max-mru=1400 mrru=disabled connect-to=$VPNBookSrv user="vpnbook" password=$VPNBookPass profile=vpnbook add-default-route=no dial-on-demand=no allow=mschap2 disabled=no
"@.Split(13).Trim(10)|Out-File -FilePath .\VPNBook.rsc -Encoding default -Force
@'
## Import BlackList.rsc

/tool fetch mode=http url=http://www.asmalyshev.ru/MikroTik/VPNBook/BlackList.rsc dst-path=BlackList.rsc;
/import file-name=BlackList.rsc;
:delay 1s;
:if ([:len [/file find name="BlackList.rsc"]] > 0) do={/file remove BlackList.rsc};

/ip firewall nat
add chain=srcnat action=masquerade out-interface=vpnbook

/ip firewall mangle
add chain=prerouting action=mark-routing new-routing-mark=BlackList passthrough=no \
dst-address-list=BlackList

/ip route
add disabled=no distance=1 dst-address=0.0.0.0/0 gateway=vpnbook \
routing-mark=BlackList scope=30 target-scope=10

## Create Script VPNBookPass 

:if ([:len [/system script find name="VPNBookPass"]] > 0) do={/system script remove VPNBookPass};
/system script add name=VPNBookPass policy=read,write,policy,test source= {
:local interface "vpnbook";
:local FilePassName "VPNBookPass.txt";
:local FileSrvName "VPNBookSrvArray.txt";
:local FileBlackListName "BlackList.rsc";
:local PassNameUrl "http://www.asmalyshev.ru/MikroTik/VPNBook/$FilePassName";
:local PassSrvUrl "http://www.asmalyshev.ru/MikroTik/VPNBook/$FileSrvName";
:local BlackListNameUrl "http://www.asmalyshev.ru/MikroTik/VPNBook/$FileBlackListName";
 
:if ([/interface pptp-client get $interface running] = false) do={
		/tool fetch mode=http url=$PassNameUrl dst-path=$FilePassName;
		/tool fetch mode=http url=$BlackListNameUrl dst-path=$FileBlackListName;
		/tool fetch mode=http url=$PassSrvUrl dst-path=$FileSrvName;
		/import file-name=$FileBlackListName;
		:delay 1s;
		:local VPNPassword [/file get $FilePassName contents];
		:local SrvArray [/file get $FileSrvName contents];
		:local HostsSrv [:toarray "$SrvArray"];
			:foreach x in=$HostsSrv do={
			:if ([/interface pptp-client get $interface running] = false) do={
			/interface pptp-client set vpnbook connect-to=$x password=$VPNPassword;
			:delay 10s;};};
		:if ([:len [/file find name="$FilePassName"]] > 0) do={/file remove $FilePassName};
		:if ([:len [/file find name="$FileSrvName"]] > 0) do={/file remove $FileSrvName};
		:if ([:len [/file find name="$FileBlackListName"]] > 0) do={/file remove $FileBlackListName};
};}
:if ([:len [/system scheduler find name="VPNBookPass"]] > 0) do={/system scheduler remove VPNBookPass};
/system scheduler add name=VPNBookPass on-event="/system script run VPNBookPass" interval=5m policy=read,write,policy,test

## Create Script VPNBook 

:if ([:len [/system script find name="VPNBook"]] > 0) do={/system script remove VPNBook};
/system script add name=VPNBook policy=read,write,policy,test source= {
# /tool fetch mode=http url=http://www.asmalyshev.ru/MikroTik/VPNBook/VPNBook.rsc dst-path=VPNBook.rsc;
# /import file-name=VPNBook.rsc;

:local FileName "VPNBook.rsc";
:local NameUrl "http://www.asmalyshev.ru/MikroTik/VPNBook/$FileName";
  
		/tool fetch mode=http url=$NameUrl dst-path=$FileName;
		/import file-name=$FileName;
		:delay 1s;
		:if ([:len [/file find name="/$FileName"]] > 0) do={/file remove $FileName};
};}
:if ([:len [/system scheduler find name="VPNBook"]] > 0) do={/system scheduler remove VPNBook};
/system scheduler add name=VPNBook on-event="/system script run VPNBook" start-time=03:00:00 interval=1d policy=read,write,policy,test
'@.Split(13).Trim(10)|Out-File -FilePath .\VPNBook.rsc -Encoding default -Force -Append

# BlackList
"/ip firewall address-list remove [/ip firewall address-list find list=BlackList]"|Out-File -FilePath .\BlackList.rsc -Encoding default -Force
Function BlackList {
Param(
$DnsName = "Kinozal.tv"
)
[Net.DNS]::GetHostEntry($DnsName).AddressList.IPAddressToString|Select-Object @{Name="Name"; Expression={$DnsName}}, @{Name="IPAddress"; Expression={$_}}
}
[Array]$BlackList=@()
$DnsNameHosts = @"
telegram.org
api.telegram.org
Kinozal.tv
Kinozal.me
rutracker.org
nnm-club.ws
nnm-club.me
"@.Split(13).Trim(10)
$BlackList += $DnsNameHosts|foreach{BlackList -DnsName $_}
$BlackList = $BlackList|Sort-Object -Property IPAddress -Unique
$BlackList|foreach{"/ip firewall address-list add list=BlackList address=$($_.IPAddress) comment=$($_.Name)"}|Out-File -FilePath .\BlackList.rsc -Encoding default -Force -Append
#
# Send Config for MIKROTIK to FTP
@"
VPNBook.rsc
BlackList.rsc
VPNBookPass.txt
VPNBookSrvArray.txt
"@.Split(13).Trim(10)|foreach {
& ncftpput -u magakbru_asmalyshev -p 0Cm24ae1 -P 21 77.222.61.167 /public_html/MikroTik/VPNBook $_
Remove-Item .\$_ -Force
}