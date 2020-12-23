<#
.Synopsis
   Reset services to fix Windows Update issues.
.DESCRIPTION
   Reset services to fix Windows Update issues. REsets services' parameters and registry keys
.EXAMPLE
   .\Reset-WUClient.ps1
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>

function Register-Library {
<#
.SYNOPSIS
Register a file using regsvr32.exe
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
    [ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
    [string]$FilePath
)
    try {
        $Result = Start-Process -FilePath 'regsvr32.exe' -Args "/s $FilePath" -Wait -NoNewWindow -PassThru
	} catch {
        Write-Error $_.Exception.Message $false
	}
}

#region Init
[string]$RegKeyPath = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate'
[string[]]$RegValues = @('AccountDomainSid', 'PingID', 'SusClientId', 'SusClientIDValidation')
[string[]]$ServiceNames = @('BITS', 'wuauserv', 'appidsvc', 'cryptsvc')
[string[]]$DLLs = @('atl.dll', 'urlmon.dll', 'mshtml.dll', 'shdocvw.dll', 'browseui.dll', 'jscript.dll', `
'vbscript.dll', 'scrrun.dll', 'msxml.dll', 'msxml3.dll', 'msxml6.dll', 'actxprxy.dll', 'softpub.dll', `
'wintrust.dll', 'dssenh.dll', 'rsaenh.dll', 'gpkcsp.dll', 'sccbase.dll', 'slbcsp.dll', 'cryptdlg.dll', `
'oleaut32.dll', 'ole32.dll', 'shell32.dll', 'initpki.dll', 'wuapi.dll', 'wuaueng.dll', 'wuaueng1.dll', `
'wucltui.dll', 'wups.dll', 'wups2.dll', 'wuweb.dll', 'qmgr.dll', 'qmgrprxy.dll', 'wucltux.dll', `
'muweb.dll', 'wuwebv.dll')
#endregion Init

#Stop services
$ServiceNames | ForEach-Object { Get-Service -Name $_ | Stop-Service }

#Remove all BITS jobs
Get-BitsTransfer -AllUsers | Remove-BitsTransfer

#Reset WinSock
netsh winsock reset
netsh winhttp reset proxy

#Rename existing Software Distribution & CatRoot2 folders
@('SoftwareDistribution', 'System32\Catroot2') | `
    ForEach-Object { $CurrentItem = $(Join-Path -Path $env:systemroot -ChildPath $_); `
    if(Test-Path -Path $CurrentItem) { Get-Item $CurrentItem | `
    Rename-Item -NewName "$(Split-Path $_ -Leaf).bak" `
    -ErrorAction SilentlyContinue }
}

#Remove Windows Update logs for older OS. Microsoft does not recomment remove logs for Windows 10, 2016 Server and newer
if([System.Environment]::OSVersion.Version.Major -lt 10)
{
    Remove-Item -Path "$env:systemroot\WindowsUpdate.log" -Force -ErrorAction SilentlyContinue
}

#Remove QMGR Data
Get-Item "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat" | Remove-Item -Force -ErrorAction SilentlyContinue

#Re-register DLLs
Set-Location $env:systemroot\system32
$DLLs | ForEach-Object { if (Test-Path -Path $_ -PathType 'Leaf') { Get-Item $_ | Register-Library } }

#Remove WSUS registry settings
$RegValues | ForEach-Object {
    $ValueName = $_
    $RegValue = $( try { Get-ItemProperty -Path Registry::$RegKeyPath -Name $ValueName -ErrorAction Stop} catch { $null })
    if ($null -ne $RegValue )
    {
        Remove-ItemProperty -Path Registry::$RegKeyPath -Name $ValueName -Force -ErrorAction SilentlyContinue
    }
}

#Reset settings for BITS & Windows Update Service
"sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
"sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"

#Start services
$ServiceNames | ForEach-Object { Get-Service -Name $_ | Start-Service }

#Force discovery
wuauclt.exe /resetauthorization /detectnow