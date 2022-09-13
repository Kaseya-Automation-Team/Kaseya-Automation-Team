<#
.Synopsis
    Adds computers to the AD group.
.DESCRIPTION
    Adds computers from the provided text file with names of the AD computers to the AD group provided.
.PARAMETERS
    [string] GroupIdentity
        - The AD Group identity
    [string] FileName
        - Name of the file with computer names (a name per line)
		 
.EXAMPLE
    .\Add-ComputersToADGroup.ps1 -GroupIdentity 'YourADGroupName' -FileName 'ComputerList.txt'
.NOTES
    Version 0.1
    Requires: 
        Permissions for adding objects to AD groups
        Execute the script from a Domain Controller or on a client with the RSAT installed
   
    Author: Proserv Team - VS

#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $GroupIdentity,

    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if( -Not ($_ | Test-Path -PathType leaf ) ){
            throw "The file `"$_`" not found"
        }
        return $true
    })]
    [System.IO.FileInfo]$FileName
)

[string] $ModuleName = 'ActiveDirectory'
$ComputerList = Get-Content -Path $FileName

if ( $null -ne $(try {Get-Module -Name $ModuleName -ErrorAction Stop} catch {$null}) ) {
    Import-Module -Name $ModuleName
    $TheGroup = try {
            Get-ADGroup -Identity $GroupIdentity -ErrorAction Stop
        } catch {
            Write-Host "AD Group <$GroupIdentity>" -NoNewline; Write-Host " not found" -ForegroundColor Red
            $null
        }
    if ( $null -ne $TheGroup) {
        foreach ($ComputerIdentity in $ComputerList)
        {
            if ( -not [string]::IsNullOrEmpty($ComputerIdentity)) {
                $TheComputer = try {
                    Get-ADComputer -Identity $ComputerIdentity -ErrorAction Stop
                } catch {
                    Write-Host "AD Computer <$ComputerIdentity>" -NoNewline; Write-Host " not found" -ForegroundColor Red
                    $null
                }
                if ( $null -ne $TheComputer ) {
                    Write-Host "Adding Computer <" -NoNewline; Write-Host "$ComputerIdentity" -ForegroundColor Green  -NoNewline; Write-Host "> to group $TheGroup"
                    Add-ADGroupMember -Identity $TheGroup -Members $TheComputer
                }
            }
        }
    }
} else {
    Write-Host "The Module $ModuleName"  -NoNewline; Write-Host " not found" -ForegroundColor Red
}