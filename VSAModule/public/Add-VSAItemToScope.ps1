function Add-VSAItemToScope
{
    <#
    .Synopsis
       Adds a VSA item to a scope.
    .DESCRIPTION
       Adds an existing machine group, organization or user to an existing scope.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ScopeId
        Specifies the Scope Id to which a VSA item is added.
    .PARAMETER MachineGroupId
        Specifies the Machine Group Id.
        Not Compatible with -OrganizationId, -UserId parameters.
    .PARAMETER OrganizationId
        Specifies the Organization Id.
        Not Compatible with -UserId, -MachineGroupId parameters.
    .PARAMETER UserId
        Specifies the User Id.
        Not Compatible with -OrganizationId, -MachineGroupId parameters.
    .EXAMPLE
       Add-VSAItemToScope -ScopeId 10001 -MachineGroupId 20002
    .EXAMPLE
       Add-VSAItemToScope -ScopeId 10001 -OrganizationId 20002
    .EXAMPLE
       Add-VSAItemToScope -ScopeId 10001 -UserId 20002
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if addition was successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'MachineGroup')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'User')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
             
            ParameterSetName = 'MachineGroup')]
        [parameter(Mandatory = $false, 
             
            ParameterSetName = 'Organization')]
        [parameter(Mandatory = $false, 
             
            ParameterSetName = 'User')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/scopes/{0}',

        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $OrganizationId,

        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'MachineGroup')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $MachineGroupId,

        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'User')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $UserId,

        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'MachineGroup')]
        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'User')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $ScopeId
    )

    $ItemId = [string]::Empty

    [string] $LogStr = 'Add-VSAItemToScope: '

    if( -not [string]::IsNullOrEmpty($OrganizationID) ) {
        $URISuffix = "$URISuffix/orgs/{1}"
        $ItemId = $OrganizationID
        $LogStr += "Adding Organization '$ItemId' to Scope '$ScopeId'"
    }

    if( -not [string]::IsNullOrEmpty($MachineGroupId) ) {
        $URISuffix = "$URISuffix/machinegroups/{1}"
        $ItemId = $MachineGroupId
        $LogStr += "Adding Machine Group '$ItemId' to Scope '$ScopeId'"
    }

    if( -not [string]::IsNullOrEmpty($UserId) ) {
        $URISuffix = "$URISuffix/users/{1}"
        $ItemId = $UserId
        $LogStr += "Adding User '$ItemId' to Scope '$ScopeId'"
    }

    return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($($URISuffix -f $ScopeId, $ItemId)) -VSAConnection $VSAConnection
}
Export-ModuleMember -Function Add-VSAItemToScope