<#
=================================================================================
Script Name:        Management: Get BitLocker Recovery Key.
Description:        Checks if system drive is already encrypted with BitLocker and if so, gets recovery key.
Lastest version:    2022-09-20
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
#Check if BitLocker is enabled for system drive
if ((Get-BitLockerVolume -MountPoint $env:SystemDrive).ProtectionStatus -eq "On") {
	#Get recovery key
    $RecoveryKey = (Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector|Select-Object -ExpandProperty RecoveryPassword
    #Display recovery key
    Write-Host "Recovery key for system drive ($env:SystemDrive) is: $RecoveryKey"
} else {
    #Throw a message if BitLocker is NOT enabled
    Write-Warning "BitLocker is not enabled for system drive ($env:SystemDrive)"
}