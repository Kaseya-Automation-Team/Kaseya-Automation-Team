<#
.Synopsis
   Gather list of latest updates and saves information to a csv-file
.DESCRIPTION
   Gather list of latest Windows updates and saves information as well as last boot time to a csv-file
.EXAMPLE
   .\Gather-LastOSPatchesInstalled.ps1 -FileName 'latest_os_patches.csv' -Path 'C:\TEMP' -AgentName '123456'
.EXAMPLE
    .\Gather-LastOSPatchesInstalled.ps1 -FileName 'latest_os_patches.csv' -Path 'C:\TEMP' -AgentName '123456' -LogIt 1
.NOTES
   Version 0.1.3
   Author: Proserv Team - VS
#>

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,

    [parameter(Mandatory=$true)]
    [string]$FileName,

    [parameter(Mandatory=$true)]
    [string]$Path,

    [parameter(Mandatory=$false)]
    [int] $LogIt = 0
)

#region check/start transcript
[string]$Pref = 'Continue'
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $LogFile = "$path\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

#[string] $LastBootUp = "{0:MM'/'dd'/'yyyy H:mm:ss}" -f [System.Management.ManagementDateTimeConverter]::ToDateTime($(Get-WmiObject -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime))
[string] $LastBootUp = "{0:MM'/'dd'/'yyyy H:mm:ss}" -f (Get-Date).AddMilliseconds( -([System.Environment]::TickCount) )

#region function Convert-WuaResultCodeToName
# Convert Wua History ResultCode to a Name # 0, and 5 are not used for history # See https://msdn.microsoft.com/en-us/library/windows/desktop/aa387095(v=vs.85).aspx
function Convert-WuaResultCodeToName
{
    param( [Parameter(Mandatory=$true)]
    [int] $ResultCode
    )
    $Result = $ResultCode
    switch($ResultCode)
    {
        1 {
            $Result = "In progress"
        }
        2 {
            $Result = "Succeeded"
        }
        3 {
            $Result = "Succeeded With Errors"
        }
        4 {
            $Result = "Failed"
        }
    }
    return $Result
}
#endregion function Convert-WuaResultCodeToName

function Get-WuaHistory
{
    # Get a WUA Session
    $session = (New-Object -ComObject 'Microsoft.Update.Session')
    # Query the latest 1000 History starting with the first recordp
    $history = $session.QueryHistory("",0,50) | ForEach-Object {
        $Result = Convert-WuaResultCodeToName -ResultCode $_.ResultCode
        # Make the properties hidden in com properties visible.
        $_ | Add-Member -MemberType NoteProperty -Value $Result -Name Result
        $Product = $_.Categories | Where-Object {$_.Type -eq 'Product'} | Select-Object -First 1 -ExpandProperty Name
        $_ | Add-Member -MemberType NoteProperty -Value $_.UpdateIdentity.UpdateId -Name UpdateId
        $_ | Add-Member -MemberType NoteProperty -Value $_.UpdateIdentity.RevisionNumber -Name RevisionNumber
        $_ | Add-Member -MemberType NoteProperty -Value $Product -Name Product -PassThru
        Write-Output $_
    }
    #Remove null records and only return the fields we want
    $Regexp = 'KB\d+'

    $history |
    Where-Object { -not [String]::IsNullOrWhiteSpace($_.title) } |
        Select-Object @{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}}, `
        @{Name = 'AgentGuid'; Expression = {$AgentName}}, `
        @{Name = 'PatchName'; Expression = {$( if ($_.title -match $Regexp) {$matches[0]} else {$_.title} )}}, `  
        @{Name = 'LastBootTime'; Expression = {$LastBootUp}}, ` 
        Result, Date, Title, SupportUrl, Product, UpdateId, RevisionNumber -unique
}

#Export results to csv file

try { Get-WuaHistory | Export-Csv -Path "FileSystem::$OutputFilePath" -Encoding UTF8 -NoTypeInformation -Force -ErrorAction Stop } catch { $_.Exception.Message }

#region check/stop transcript
if (1 -eq $LogIt)
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript