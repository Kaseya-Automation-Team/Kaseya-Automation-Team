<#
.Synopsis
   Checks if MS Teams is installed on users' accounts.
.DESCRIPTION
   Checks if MS Teams is installed on users' accounts and saves information to a CSV-file.
.EXAMPLE
   .\Gather-MSTeams.ps1 -AgentName '12345' -FileName 'teams_info.csv' -Path 'C:\TEMP'
.EXAMPLE
   .\Gather-MSTeams.ps1 -AgentName '12345' -FileName 'teams_info.csv' -Path 'C:\TEMP' -LogIt 1
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
param (
    [parameter(Mandatory=$true)]
    [string] $AgentName,
    [parameter(Mandatory=$true)]
    [string] $FileName,
    [parameter(Mandatory=$true)]
    [string] $Path,
    [parameter(Mandatory=$false)]
    [int] $LogIt = 0
)

#region check/start transcript
[string]$Pref = 'Continue'
if ( 1 -eq $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $LogFile = "$path\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

$currentDate = Get-Date -UFormat "%m/%d/%Y %T"
#region output file path
if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }
#endregion output file path

# under the ProfileList key there are subkeys for each user in the system. 
[string] $RegKeyUserProfiles = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

[array] $outputArray = @()
[string] $TeamsFile = 'AppData\Local\Microsoft\Teams\current\Teams.exe'

# get local users' SIDs from the registry
[string[]] $UserAccountSIDs = try {
   Get-ChildItem -Name Registry::$RegKeyUserProfiles -ErrorAction Stop | `
   Where-Object { $_ -match "S-1-5-21-\d+" } #skip non-user accounts
} catch {$null}

#region Gather user names, pofile paths, Teams info
foreach ($UserSID in $UserAccountSIDs)
{
   [string] $ProfilePath = try {Get-ItemProperty -Path Registry::$(Join-Path -Path $RegKeyUserProfiles -ChildPath $UserSID) | `
      Select-Object -ExpandProperty ProfileImagePath                                      # get Profile path
   } catch { $null }

   $Principal = New-Object Security.Principal.SecurityIdentifier("$UserSID")
   [string] $NetbiosName = try { $Principal.Translate([Security.Principal.NTAccount]) | ` # get name by SID 
      Select-Object -ExpandProperty Value
   } catch { $null }

   if ( ($null -ne $Path) -and ($null -ne $NetbiosName) )
   {
      $TeamsInfo = New-Object PSObject -Property @{
         AgentGuid = $AgentName
         Hostname = $env:COMPUTERNAME
         User = $NetbiosName
         Version = 'NULL'
         Date = $currentDate
      }

      [string] $TeamsPath = Join-Path -Path $ProfilePath -ChildPath $TeamsFile
      if ( Test-Path -Path $TeamsPath ) # Teams file found in the user's profile
      {
         $TeamsInfo.Version = (Get-ItemProperty -Path $TeamsPath).VersionInfo.ProductVersion
      }
      $outputArray += $TeamsInfo
   } # if 
} #foreach
#endregion Gather user names, pofile paths, Teams info

$outputArray | Export-Csv -Path "FileSystem::$FileName" -Encoding UTF8 -NoTypeInformation -Force

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