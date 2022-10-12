<#
.Synopsis
   Reverts to the Last System Restore Point.
.DESCRIPTION
   Reverts to the Last System Restore Point.
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
$LastRestorePoint = Get-ComputerRestorePoint | Sort-Object -Property CreationTime -Descending | Select-Object -First 1 | Select-Object -ExpandProperty SequenceNumber
if ($null -eq $LastRestorePoint) {
    "No Restore Points Found!" | Write-Output
} else {
    Restore-Computer -RestorePoint $LastRestorePoint
    "The Last Restore Point Reverted" | Write-Output
}