# Get all printers
$printers = Get-WmiObject -Query "Select * From Win32_Printer"

# Loop through each printer and print the driver name and status
foreach ($printer in $printers) {
    Write-Output ("{0} - {1}" -f $printer.DriverName, $printer.Status)
}


# Get the spooler service
$spoolerService = Get-Service -Name Spooler

# Print the spooler service status
Write-Output ("Spooler Service Status: {0}" -f $spoolerService.Status)


# Open the printer properties dialog for a specific printer
Start-Process -FilePath "rundll32.exe" -ArgumentList "printui.dll,PrintUIEntry /p /n ""Microsoft XPS Document Writer v4"""
