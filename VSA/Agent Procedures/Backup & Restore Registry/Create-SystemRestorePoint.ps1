<#
.Synopsis
   Creates a System Restore Point.
.DESCRIPTION
   Creates a System Restore Point. If a Restore Point was created within the last 24 hours, removes it and creates a new one
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
$ExistingRestorePoints = Get-ComputerRestorePoint
if ($null -eq $ExistingRestorePoints) {
    Enable-ComputerRestore -Drive "$env:SystemDrive\"
} else {
    #remove restore points created in the last 24 hours
    $dayAgo = [system.management.ManagementDateTimeConverter]::ToDmtfDateTime((Get-Date).AddHours(-24))
    Get-WmiObject -query "SELECT * from Win32_ShadowCopy where Persistent = 'True' AND InstallDate > '$dayAgo'" | ForEach-Object {$_.Delete();}
}
[string]$Description = "RegistrySavePoint.$((Get-Date).tostring("MM-dd-yyyy"))"
Checkpoint-Computer -Description $Description -RestorePointType MODIFY_SETTINGS
"Restore Point $Description created" | Write-Output