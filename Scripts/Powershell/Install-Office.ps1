<#
.Synopsis
   Prepare config file and call office installation using ODT setup
.DESCRIPTION
   Prepare config file and call office installation using ODT setup
.EXAMPLE
   .\Install-Office.ps1 -DownloadTo '\\Server\Share' -BitVersion '64' -OfficeEdition 'ProPlusRetail'
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
#region initialization

param (
    [parameter(Mandatory=$true)]
    [string]$DownloadTo,
    [parameter(Mandatory=$true)]
    [string]$BitVersion,
    [parameter(Mandatory=$true)]
    [string]$OfficeEdition
)

#region creating the batch file
@"
@echo off
cd /D "%~dp0"

set LOGFILE=install_cmd.log
call :LOG > %LOGFILE%
exit /B

:LOG
setup.exe /download Config.xml
setup.exe /configure Config.xml
"@ | Out-File -FilePath "install.cmd" -Force -Encoding utf8
#endregion creating the batch file

#region creating the config file
@"
<Configuration>
  <Add SourcePath="{0}" OfficeClientEdition="{1}">
    <Product ID="{2}">
      <Language ID="en-us" />
    </Product>
  </Add>
  <!--  <Updates Enabled="FALSE" Branch="Current" /> -->
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="0" />
</Configuration>
"@ -f @($DownloadTo, $BitVersion, $OfficeEdition) | Out-File -FilePath "Config.xml" -Force -Encoding utf8
#endregion creating the batch file