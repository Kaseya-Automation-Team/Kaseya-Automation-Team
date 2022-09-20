<#
=================================================================================
Script Name:        Disable BitLocker
Description:        Disables BitLocker protection for system drive.
Lastest version:    2022-09-20
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
#Check if BitLocker is currently enabled
if ((Get-BitLockerVolume -MountPoint $env:SystemDrive).ProtectionStatus -eq "On") {
    #Disable BitLocker protection
    try {
	    Disable-BitLocker -MountPoint $env:SystemDrive
        eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "BitLocker protection has been disabled by VSA X script." | Out-Null
    }
    catch {
	    Write-Error $_.Exception.Message
        eventcreate /L Application /T ERROR /SO VSAX /ID 400 /D "Unable to disable BitLocker protection." | Out-Null
    }

} else {
    Write-Warning "BitLocker is not enabled for system drive ($env:SystemDrive)"
}