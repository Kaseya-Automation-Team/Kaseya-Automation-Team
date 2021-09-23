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
    .PARAMETER OrganizationId
        Specifies the Organization Id.
    .PARAMETER MachineGroupId
        Specifies the Machine Group Id.
    .PARAMETER UserId
        Specifies the User Id.
    .PARAMETER ScopeId
        Specifies the Scope Id.
    .EXAMPLE
       Add-VSAItemToScope -MachineGroupId 10001 -ScopeId 20002
    .EXAMPLE
       Add-VSAItemToScope -MachineGroupId 10001 -OrganizationId 20002
    .EXAMPLE
       Add-VSAItemToScope -MachineGroupId 10001 -UserId 20002
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
            ValueFromPipelineByPropertyName=$true, 
            ParameterSetName = 'MachineGroup')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true, 
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

    [string] $ItemId

    if( -not [string]::IsNullOrEmpty($OrganizationID)) {
        $URISuffix = "$URISuffix/orgs/{1}"
        $ItemId = $OrganizationID
        "Add an organization to a scope" | Write-Verbose
    }

    if( -not [string]::IsNullOrEmpty($MachineGroupId)) {
        $URISuffix = "$URISuffix/machinegroups/{1}"
        $ItemId = $MachineGroupId
        "Add a machine group to a scope" | Write-Verbose
    }

    if( -not [string]::IsNullOrEmpty($UserId)) {
        $URISuffix = "$URISuffix/users/{1}"
        $ItemId = $UserId
        "Add a user to a scope" | Write-Verbose
    }

    $URISuffix = $URISuffix -f $ScopeId, $ItemId
    $URISuffix | Write-Verbose
    $URISuffix | Write-Debug

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    $Params.Add('Method', 'PUT')

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Add-VSAItemToScope

