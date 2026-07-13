function Get-VSAOrgNetwork
{
    <#
    .Synopsis
       Retrieves networks for one or more organizations.
    .DESCRIPTION
       Retrieves the Discovery networks belonging to the specified organizations. This endpoint is a
       POST that takes an array of organization ids and returns data, so it is not gated by ShouldProcess.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER OrgId
        Specifies one or more organization ids.
    .EXAMPLE
       Get-VSAOrgNetwork -OrgId 10001
    .EXAMPLE
       Get-VSAOrgNetwork -OrgId 10001, 10002
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       Array of organization networks.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/system/orgs/networksbyorg',

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            foreach ($id in $_) { if ($id -notmatch "^\d+$") { throw "Non-numeric Id" } }
            return $true
        })]
        [string[]] $OrgId
    )
    process {
        [string] $Body = ConvertTo-Json -InputObject @($OrgId) -Depth 5
        return Invoke-VSAWriteRequest -Body $Body -Method POST -URISuffix $URISuffix -VSAConnection $VSAConnection
    }
}
Export-ModuleMember -Function Get-VSAOrgNetwork
