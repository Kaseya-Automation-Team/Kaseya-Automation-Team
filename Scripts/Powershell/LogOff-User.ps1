<#
.Synopsis
  Logs of specific user / all user on the computer
.DESCRIPTION
   Performs an immediate forced logoff for specified user on the computer. If no user specified performs an immediate forced logoff for all logged on users
.EXAMPLE
   .\LogOff-Users -LoginName 'testuser'
.EXAMPLE
   .\LogOff-Users
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
param (
    [parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
    [string] $LoginName,
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

[array]$Sessions = Get-Process -IncludeUserName | `
                        Select-Object UserName, SessionId | `
                        Where-Object { $_.UserName -ne $null } | `
                        Sort-Object SessionId -Unique

Write-Debug "Current sessions: $($Sessions | Out-String)"

if ( -not [string]::IsNullOrEmpty($LoginName))
{
    if ($LoginName -match '\\') #Login name in 'Domain\User format'
    {
        $Sessions = $Sessions | Where-Object { $LoginName -eq $_.UserName}
    }
    else #Login name without domain 
    {
        $Sessions = $Sessions | Where-Object { $LoginName -eq $_.UserName.Substring( $($_.UserName.LastIndexOf('\') + 1) ) }
    }
}

if ( 0 -lt $Sessions.Count )
{
    $Sessions.SessionId | ForEach-Object {
        try { 
            query session $_ | where-object {$_ -notmatch 'services'} | logoff $_ /v | Write-Debug
        }
        Catch {
            Write-Warning "$_.Exception.Message"
        }
    }
}

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