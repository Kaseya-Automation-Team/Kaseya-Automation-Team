# Inputs
$BitLockerStatus = BitLocker Status: # Custom Field variable evaluated at runtime

# Outputs
$BitLockerStatus = "Unknown"
$RecoveryPassword = "Not set"
if ( 'Enabled' -eq $BitLockerStatus ) {
    if ((Get-BitLockerVolume -MountPoint $env:SystemDrive).ProtectionStatus -eq "On") {
         $BitLockerStatus = try {
            Disable-BitLocker -MountPoint $env:SystemDrive -ErrorAction Stop | Out-Null
            'Disabled' | Write-Output
        } catch {
            $_.Exception.Message  | Write-Output
        }
    }
}
#This call performs an implicit string conversion. To see what is actually set in
#the variable, uncomment the following line and look at the script output
#"$BitLockerStatus"
Start-Process -FilePath "$env:ProgramFiles\VSA X\CLI.exe" -ArgumentList ("setVariable BitLockerStatus ""$BitLockerStatus""") -Wait


#This call performs an implicit string conversion. To see what is actually set in
#the variable, uncomment the following line and look at the script output
#"$RecoveryPassword"
Start-Process -FilePath "$env:ProgramFiles\VSA X\CLI.exe" -ArgumentList ("setVariable RecoveryPassword ""$RecoveryPassword""") -Wait

