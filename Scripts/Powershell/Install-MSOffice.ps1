<#
.Synopsis
   Prepare config file and create office installation batch file using ODT setup
.DESCRIPTION
   Prepare config file and creates office installation batch file using ODT setup
.EXAMPLE
   .\Install-Office.ps1 -DownloadTo '\\Server\Share' -BitVersion '64' -OfficeEdition 'ProPlusRetail'
.EXAMPLE
   .\Install-Office.ps1 -DownloadTo 'C:\Temp' -BitVersion '64' -OfficeEdition 'ProPlus2019Retail' -ActivationKey '12345-12345-12345-12345-12345'
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
    [parameter(Mandatory=$false)]
    [string]$ActivationKey,
    # Create transcript file
    [parameter(Mandatory=$false)]
    [int] $LogIt = 1
)

#region check/start transcript
[string]$Pref = 'Continue'
if ( 1 -eq $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
    $LogFile = "$ScriptPath\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

if ( -not( [Environment]::Is64BitOperatingSystem -and (64 -eq $BitVersion) )) {$BitVersion = 32}

[string] $WorkDir = Split-Path $($MyInvocation.MyCommand.Path) -Parent

[string] $FilePath = Join-Path -Path $WorkDir -ChildPath "install.cmd"

#region creating the batch file
@"
@echo off
cd /D "%~dp0"

set LOGFILE=$ScriptName.log
call :LOG > %LOGFILE%
exit /B

:LOG
setup.exe /download Config.xml
setup.exe /configure Config.xml
"@ | Out-File -FilePath $FilePath -Force -Encoding utf8 -Verbose
#endregion creating the batch file

$FilePath = Join-Path -Path $WorkDir -ChildPath "Config.xml"

#region creating the config file
[string] $ConfigContent

#if activation key provided
if ( -not [string]::IsNullOrEmpty($ActivationKey) ) { $ActivationKey.Trim() }

if ( -not [string]::IsNullOrEmpty($ActivationKey) ) {
$ConfigContent = @"
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
"@ -f @($DownloadTo, $BitVersion, $OfficeEdition, $ActivationKey)
}
else { #no activation key
$ConfigContent = @"
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
"@ -f @($DownloadTo, $BitVersion, $OfficeEdition)
}

$ConfigContent | Out-File -FilePath $FilePath -Force -Encoding utf8 -Verbose

#endregion creating the config file

#region check/stop transcript
if ( 1 -eq $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript