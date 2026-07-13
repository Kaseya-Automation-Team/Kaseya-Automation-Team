function Get-VSATicket
{
    <#
    .SYNOPSIS
       Returns Tickets from a VSA environment.
    .DESCRIPTION
       Retrieves tickets from a VSA environment.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies an existing non-persistent VSAConnection object.
    .PARAMETER URISuffix
        Specifies the URI suffix if it differs from the default.
    .PARAMETER TicketID
        Specifies the TicketId to return. All Tickets are returned if no TicketId is specified.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSATicket
    .EXAMPLE
       Get-VSATicket -TicketId '10001' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection.
    .OUTPUTS
       Array of objects that represent ticket data.
    #>
    [CmdletBinding(DefaultParameterSetName='All')]
    param (

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'All')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false,

            ParameterSetName = 'All')]
        [parameter(DontShow, Mandatory = $false,

            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/automation/tickets',

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [string] $TicketId,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [string] $Sort
    )
    process {

    if( -not [string]::IsNullOrEmpty($TicketId)) {
        $URISuffix = "{0}/{1}" -f $URISuffix, $TicketId
    }

    [hashtable]$Params = @{
        URISuffix = $URISuffix
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    #region messages to verbose and debug streams
    "Get-VSATicket: $($Params | Out-String)" | Write-Debug

    "Get-VSATicket: $($Params | Out-String)" | Write-Verbose

    #endregion messages to verbose and debug streams

    # No -TicketId  -> GET /automation/tickets returns the TicketSummary list (5 fields) in one call.
    # With -TicketId -> GET /automation/tickets/{id} returns the full Ticket (17 fields).
    # Previously the no-id path fanned out one GET per ticket (N+1) to full-expand every row; that is
    # removed (F-9/D-1). Callers who need full detail pass the summary's TicketId back to
    # Get-VSATicket -TicketId (the list has no bulk-detail endpoint on the API).
    return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Get-VSATicket
