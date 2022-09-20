<#
=================================================================================
Script Name:        Audit: Security: Gather Encryption Status.
Description:        Gather BitLocker Encryption Status.
Lastest version:    2022-06-09
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
#This script checks status of BitLocker encryption

# Outputs
$EncryptionStatus = "Null"

$CurrentEncryptionStatus = (Get-BitLockerVolume |Select-Object -Property ProtectionStatus).ProtectionStatus

Start-Process -FilePath "$env:PWY_HOME\CLI.exe" -ArgumentList ("setVariable EncryptionStatus ""$CurrentEncryptionStatus""") -Wait