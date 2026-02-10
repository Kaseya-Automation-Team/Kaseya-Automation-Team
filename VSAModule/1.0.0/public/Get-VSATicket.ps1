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
    .PARAMETER Paging
        Specifies REST API Paging.
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
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'All')]
        [parameter(DontShow, Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true,
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
        [string] $Paging,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    if( -not [string]::IsNullOrEmpty($TicketId)) {
        $URISuffix = "{0}/{1}" -f $URISuffix, $TicketId
    }

    [hashtable]$Params = @{
        URISuffix = $URISuffix
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Paging)        {$Params.Add('Paging', $Paging)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    #region messages to verbose and debug streams
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "Get-VSATicket: $($Params | Out-String)" | Write-Debug
    }
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        "Get-VSATicket: $($Params | Out-String)" | Write-Verbose
    }
    #endregion messages to verbose and debug streams
    $TicketData = New-Object System.Collections.ArrayList
    if ([string]::IsNullOrEmpty($TicketId)) {
        $ParamsCloned = $Params.Clone()
        $AllTickets = Invoke-VSARestMethod @Params
        Foreach ($Ticket in $AllTickets) {
            $ParamsCloned['URISuffix'] = "{0}/{1}" -f $URISuffix, $Ticket.TicketId
            $TicketData.Add( $(Invoke-VSARestMethod @ParamsCloned) ) | Out-Null
        }
    } else {
        $TicketData.Add( $(Invoke-VSARestMethod @Params) ) | Out-Null
    }

    return $TicketData.ToArray()
}
Export-ModuleMember -Function Get-VSATicket