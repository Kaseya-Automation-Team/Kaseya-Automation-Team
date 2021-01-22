## Kaseya Automation Team
## Used by the "Install Adobe DC PRO Trial" Agent Procedure

param (
    [parameter(Mandatory=$true)]
	[string]$Path = ""
)

$ExtractPath = "$env:TEMP\Acrobat"

Write-Host "Starting extraction of SFX archive"

try {
    Start-Process -FilePath "$Path\Acrobat_DC_Web_WWMUI.exe" -ArgumentList "/o /a /s /x /d $ExtractPath" -PassThru -Wait
    Write-Host "Files have been extracted."
} catch {
    Write-Host "An exception was caught: $($_.Exception.Message)"
    $_.Exception.Response
    Break
}

Write-Host "Running setup.exe in silent mode"

try {
    Start-Process -FilePath "$ExtractPath\Adobe Acrobat\Setup.exe" -ArgumentList "/sALL" -Wait
    Write-Host "Setup have been completed"
} catch {
    Write-Host "An exception was caught: $($_.Exception.Message)"
    $_.Exception.Response
    Break
}

$Status = (Get-Package * | Where-Object {$_.Tagid -eq "AC76BA86-1033-FFFF-7760-0C0F074E4100"} | Select-Object -Property Status).Status

If ($Status -eq "Installed") {
    Write-Host "Adobe Reader DC PRO setup has been successully completed"
} else {
    Write-Host "Looks like something went wrong during installation process. Please investigate"
    Break
}

Write-Host "Cleaning up..."

try {
    Remove-Item -Path "$ExtractPath\" -Recurse -Force -ErrorAction Continue
    Remove-Item -Path "$Path\Acrobat_DC_Web_WWMUI.exe" -Force -ErrorAction Continue
} catch {
    Write-Host "An exception was caught: $($_.Exception.Message)"
    $_.Exception.Response
}

