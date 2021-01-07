<#
.Synopsis
   Prepare config file and call office installation using ODT setup
.DESCRIPTION
   Prepare config file and call office installation using ODT setup
.EXAMPLE
   .\Install-Office.ps1 -$ConfigFile 'Config32.xml' -DownloadTo '\\Server\Share'
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
#region initialization

param (
    [parameter(Mandatory=$true)]
    [string]$ConfigFile,
    [parameter(Mandatory=$true)]
    [string]$DownloadTo
 )
$DownloadTo = "\\W2012R2-T1\Software"
[xml]$xmlConfig = Get-Content -Path $ConfigFile
$xmlConfig.Configuration.Add.SourcePath = $DownloadTo
$xmlConfig.Save($ConfigFile)
& .\install.cmd