# Get all devices
$devices = Get-WmiObject Win32_PnPSignedDriver

# Loop through each device and print the driver version
foreach ($device in $devices) {
    Write-Output ("{0} - {1}" -f $device.DeviceName, $device.DriverVersion)
}
