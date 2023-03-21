<#
.Synopsis
   Creates a System Restore Point.
.DESCRIPTION
   Creates a System Restore Point. If a there are more Restore Points than specified by the Limit, removes older Restore Points and creates a new one
.NOTES
   Version 0.2
   Author: Proserv Team - VS
#>
param (
    [parameter(Mandatory=$false)]
    [int]$Limit = 10
 )

[array]$ExistingRestorePoints = Get-ComputerRestorePoint
if ($null -eq $ExistingRestorePoints) {
    Enable-ComputerRestore -Drive "$env:SystemDrive\"
} else {
    $TotalRPs = $ExistingRestorePoints.Count
    if ($TotalRPs -ge $Limit) {
        [array]$IDToRemove = Get-WmiObject -query "SELECT ID, InstallDate FROM Win32_ShadowCopy WHERE Persistent = 'True'" | Select-Object -Property ID, InstallDate, @{Name="Date"; Expression={$_.ConvertToDateTime($_.InstallDate)}} | Sort-Object -Descending -Property Date | Select-Object -ExpandProperty ID -Last $($TotalRPs - $Limit + 1)
        Get-WmiObject -query "SELECT ID, InstallDate FROM Win32_ShadowCopy WHERE Persistent = 'True'" | Where-Object { $IDToRemove.Contains( $_.ID ) } | ForEach-Object {$_.Delete();}
    }
}
[string]$Description = "RegistrySavePoint.$((Get-Date).tostring("MM-dd-yyyy"))"
Checkpoint-Computer -Description $Description -RestorePointType MODIFY_SETTINGS
"Restore Point $Description created" | Write-Output
