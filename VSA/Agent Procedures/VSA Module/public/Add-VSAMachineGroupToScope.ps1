function Add-VSAMachineGroupToScope
{
    <#
    .Synopsis
       Adds a machine group to a scope.
    .DESCRIPTION
       Adds an existing machine group to an existing scope.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER MachineGroupId
        Specifies the Machine Group Id.
    .PARAMETER ScopeId
        Specifies the Scope Id.
    .EXAMPLE
       Add-VSAMachineGroupToScope -MachineGroupId 10001 -ScopeId 20002
    .EXAMPLE
       Add-VSAMachineGroupToScope -MachineGroupId 10001 -ScopeId 20002 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if addition was successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/scopes/{0}/machinegroups/{1}',

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $MachineGroupId,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $ScopeId
    )

    $URISuffix = $URISuffix -f $ScopeId, $MachineGroupId

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    $Params.Add('Method', 'PUT')

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Add-VSAMachineGroupToScope