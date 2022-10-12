$LastRestorePoint = Get-ComputerRestorePoint | Sort-Object -Property CreationTime -Descending | Select-Object -First 1 | Select-Object -ExpandProperty SequenceNumber
if ($null -eq $LastRestorePoint) {
    "No Restore Points Found!" | Write-Output
} else {
    Restore-Computer -RestorePoint $LastRestorePoint
    "The Last Restore Point Reverted" | Write-Output
}