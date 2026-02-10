function Get-VSASDTicket {
    <#
    .Synopsis
       Returns an array of tickets or specified service desk or details on specified ticket.
    .DESCRIPTION
       Returns an array of tickets or specified service desk or details on specified ticket.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ServiceDeskId
        Specifies id of service desk
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSASDTicket -ServiceDeskId 123456
    .EXAMPLE
       Get-VSASDTicket -VSAConnection $connection -ServiceDeskId 123456
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of items that represent service desk tickets or ticket details
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [Alias('ID')]
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ([string]::IsNullOrWhiteSpace($_)) { throw "ServiceDeskId cannot be empty." }
            if ($_ -notmatch "^\d+$") { throw "ServiceDeskId must be a numeric string." }
            return $true
        })]
        [string] $ServiceDeskId,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ([string]::IsNullOrWhiteSpace($_)) { throw "ServiceDeskTicketId cannot be empty." }
            if ($_ -notmatch "^\d+$") { throw "ServiceDeskTicketId must be a numeric string." }
            return $true
        })]
        [string] $ServiceDeskTicketId,

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

    # Ensure exactly one of ServiceDeskId or ServiceDeskTicketId is provided
    if ([string]::IsNullOrWhiteSpace($ServiceDeskId) -eq [string]::IsNullOrWhiteSpace($ServiceDeskTicketId)) {
        throw "Exactly one of ServiceDeskId or ServiceDeskTicketId parameters must be provided."
    }

    # Set URI based on input
    $URISuffix = if ($ServiceDeskTicketId) {
        "api/v1.0/automation/servicedesktickets/$ServiceDeskTicketId"
    } else {
        "api/v1.0/automation/servicedesks/$ServiceDeskId/tickets"
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

Export-ModuleMember -Function Get-VSASDTicket