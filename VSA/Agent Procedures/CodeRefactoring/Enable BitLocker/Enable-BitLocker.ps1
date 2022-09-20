<#
=================================================================================
Script Name:        Management: Enable BitLocker.
Description:        This script silently enables BitLocker for system drive.
Lastest version:    2022-09-20
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
#Check BitLocker requirements
$TPMEnabled = Get-WmiObject win32_tpm -Namespace root\cimv2\security\microsofttpm | where {$_.IsEnabled_InitialValue -eq $true} -ErrorAction SilentlyContinue
$WindowsVer = Get-WmiObject -Query 'select * from Win32_OperatingSystem where (Version like "6.2%" or Version like "6.3%" or Version like "10.0%") and ProductType = "1"' -ErrorAction SilentlyContinue
$BitLockerReadyDrive = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue
$BitLockerDecrypted = Get-BitLockerVolume -MountPoint $env:SystemDrive | where {$_.VolumeStatus -eq "FullyDecrypted"} -ErrorAction SilentlyContinue
$BLVS = Get-BitLockerVolume | Where-Object {$_.KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'}} -ErrorAction SilentlyContinue


#Check if TPM is enabled and initialize if required
if ($WindowsVer -and $TPMEnabled) 
{
    Initialize-Tpm -AllowClear -AllowPhysicalPresence | Out-Null
}

#Check if BitLocker volume is provisioned and partition system drive for BitLocker if required
if ($WindowsVer -and $TPMEnabled -and !$BitLockerReadyDrive) 
{
    Get-Service -Name defragsvc -ErrorAction SilentlyContinue | Set-Service -Status Running -ErrorAction SilentlyContinue
    BdeHdCfg -target $env:SystemDrive shrink -quiet
}

#If all requirements are met, then enable BitLocker
if ($WindowsVer -and $TPMEnabled -and $BitLockerReadyDrive -and $BitLockerDecrypted) 
{
    Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -TpmProtector
    Enable-BitLocker -MountPoint $env:SystemDrive -RecoveryPasswordProtector
    Write-Host "BitLocker encryption has been successfully enabled for drive $env:SystemDrive"
    eventcreate /L Application /T INFORMATION /SO "VSA X" /ID 200 /D "BitLocker encryption has been successfully enabled for drive $env:SystemDrive by VSA X script." | Out-Null

} else {
    Write-Host "There are no drives ready to be encrypted with BitLocker. Can't continue."
    eventcreate /L Application /T ERROR /SO "VSA X" /ID 400 /D "There are no drives ready to be encrypted with BitLocker. Can't continue." | Out-Null

}