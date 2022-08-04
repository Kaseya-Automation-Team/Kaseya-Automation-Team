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
    [switch] LogIt
        - Enables execution transcript	
.EXAMPLE
   .\Create-MSOfficeInstaller.ps1 -ODTPath C:\TEMP\setup.exe -LogIt
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
    [System.IO.FileInfo] $ODTPath,

    [parameter(Mandatory=$false)]
    [switch] $LogIt
)

#region check/start transcript
[string]$Pref = 'Continue'
if ( $LogIt ) {
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
if ( -not( [Environment]::Is64BitOperatingSystem -and (64 -eq $BitVersion) )) {
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
  <Add OfficeClientEdition="64" Channel="PerpetualVL2021">
    <Product ID="ProPlus2021Volume">
      <Language ID="en-us" />
      <ExcludeApp ID="Lync" />
    </Product>
    <Product ID="VisioPro2021Volume">
      <Language ID="en-us" />
    </Product>
    <Product ID="ProjectPro2021Volume">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Remove All="True" />
</Configuration>
"@ | Out-File -FilePath "$ODTLocationFolder\Configuration.xml" -Force -Encoding utf8
#endregion  set output files content

#region check/stop transcript
if ( $LogIt ) {
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript