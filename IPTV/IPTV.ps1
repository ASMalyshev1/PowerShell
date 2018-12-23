Clear-Host
Set-Location $PSScriptRoot

#http://www.asmalyshev.ru/IPTV/iptv.m3u

#http://iptvsensei.ru/samoobnovlyayemyye-pleylisty-iptv/

#Invoke-WebRequest -Uri https://sites.google.com/site/iptvblogspot/rus.m3u -Method Get -OutFile .\iptv.m3u
Function CreateIPTVList {
Param(
[Array]$Url = "https://getsapp.ru/IPTV/04.18.m3u"
)
'#EXTM3U'|Out-File -FilePath .\iptv.m3u -Encoding utf8 -Force
[Array]$IPTV=@()
[Array]$IPTVTable=@()
$Url|foreach {
Invoke-WebRequest -Uri $_ -Method Get -OutFile .\iptvlist.m3u
#Invoke-WebRequest -Uri $Url[0] -Method Get -OutFile .\iptvlist.m3u
[Array]$GC = Get-Content -Path .\iptvlist.m3u -Encoding UTF8
$Line = (Select-String -Path .\iptvlist.m3u -Pattern "EXTINF:").LineNumber
$StartLine = ($Line |Select-Object -First 1) - 1
$EndLine = ($Line |Select-Object -Last 1) - 1

    for ($i = $StartLine; $i -le $EndLine;$i=$i+2){
    $IPTV+=""|Select-Object @{Name="Prefix"; Expression={($GC[$i] -split ","|Select-Object -First 1) + ","}}, @{Name="Name"; Expression={$GC[$i] -split ","|Select-Object -Last 1}}, @{Name="Url"; Expression={$GC[$i + 1]}}
    }
}

$IPTVTable += $IPTV|Where-Object {!($_.url -eq "http://listiptv.ru" -or $_.url -eq "http://j.mp/1FwLpEb?.m3u8" -or $_.name -like "*(18+)*" -or $_.name -like "*Украина*" -or $_.name -like "*UA*" -or $_.name -like "*(KZ)*" -or $_.url -eq "")}
$IPTVTable = $IPTVTable|Where-Object {$_.name -like "* HD*"}
$IPTVTable = $IPTVTable|Sort-Object -Property name -Unique

For ($i = 0; $i -lt $IPTVTable.count;$i++){
$IPTVTable[$i].Prefix + $IPTVTable[$i].Name|Out-File -FilePath .\iptv.m3u -Encoding utf8 -Force -Append
$IPTVTable[$i].Url|Out-File -FilePath .\iptv.m3u -Encoding utf8 -Force -Append
}

Start-Process -Wait .\ncftpput.exe -ArgumentList "-u","magakbru_asmalyshev","-p","0Cm24ae1","-P","21 77.222.61.167","/public_html/IPTV", ".\iptv.m3u" -NoNewWindow

#Remove-Item .\iptvlist.m3u -Force
#Remove-Item .\iptv.m3u -Force
}

$PlayList = @"
https://smarttvnews.ru/apps/iptvchannels.m3u
http://iptv.servzp.pp.ua/pl/lanta/day/37.235.156.50.m3u
http://iptv.slynet.tv/FreeSlyNet.m3u
http://iptv.slynet.tv/FreeBestTV.m3u
http://iptv.slynet.tv/PeerstvSlyNet.m3u
http://listiptv.ru/iptv18.m3u
https://getsapp.ru/IPTV/04.18.m3u
"@.Split(13).Trim(10)

CreateIPTVList -Url $PlayList
CreateIPTVList -Url "https://getsapp.ru/IPTV/04.18.m3u"
<#
https://smarttvnews.ru/apps/iptvchannels.m3u
http://iptv.servzp.pp.ua/pl/lanta/day/37.235.156.50.m3u
http://iptv.slynet.tv/FreeSlyNet.m3u
http://iptv.slynet.tv/FreeBestTV.m3u
http://iptv.slynet.tv/PeerstvSlyNet.m3u
http://listiptv.ru/iptv18.m3u
#>