<#
.Synopsis
   Gather list of Top 10 Largest Directories In Drives and saves information to a csv-file
.DESCRIPTION
   Gather list of Top 10 Largest Directories In Drives and saves information to a csv-file
.EXAMPLE
   Gather-BiggestFolders -FileName 'biggestfolders.csv' -Path 'C:\TEMP' -AgentName '123456'
.EXAMPLE
Gather-BiggestFolders -FileName 'biggestfolders.csv' -Path 'C:\TEMP' -AgentName '123456' -Top 10
.NOTES
   Version 0.1
   Author: Vladislav Semko
   Email: Vladislav.Semko@kaseya.com
#>

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    [parameter(Mandatory=$true)]
    [string]$FileName,
    [parameter(Mandatory=$true)]
    [string]$Path,
    [parameter(Mandatory=$false)]
    [int]$Top = 10
 )


$currentDate = Get-Date -UFormat "%m/%d/%Y %T"
if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

[hashtable]$CimParams = @{
    query = "SELECT Name, FreeSpace, Capacity FROM Win32_Volume WHERE DriveType = 3 AND DriveLetter != NULL"
    ErrorAction = "Stop"
}

$LocalDrives = try{
    Get-CimInstance @CimParams }
catch {$null}

if ($null -ne $LocalDrives)
{
    Foreach ($Drive in $LocalDrives )
    {
        [array] $FolderInfo = @()
        Get-ChildItem -Directory -Force $Drive.Name -ErrorAction SilentlyContinue | ForEach-Object {
                [uint64]$Size = 0
                Get-ChildItem -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { $Size += $_.Length }
                $FolderInfo += [PSCustomObject] @{
                    AgentGuid =$AgentName
                    Hostname = $env:COMPUTERNAME
                    Date = $currentDate
                    Drive = $Drive.Name
                    Available = $( "{0:P2}" -f ( $Drive.FreeSpace / $Drive.Capacity ) )
                    Folder = $($_.FullName)
                    Size = $Size
                }
        }
        $FolderInfo | Sort-Object -Descending -Property SizeGb | Select-Object -First $Top| Select-Object AgentGuid, Hostname, Date, Drive, Available, Folder, @{name="Size, Gb";expression={ $( "{0:N2}" -f ($_.Size / 1Gb) )}} | Export-Csv -Path "FileSystem::$FileName" -Append -Encoding UTF8 -NoTypeInformation
    }
}