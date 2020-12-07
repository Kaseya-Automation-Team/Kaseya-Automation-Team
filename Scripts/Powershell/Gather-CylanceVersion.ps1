<#
.Synopsis
   Gets version of Cylance Smart Antivirus
.DESCRIPTION
   Script collects information about Cylance Smart Antivirus - if it's installed, what version. All this info exported to CSV file.
.EXAMPLE
   .\Gather-CylanceVersion.ps1 

.NOTES
   Version 0.1
   Author: Aliaksandr Serzhankou
   Email: a.serzhankou@kaseya.com
#>

#Read input parameters
param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
    [string]$FileName = "",
    [parameter(Mandatory=$true)]
    [string]$Path = ""
 )

#Create new object for export purposes
$Output = New-Object psobject

Add-Member -InputObject $Output -MemberType NoteProperty -Name AgentGuid -Value $AgentName

#Check if software is installed
$isInstalled = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*) | Where-Object {$_.DisplayName -like "*cylance*"}

if ($isInstalled) {
    #If it's installed, add installed and version properties to an object
    Add-Member -InputObject $Output -TypeName Installed -MemberType NoteProperty -Name Installed -Value "True"
    Add-Member -InputObject $Output -TypeName Version -MemberType NoteProperty -Name Version -Value $isInstalled.DisplayVersion
}
 else {
    #If not installed, set values to False
    Add-Member -InputObject $Output -TypeName Installed -MemberType NoteProperty -Name Installed -Value "False"
    Add-Member -InputObject $Output -TypeName Version -MemberType NoteProperty -Name Version -Value "False"
}

#Export results to csv file
Export-Csv -Path $Path\$FileName -InputObject $Output -NoTypeInformation -Encoding UTF8