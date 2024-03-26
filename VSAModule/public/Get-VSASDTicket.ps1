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
       Get-VSASDTicket -ServiceDeskId 3434343
    .EXAMPLE
       Get-VSASDTicket -VSAConnection $connection -ServiceDeskId 3434343
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of items that represent service desk tickets or ticket details
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NonPersistent')]
        [VSAConnection] $VSAConnection,
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/automation/servicedesks/{0}/tickets',
        [ValidateNotNullOrEmpty()]
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $ServiceDeskId,
        [ValidateNotNullOrEmpty()]
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $ServiceDeskTicketId,         
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    if( -not [string]::IsNullOrWhiteSpace( $ServiceDeskTicketId) ) {
        $URISuffix = "api/v1.0/automation/servicedesktickets/$ServiceDeskTicketId"

        if ($ServiceDeskId) { Write-Error "ServiceDeskId can not be specified at same time with ServiceDeskTicketId"}

    } else {
        $URISuffix = $URISuffix -f $ServiceDeskId
    }

    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Paging)        {$Params.Add('Paging', $Paging)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    return Get-VSAItems @Params
}

Export-ModuleMember -Function Get-VSASDTicket