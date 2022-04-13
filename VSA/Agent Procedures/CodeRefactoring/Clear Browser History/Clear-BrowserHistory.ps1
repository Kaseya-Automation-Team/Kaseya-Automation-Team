<#
    Removes history entries for the most popular browsers.
#>
#Number of days to keep history. 0 - to keep nothing
[int] $DaysToKeep = 7

#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

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


If ($DaysToKeep -gt 0) {
    $Info = "older than $DaysToKeep days cleared"
} else {
    $DaysToKeep = 0
    $Info = "cleared"
}

#Perform cleanup
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
        $RunningProcessProfilePath = $env:USERPROFILE
        
        $AppDataPath = $AppDataPath.Replace($RunningProcessProfilePath, $UserProfilePath)

        #region Cleanup
            #region Cookies
            #Mozilla
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Mozilla\Firefox\Profiles\*.default*\cookies.sqlite" -Resolve
            #Chrome
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default*\Cookies*" -Resolve
            #Microsoft browsers
            $ItemsToClear += Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") -Name "Cookies" `
                | Select-Object -ExpandProperty "Cookies"
            [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Cookies $Info for User SID: $($UserProfile.SID)", "Information", 200)
            #endregion Cookies
            #region Temporary files
            #Mozilla
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Mozilla\Firefox\Profiles\*.default*\cache*" -Resolve
            #Chrome
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default\cache*" -Resolve
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default\Media Cache*" -Resolve
            #Microsoft browsers
            $ItemsToClear += Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") -Name "Cache" `
                | Select-Object -ExpandProperty "Cache"
            [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Cached files $Info for User SID: $($UserProfile.SID)", "Information", 200)
            #endregion Temporary files
            #region History
            #Mozilla
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Mozilla\Firefox\Profiles\*.default*\places.sqlite" -Resolve
            #Chrome
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default\History*" -Resolve
            $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default\Visited Links*" -Resolve
            #Microsoft browsers
            $ItemsToClear += Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") -Name "History" `
                | Select-Object -ExpandProperty "History"
            [System.Diagnostics.EventLog]::WriteEntry("VSA X", "History $Info for User SID: $($UserProfile.SID)", "Information", 200)
            #endregion History

        $ItemsToClear | ForEach-Object { $Item = $_.Replace($RunningProcessProfilePath, $UserProfilePath); Clear-Path -Path $Item -DaysToKeep $DaysToKeep }
        #endregion Cleanup

        [gc]::Collect()
        If ( -Not $IsProfileLoaded )
        {
            reg unload "HKU\$($_.SID)"
        }
    }# ForEach-Object
