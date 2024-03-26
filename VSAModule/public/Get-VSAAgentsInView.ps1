function Get-VSAAgentsInView {
    <#
    .Synopsis
       Returns an array of agent records in the selected view
    .DESCRIPTION
       Returns an array of agent records in the selected view.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ViewId
        Specifies id of system view.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSAAgentsInView -ViewId 3423232
    .EXAMPLE
       Get-VSAAgentsInViews -VSAConnection $connection -ViewId 3423232424
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of custom objects that represent agents within specified system view
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
        [string] $URISuffix = 'api/v1.0/assetmgmt/agentsinview/{0}',
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $ViewId,
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

    $URISuffix = $URISuffix -f $ViewId
    
    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Paging)        {$Params.Add('Paging', $Paging)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    return Get-VSAItems @Params
}

Export-ModuleMember -Function Get-VSAAgentsInView