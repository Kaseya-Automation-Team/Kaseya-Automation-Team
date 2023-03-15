# Outputs
$BitLockerStatus = "Unknown"
$RecoveryPassword = "Not set"
$Tpm = try { Get-Tpm -ErrorAction Stop } catch { $null }
if ( $null -ne $Tpm ) {
    if ( $Tpm.TpmPresent ) { 
        if ( -not $Tpm.TpmReady) {
            #Initialize the TPM if not initialized
            Initialize-Tpm -AllowClear -AllowPhysicalPresence | Out-Null
        }
        #Check if the System Drive already encrypted
        [bool]$IsEncrypted  = try { (Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop | Select-Object -ExpandProperty VolumeStatus) -eq 'FullyEncrypted' } catch { $false }
        #Ecncrypt the System Drive if it's not already encrypted
        if ( -not $IsEncrypted  ) {
            Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -TpmProtector
            Enable-BitLocker -MountPoint $env:SystemDrive -RecoveryPasswordProtector
            $BitLockerStatus = 'Enabled'
        } else {
            $BitLockerStatus = "System drive is already encrypted with BitLocker."
        }
    } else {
        $BitLockerStatus = "TPM is not present or enabled on this computer."
    }
} else {
    $BitLockerStatus = 'Could not detect TPM'
}
$RecoveryPassword = try {Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop| Where-Object {$_.KeyProtector.KeyProtectorType -eq 'RecoveryPassword'} | ForEach-Object { $_.KeyProtector.RecoveryPassword } } catch { 'Not set'}
if ( [string]::IsNullOrEmpty($RecoveryPassword) ) { $RecoveryPassword = 'Not set' }
#This call performs an implicit string conversion. To see what is actually set in
#the variable, uncomment the following line and look at the script output
#"$RecoveryPassword"
Start-Process -FilePath "$env:ProgramFiles\VSA X\CLI.exe" -ArgumentList ("setVariable RecoveryPassword ""$RecoveryPassword""") -Wait


#This call performs an implicit string conversion. To see what is actually set in
#the variable, uncomment the following line and look at the script output
#"$BitLockerStatus"
Start-Process -FilePath "$env:ProgramFiles\VSA X\CLI.exe" -ArgumentList ("setVariable BitLockerStatus ""$BitLockerStatus""") -Wait

