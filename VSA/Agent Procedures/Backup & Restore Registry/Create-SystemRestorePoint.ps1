$ExistingRestorePoints = Get-ComputerRestorePoint
if ($null -eq $ExistingRestorePoints) {
    Enable-ComputerRestore -Drive "$env:SystemDrive\"
} else {
    #remove restore points created in the last 24 hours
    $dayAgo = [system.management.ManagementDateTimeConverter]::ToDmtfDateTime((Get-Date).AddHours(-24))
    Get-WmiObject -query "SELECT * from Win32_ShadowCopy where Persistent = 'True' AND InstallDate > '$dayAgo'" | ForEach-Object {$_.Delete();}
}
Checkpoint-Computer -Description "RegistrySavePoint.$((Get-Date).tostring("MM-dd-yyyy"))" -RestorePointType MODIFY_SETTINGS