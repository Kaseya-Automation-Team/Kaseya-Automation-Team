<#
.Synopsis
   Creates config file and installation batch file for MS Office setup.
.DESCRIPTION
   Prepares an ODT config file and creates a batch for MS Office setup using the ODT.
.NOTES
   Version 0.2
   Author: Proserv Team - VS
.PARAMETERS
    [string] ODTPath
        - ODT file location
    [string] BitVersion
        - Bit Version
    [string] OfficeEdition
        - Supported Product IDs according to https://docs.microsoft.com/en-us/office365/troubleshoot/installation/product-ids-supported-office-deployment-click-to-run
    [string] ActivationKey
        - The Product Activation Key
    [switch] LogIt
        - Enables execution transcript	
.EXAMPLE
   .\Create-MSOfficeInstaller.ps1 -ODTPath C:\TEMP\ODT.exe -BitVersion 32 -OfficeEdition Standard2019Volume -ActivationKey '12345-12345-12345-12345-12345' -LogIt
#>

param (
    [parameter(Mandatory=$true)]
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "Path <$_> is not accessible" 
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The DownloadTo argument must be a file. Folder paths are not allowed."
        }
        return $true
    })]
    [string] $ODTPath,
    [parameter(Mandatory=$true)]
    [ValidateSet("32","64")]
    [string]$BitVersion,
    [parameter(Mandatory=$true)]
    [ValidateSet("AccessRetail", "Access2019Retail", "Access2019Volume", "ExcelRetail", "Excel2019Retail", "Excel2019Volume", "HomeBusinessRetail", "HomeBusiness2019Retail", "HomeStudentRetail", "HomeStudent2019Retail", "O365HomePremRetail", "OneNoteRetail", "OutlookRetail", "Outlook2019Retail", "Outlook2019Volume", "Personal2019Retail", "PowerPointRetail", "PowerPoint2019Retail", "PowerPoint2019Volume", "ProfessionalRetail", "Professional2019Retail", "ProfessionalPlusRetail", "ProPlus2019Retail", "ProjectProXVolume", "ProjectPro2019Retail", "ProjectPro2019Volume", "ProjectStdRetail", "ProjectStdXVolume", "ProjectStd2019Retail", "ProjectStd2019Volume", "ProPlus2019Volume", "ProPlus2019Retail", "PublisherRetail", "Publisher2019Retail", "Publisher2019Volume", "Standard2019Volume", "VisioProXVolume", "VisioPro2019Retail", "VisioPro2019Volume", "VisioStdRetail", "VisioStdXVolume", "VisioStd2019Retail", "VisioStd2019Volume", "WordRetail", "Word2019Retail", "Word2019Volume")]
    [string]$OfficeEdition,
    [parameter(Mandatory=$false)]
    [ValidatePattern("^([A-Z0-9]{5}-){4}[A-Z0-9]{5}$")]
    [string]$ActivationKey,
    [parameter(Mandatory=$false)]
    [switch] $LogIt
)

#region check/start transcript
[string]$Pref = 'Continue'
if ( $LogIt )
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

#--------------------------------
if ( -not( [Environment]::Is64BitOperatingSystem -and (64 -eq $BitVersion) ))
{
    $BitVersion = 32
}
[string] $ODTLocationFolder = Split-Path $ODTPath -Parent

#--------------------------------
#region set output files content
[string] $ConfigContent
#if activation key provided
if ( -not [string]::IsNullOrEmpty($ActivationKey) )
{
$ConfigContent = @"
<Configuration>
  <Add SourcePath="{0}" OfficeClientEdition="{1}" Channel="PerpetualVL2019">
    <Product ID="{2}" PIDKEY="{3}">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Updates Enabled="TRUE" Branch="Current" />
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="1" />
</Configuration>
"@ -f @($ODTLocationFolder, $BitVersion, $OfficeEdition, $ActivationKey)
}
else #no activation key
{ 
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
"@ -f @($ODTLocationFolder, $BitVersion, $OfficeEdition)
}
#--------------------------------
[string] $BatchContent = @"
@echo off
cd /D "%~dp0"

set LOGFILE=$ScriptName.log
call :LOG > %LOGFILE%
exit /B

:LOG
$ODTPath /download Config.xml
$ODTPath /configure Config.xml
"@
#endregion  set output files content


#region creating the output files
$OutputFilePath  = Join-Path -Path $ODTLocationFolder -ChildPath "install.cmd"
$BatchContent | Out-File -FilePath $OutputFilePath -Force -Encoding utf8 -Verbose

$OutputFilePath = Join-Path -Path $ODTLocationFolder -ChildPath "Config.xml"
$ConfigContent | Out-File -FilePath $OutputFilePath -Force -Encoding utf8 -Verbose
#endregion creating the output files

#region check/stop transcript
if ( $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript