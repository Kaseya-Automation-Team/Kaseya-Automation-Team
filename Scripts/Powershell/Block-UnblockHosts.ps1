<#
.Synopsis
   Check if some website is blocked
.DESCRIPTION
   Script check if Windows hosts file contains entries for domain names supplied in text file (blocked.txt).
   Also, if special switch has been passed, script can add entries for domain names from text file, to point them to 127.0.0.1,
   i.e. block them or to delete records from hosts file, which are equal with records in text file
.EXAMPLE
   .\Block-UnblockHosts.ps1 -Blacklist "c"\kworking\system\blacklist.txt"
   .\Block-UnblockHosts.ps1 -Blacklist "c"\kworking\system\blacklist.txt" -Add
   .\Block-UnblockHosts.ps1 -Blacklist "c"\kworking\system\blacklist.txt" -Remove
.NOTES
   Version 0.1
   Author: Aliaksandr Serzhankou
   Email: a.serzhankou@kaseya.com
#>

#Read input parameters and switches
param (
    [parameter(Mandatory=$true)]
    [string[]]$BlackList = "",
    [switch]$Add,
    [switch]$Remove
 )

#Buffering content of text file
$BlackList = Get-Content "$BlackList"
#Buffer content on hosts file
$Path = "$env:windir\System32\Drivers\etc\hosts"
$HostsFile = Get-Content $Path

#Create empty arrays, to store missing and records to add in them
$Results = @()
$EntriesToApply = @()

#Check if hosts file contains records from text file and if they are pointed to 127.0.0.1 ip address
foreach($HostName in $BlackList) {
    if (($HostsFile -match $HostName) -and ($HostsFile -match "127.0.0.1")) {
    } else {
        $Results += "`r`n$HostName"
        #If -Add switch has been passed to the script, write only missing entries to hosts file
        if ($Add) {
            $EntriesToApply += "127.0.0.1`t$HostName"
        }

    }
}

#Display missing records from array to console
if ($Results) {
    Write-Host "Following records are missing in hosts file:"
    Write-Host $Results
}

#If we have any entries to add in array, put them into hosts file
if ($EntriesToApply) {
    $EntriesToApply = ,"`r`n#These records have been generated automatically by VSA agent procedure" + $EntriesToApply
    Add-Content $Path $EntriesToApply
    Write-Host "`r`nAll missing records have been added successfully."
}

#If we have -Remove switch passed to the script, write hosts file to itself, but filtered domain names from text file
if ($Remove) {
    foreach($HostName in $BlackList) {
        $HostsFile = Get-Content $Path
        $escapedHostname = [Regex]::Escape($HostName)
        $HostsFile -notmatch ".*\s+$escapedHostname.*" | Out-File $Path
        Write-Host "Attempted to remove domain name $HostName from hosts file"
    }
}