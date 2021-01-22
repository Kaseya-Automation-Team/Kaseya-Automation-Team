## Kaseya Automation Team
## Used by the "Uninstall Adobe DC PRO Trial" Agent Procedure

$Status = (Get-Package * | Where-Object {$_.Tagid -eq "AC76BA86-1033-FFFF-7760-0C0F074E4100"} | Select-Object -Property Status).Status

If ($Status -eq "Installed") {

    Write-Host "Attempting to start uninstallation process"

    Start-Process msiexec.exe -ArgumentList '-x "{AC76BA86-1033-FFFF-7760-0C0F074E4100}" /quiet' -Wait

    Write-Host "Adobe Reader DC PRO has been successully uninstalled"

} else {

    Write-Host "Adobe Reader DC PRO application doesn't seem to be installed"

}