<#
.Synopsis
   Gathers Antivirus Information.
.NOTES
   Version 0.1
   Author: Proserv Team - VS
   requires -version 5.1
#>

#Create VSA Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

Function ConvertTo-Hex {
    Param([int]$Number)
    '0x{0:x}' -f $Number
}

[string] $Results = ''
[Array] $AntivirusProducts = Try {
                                    Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName "Antivirusproduct" -ErrorAction Stop
                             } Catch {
                                [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Gathering Antivirus Information Error: $($_.Exception.Message)", 400)
                                $null
                             }

if ( $AntivirusProducts ) {

    foreach ( $AV in $AntivirusProducts ) {

        [string] $ProductStateHex = ConvertTo-Hex $AV.ProductState
        $Middle = $ProductStateHex.Substring( 3, 2 )

        if ($Middle -notmatch "00|01") {
            $State = 'Enabled'
        } else {
            $State = 'Disabled'
        }

        $Tail = $ProductStateHex.Substring(5)

        if ( '00' -eq $Tail) {
            $UpToDate = 'Up to date'
        } else {
            $UpToDate = 'Outdated'
        }
        if ( -not [string]::IsNullOrEmpty( $($AV.Displayname) ) ) {
            $AVString = @( "Antivirus: $($AV.Displayname)", $State, $UpToDate, "Last updated: $($AV.Timestamp)") -join ", "
            if ( -not [string]::IsNullOrEmpty( $Results ) ) {
                $Results += ";`t"
            }
            $Results += $AVString
        }
        
    }
    Start-Process -FilePath "$env:PWY_HOME\CLI.exe" -ArgumentList ("setVariable AVInfo ""$Results""") -Wait
}