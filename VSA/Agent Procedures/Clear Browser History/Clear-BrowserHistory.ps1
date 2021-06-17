<#
.SYNOPSIS
    Removes history entries for the most popular browsers.
.DESCRIPTION
    Removes history entries for Google Chrome, Mozilla Firefox & IE.
.PARAMETER DaysToKeep
    Specifies the number of days to keep browser data. Everything older that
    the given number of days will be removed.
    Defaults to 7.
.PARAMETER All
    This is a shorthand switch. When set, Cookies, Temporary files and History items will be cleared.
.PARAMETER Cookies
    When set, Cookies will be removed.
.PARAMETER TemporaryFiles
    When set, the Temporary files will be removed.
.PARAMETER History
    When set, History and History-journal and Visited Links will be removed.
.EXAMPLE
    .\Clear-BrowserHistory.ps1 -All -DaysToKeep 14
    Will remove Cookies, Temporary files and History older than 14 days.
.EXAMPLE
    .\Clear-BrowserHistory.ps1 -Cookies -DaysToKeep 0
    Will remove all cookies.
.NOTES
    Version 0.1
    Author: Proserv Team - VS
#>
param (
    [Parameter(ParameterSetName='ByAll')]
    [switch] $All,

    [Parameter(ParameterSetName='ByItem')]
    [switch] $Cookies,          # file: Cookies and Cookies-journal
    [Parameter(ParameterSetName='ByItem')]
    [switch] $TemporaryFiles,   # folder: Cache
    [Parameter(ParameterSetName='ByItem')]
    [switch] $History , # Archived History
    [Parameter(ParameterSetName='ByItem')]
    [Parameter(ParameterSetName='ByAll')]
    [switch] $LogIt,
    [Parameter(ParameterSetName='ByItem')]
    [Parameter(ParameterSetName='ByAll')]
    [int] $DaysToKeep = 7
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

function Clear-Path {
[CmdletBinding()]
param (
    [parameter(Mandatory = $true, 
    Position = 0,
    ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $Path,
    [Parameter(Mandatory = $true,
    Position = 1,
    ValueFromPipeline=$true)]
    [int] $DaysToKeep
)
    $OlderThan = (Get-Date).AddDays(-([Math]::Abs($DaysToKeep)))
    if(Test-Path -Path $Path -Verbose)
    {
        $TheItem = Get-Item -Path $Path -Force -Verbose

        If ( $TheItem -is [System.IO.DirectoryInfo] )
        {
            $TheItem | Get-ChildItem -Recurse -Force | Where-Object { $_.CreationTime -lt $OlderThan } | Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
        }
        else
        {
            if( $TheItem.CreationTime -lt $OlderThan )
            {
                 $TheItem | Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
            }
        }        
    }
}

#Clear users' cookies
[string] $SIDPattern = 'S-1-5-21-(\d+-?){4}$'
Get-WmiObject Win32_UserProfile | Where-Object {$_.SID -match $SIDPattern} | Select-Object LocalPath, SID | `
    ForEach-Object {
        
        [array] $ItemsToClear = @()
        $UserProfilePath = $_.LocalPath

        [bool] $IsProfileLoaded = Test-Path Registry::HKEY_USERS\$($_.SID)
        If ( -Not $IsProfileLoaded )
        {
            reg load "HKU\$($_.SID)" "$UserProfilePath\ntuser.dat"
        }

        [string] $AppDataPath = Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") -Name "Local AppData" | Select-Object -ExpandProperty "Local AppData"
        <#
        Typically, the path to the user's TEMP folder in the registry contains a relative path that refers to the USERPROFILE system variable.
        When the registry value is read, the runtime automatically places the running process owner's profile path in the USERPROFILE variable.
        Therefore, to get the correct path to the user's TEMP folder, the registry value referencing USERPROFILE must be corrected by replacing the process owner's profile path with the user's profile path.
        #>
        $RunningProcessProfilePath = $env:USERPROFILE
        
        $AppDataPath = $AppDataPath.Replace($RunningProcessProfilePath, $UserProfilePath)

        #region Cleanup
        if ($Cookies -or $All)
        {
            #Mozilla
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Mozilla\Firefox\Profiles\*.default*\cookies.sqlite" -Resolve
            #Chrome
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default*\Cookies*" -Resolve
            #Microsoft browsers
            $ItemsToClear += Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") -Name "Cookies" `
                | Select-Object -ExpandProperty "Cookies"
        }
        if ($TemporaryFiles -or $All)
        {
            #Mozilla
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Mozilla\Firefox\Profiles\*.default*\cache*" -Resolve
            #Chrome
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default\cache*" -Resolve
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default\Media Cache*" -Resolve
            #Microsoft browsers
            $ItemsToClear += Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") -Name "Cache" `
                | Select-Object -ExpandProperty "Cache"
        }
        if ($History -or $All)
        {
            #Mozilla
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Mozilla\Firefox\Profiles\*.default*\places.sqlite" -Resolve
            #Chrome
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default\History*" -Resolve
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default\Visited Links*" -Resolve
            #Microsoft browsers
            $ItemsToClear += Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") -Name "History" `
                | Select-Object -ExpandProperty "History"
        }

        $ItemsToClear | ForEach-Object { $Item = $_.Replace($RunningProcessProfilePath, $UserProfilePath); Clear-Path -Path $Item -DaysToKeep $DaysToKeep }
        #endregion Cleanup

        [gc]::Collect()
        If ( -Not $IsProfileLoaded )
        {
            reg unload "HKU\$($_.SID)"
        }
    }

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