function Get-VSAPatchMissing {
    <#
    .Synopsis
       Returns an array of missing patches.
    .DESCRIPTION
       Returns an array of missing patches on an agent machine, with denied patches either included or excluded.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies id of agent machine.
    .EXAMPLE
       Get-VSAPatchMissing -AgentId 979868787875855
    .EXAMPLE
       Get-VSAPatchMissing -AgentId 979868787875855 -HideDeniedPatches
    .EXAMPLE
       Get-VSAPatchMissing -VSAConnection $connection -AgentId 979868787875855
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of items that represent missing patches
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/patch/{0}/machineupdate/{1}',

        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentID,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort,

        [Parameter(Mandatory = $false)]
        [switch] $HideDeniedPatches
    )

    [hashtable]$Params = @{
        URISuffix     = $( $URISuffix -f $AgentID, $HideDeniedPatches.ToString() )
        VSAConnection = $VSAConnection
        Filter        = $Filter
        Paging        = $Paging
        Sort          = $Sort
    }

    foreach ( $key in $Params.Keys.Clone()  ) {
        if ( -not $Params[$key]) { $Params.Remove($key) }
    }

    return Invoke-VSARestMethod @Params
}
New-Alias -Name Get-VSAMissingPatches -Value Get-VSAPatchMissing
Export-ModuleMember -Function Get-VSAPatchMissing -Alias Get-VSAMissingPatches