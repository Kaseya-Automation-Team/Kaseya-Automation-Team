<#
=================================================================================
Script Name:        Audit: Get Windows Version Number.
Description:        Retrieves the build number (10763) and converts it to 21H1.
Lastest version:    2022-09-20
=================================================================================



Required variable inputs:
None



Required variable outputs:
WindowsBuildNumber
#>
# Outputs
$WindowsBuildNumber = "Not Scanned"
$WindowsBuildNumber = (Get-Item 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion').GetValue('ReleaseID')

Start-Process -FilePath "$env:PWY_HOME\CLI.exe" -ArgumentList ("setVariable WindowsBuildNumber ""$WindowsBuildNumber""") -Wait

