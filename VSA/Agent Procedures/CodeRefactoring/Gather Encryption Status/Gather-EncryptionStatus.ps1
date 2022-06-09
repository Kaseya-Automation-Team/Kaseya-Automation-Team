#This script checks status of BitLocker encryption

# Outputs
$EncryptionStatus = "Null"

$CurrentEncryptionStatus = (Get-BitLockerVolume |Select-Object -Property ProtectionStatus).ProtectionStatus

Start-Process -FilePath "$env:PWY_HOME\CLI.exe" -ArgumentList ("setVariable EncryptionStatus ""$CurrentEncryptionStatus""") -Wait