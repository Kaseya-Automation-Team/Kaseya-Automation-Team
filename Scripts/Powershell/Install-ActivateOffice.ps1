﻿<#
.Synopsis
   Prepare config file and create office installation batch file using ODT setup
.DESCRIPTION
   Prepare config file and create office installation batch file using ODT setup
.EXAMPLE
   .\Install-Office.ps1 -DownloadTo '\\Server\Share' -BitVersion '64' -OfficeEdition 'ProPlusRetail' -ActivationKey '12345-12345-12345-12345-12345'
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
    [string]$OfficeEdition,
    [parameter(Mandatory=$true)]
    [string]$ActivationKey
)

[string]$WorkDir = Split-Path $($MyInvocation.MyCommand.Path) -Parent

[string]$FilePath = Join-Path -Path $WorkDir -ChildPath "install.cmd"

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
"@ | Out-File -FilePath $FilePath -Force -Encoding utf8
#endregion creating the batch file

$FilePath = Join-Path -Path $WorkDir -ChildPath "Config.xml"

#region creating the config file
@"
<Configuration>
  <Add SourcePath="{0}" OfficeClientEdition="{1}">
    <Product ID="{2}" PIDKEY="{3}">
      <Language ID="en-us" />
    </Product>
  </Add>
  <!--  <Updates Enabled="FALSE" Branch="Current" /> -->
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="1" />
</Configuration>
"@ -f @($DownloadTo, $BitVersion, $OfficeEdition, $ActivationKey) | Out-File -FilePath $FilePath -Force -Encoding utf8
#endregion creating the config file