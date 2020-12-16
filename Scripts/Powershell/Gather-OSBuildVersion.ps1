<#
.Synopsis
   Gathers OS Version and build to a csv-file
.DESCRIPTION
   Gathers OS Version and build to a csv-file
.EXAMPLE
   .\Gather-OSBuildVersion.ps1 -FileName 'os_and_build.csv' -Path 'C:\TEMP' -AgentName '123456'
.NOTES
   Version 0.1
   Author: Vladislav Semko
   Email: Vladislav.Semko@kaseya.com
#>

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    [parameter(Mandatory=$true)]
    [string]$FileName,
    [parameter(Mandatory=$true)]
    [string]$Path
 )

[string]$currentDate = Get-Date -UFormat "%m/%d/%Y %T"
if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

[string[]]$Props = @('Caption', 'Version', 'BuildNumber', 'OSArchitecture')
Get-CimInstance Win32_OperatingSystem -Property $Props | Select-Object $Props | Select-Object -Property `
@{Name = 'Date'; Expression = {$currentDate }}, `
@{Name = 'AgentGuid'; Expression = {$AgentName}}, `
@{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}} , `
@{Name = 'OSType'; Expression= {$_.Caption}} , `
@{Name = 'Version'; Expression= {$_.Version}} , `
@{Name = 'BuildNumber'; Expression= {$_.BuildNumber}} , `
@{Name = 'OSArchitecture'; Expression= {$_.OSArchitecture}} `
| Export-Csv -Path "FileSystem::$FileName"-Force -Encoding UTF8 -NoTypeInformation