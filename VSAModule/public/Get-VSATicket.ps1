function Get-VSATicket {
    <#
    .Synopsis
       Returns an array of ticketing tickets or details on specified ticket.
    .DESCRIPTION
       Returns an array of ticketing tickets or details on specified ticket.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TicketId
        Specifies id of ticket.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSATicket
    .EXAMPLE
       Get-VSATicket -VSAConnection $connection -TicketId 123456
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of items that represent ticketing tickets or ticket details
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/automation/tickets',

        [Alias('ID')]
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ([string]::IsNullOrWhiteSpace($_)) { throw "TicketId cannot be empty." }
            if ($_ -notmatch "^\d+$") { throw "TicketId must be a numeric string." }
            return $true
        })]
        [string] $TicketId,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Paging,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Sort
    )

    # Set URI based on input
    if (-not [string]::IsNullOrWhiteSpace($TicketId)) {
        $URISuffix = "{0}/{1}" -f $URISuffix, $TicketId
    }

    # Build parameters
    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Filter        = $Filter
        Paging        = $Paging
        Sort          = $Sort
    }

    # Remove empty keys
    foreach ($key in $Params.Keys.Clone()) {
        if (-not $Params[$key]) { $Params.Remove($key) }
    }

    # Sanitize inputs to prevent injection
    foreach ($key in @('Filter', 'Paging', 'Sort')) {
        if ($Params[$key]) {
            $Params[$key] = $Params[$key] -replace '[<>;]', ''
        }
    }

    Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Get-VSATicket