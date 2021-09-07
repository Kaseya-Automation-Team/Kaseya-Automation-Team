function Log-Event {
    <#
    .Synopsis
       Logs the module's commandlets information.
    .DESCRIPTION
    #>
    param(        
        [Parameter(Mandatory=$true)][String]$Msg,
        [Parameter(Mandatory=$true)][Int]$Id,
        [Parameter(Mandatory=$true)][String]$Type
    )

    #Check if log source alread exists
    $SourceExists = [System.Diagnostics.EventLog]::SourceExists("VSA API Module")

    #If not, create a new one
    if ($SourceExists -eq $false) {
        New-EventLog –LogName Application –Source “VSA API Module”
    }

    Write-EventLog –LogName Application –Source “VSA API Module” –EntryType $Type –EventID $Id  –Message $Msg -Category 0
    $CurrentTime = Get-Date
    Write-Host "$CurrentTime`: $Type`: $Msg"
}