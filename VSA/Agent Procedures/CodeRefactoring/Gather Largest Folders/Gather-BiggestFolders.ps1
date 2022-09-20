<#
=================================================================================
Script Name:        Audit: Gather Largest Folders.
Description:        Gather list of Top 10 Largest Folders on Local Drives.
Lastest version:    2022-06-16
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>

#Create VSA Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

$TopLargest = 10

[hashtable]$CimParams = @{
    query = "SELECT Name, FreeSpace, Capacity FROM Win32_Volume WHERE DriveType = 3 AND DriveLetter != NULL"
    ErrorAction = "Stop"
}

$LocalDrives = try {
    Get-CimInstance @CimParams
} catch {
    $null
}

if ($null -ne $LocalDrives) {
    Foreach ($Drive in $LocalDrives ) {
        [array] $FolderInfo = @()
        Get-ChildItem -Directory -Force $Drive.Name -ErrorAction SilentlyContinue | ForEach-Object {
                [uint64]$Size = 0
                Get-ChildItem -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { $Size += $_.Length }
                $FolderInfo += [PSCustomObject] @{
                    Drive = $Drive.Name 
                    Available = $( "{0:P2}" -f ( $Drive.FreeSpace / $Drive.Capacity ) )
                    Folder = $($_.FullName)
                    Size = $Size
                }
        }
        $Result = $FolderInfo | Sort-Object -Descending -Property Size, Folder  | Select-Object -First $TopLargest | Select-Object Drive, Available, Folder, @{name="Size, Gb";expression={ $( "{0:N2}" -f ($_.Size / 1Gb) )}} | Out-String
        $Result | Write-Output
    }
}