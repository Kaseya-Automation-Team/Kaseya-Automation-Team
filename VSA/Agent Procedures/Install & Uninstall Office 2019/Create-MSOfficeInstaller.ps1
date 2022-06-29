<#
.Synopsis
   Creates config file and installation batch file for MS Office setup.
.DESCRIPTION
   Prepares an ODT config file and creates a batch for MS Office setup using the ODT.
.NOTES
   Version 0.2.1
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
   .\Create-MSOfficeInstaller.ps1 -ODTPath C:\TEMP\setup.exe -BitVersion 32 -OfficeEdition Standard2019Volume -ActivationKey '12345-12345-12345-12345-12345' -LogIt
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
    [string]$BitVersion,
    [parameter(Mandatory=$true)]
    [string]$OfficeEdition,
    [parameter(Mandatory=$false)]
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
[string] $AutoActivate = "0"

        if ( -not [string]::IsNullOrEmpty($ActivationKey) ) {
            [string] $ProductKey = "PIDKEY=`"$ActivationKey`""
            $AutoActivate = "1"
        }

        [string] $ConfigContent = @"
<Configuration>
  <Add SourcePath="{0}" OfficeClientEdition="{1}">
    <Product ID="{2}" {3}>
      <Language ID="MatchOS" />
    </Product>
  </Add>
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/>
  <!--  <Updates Enabled="TRUE" Branch="Current" /> -->
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="{4}" />
</Configuration>
"@ -f @($ODTLocationFolder, $BitVersion, $OfficeEdition, $ProductKey, $AutoActivate) | Out-File -FilePath "$ODTLocationFolder\Configuration.xml" -Force -Encoding utf8
#endregion  set output files content

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