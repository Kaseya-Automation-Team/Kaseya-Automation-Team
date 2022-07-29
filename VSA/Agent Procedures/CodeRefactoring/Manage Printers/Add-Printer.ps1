$DriverName = ''
$IPAddress = ''
$PrinterName = ''
Add-PrinterDriver -Name $Driver  -ErrorAction Continue
Add-PrinterPort -Name "IP_$IPAddress" -PrinterHostAddress $IPAddress  -ErrorAction Continue
Add-Printer -Name $PrinterName -PortName "IP_$IPAddress" -DriverName $DriverName  -ErrorAction Continue