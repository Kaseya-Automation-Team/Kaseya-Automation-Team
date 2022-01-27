<#
.Synopsis
   Gathers Antivirus Information.
.DESCRIPTION
   Gathers Antivirus Information.
   Used by the "Gather AV Info" Agent Procedure
.EXAMPLE
   .\Gather-AVInfo.ps1
.NOTES
   Version 0.1
   Author: Proserv Team - VS
   requires -version 5.1
#>

param (
    [parameter(Mandatory=$false)]
    [int]$LogIt = 0
)

[string]$Pref = "Continue"
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $LogFile = "$Path\$ScriptName.log"
    Start-Transcript -Path $LogFile
}

Function ConvertTo-Hex {
    Param([int]$Number)
    '0x{0:x}' -f $Number
}

[Array] $Results = @()
[Array] $AntivirusProducts = Try {
                                    Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName "Antivirusproduct" -ErrorAction Stop
                             } Catch {
                                Write-Verbose "$($_.Exception.Message)"
                                $null
                             }

if ( $AntivirusProducts ) {

    foreach ( $AV in $AntivirusProducts ) {

        [string] $ProductStateHex = ConvertTo-Hex $AV.ProductState
        $Middle = $ProductStateHex.Substring( 3, 2 )

        if ($Middle -notmatch "00|01") {
            $Enabled = $True
        }
        else {
            $Enabled = $False
        }

        $Tail = $ProductStateHex.Substring(5)

        if ( '00' -eq $Tail) {
            $UpToDate = $True
        }
        else {
            $UpToDate = $False
        }

        $Results += $AV | Select-Object @{Name = "Antivirus Product"; Expression = { $_.Displayname } },
        @{Name = "Enabled"; Expression = { $Enabled } },
        @{Name = "UpToDate"; Expression = { $UptoDate } },
        @{Name = "Last Updated"; Expression = { $_.Timestamp } }
    } 
    $Results | Out-String | Write-Output
}

if (1 -eq $LogIt)
{
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}