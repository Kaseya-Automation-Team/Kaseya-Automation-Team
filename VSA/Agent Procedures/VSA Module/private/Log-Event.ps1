function Log-Event {
    <#
    .Synopsis
        Logs the module's commandlets informationin the Application event log.
    .DESCRIPTION
        Creates entries in the Application event log that for the VSA Module commandlets.
    .PARAMETER Msg
        Message body.
    .PARAMETER Id
        The event Id.
    .PARAMETER Type
        Log entry type.
    #>
    param(        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Msg,
        [Parameter(Mandatory=$true)][Int]$Id,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        [String]$Type
    )

    #Check if log source alread exists
    [string] $TheSource = "VSAModule"
    [bool]   $SourceExists = try { [System.Diagnostics.EventLog]::SourceExists($TheSource) } catch {$false}

    #If not, create a new one
    if ( -Not $SourceExists ) {
        New-EventLog -LogName Application -Source $TheSource
    }

    Write-EventLog -LogName Application -Source $TheSource -EntryType $Type -EventID $Id -Message $Msg -Category 0
    #$CurrentTime = Get-Date
    #Write-Host "$CurrentTime`: $Type`: $Msg"
}