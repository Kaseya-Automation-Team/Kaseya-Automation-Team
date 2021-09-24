function Get-VSAUser
{
    <#
    .Synopsis
       Returns VSA users
    .DESCRIPTION
       Returns existing VSA users.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER UserId
        Specifies User Id. Returns all users if no User ID specified
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .PARAMETER ResolveIDs
        Return Roles & Scopes as well as their respective IDs.
    .EXAMPLE
       Get-VSAUser
    .EXAMPLE
       Get-VSAUser -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent existing VSA users
    #>
    [CmdletBinding(DefaultParameterSetName = 'Users')]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'CurrentUser')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Users')]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'CurrentUser')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Users')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/users',

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Users')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $UserId,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'CurrentUser')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Users')]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'CurrentUser')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Users')]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'CurrentUser')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Users')]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Users')]
        [switch] $ResolveIDs,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'CurrentUser')]
        [switch] $CurrentUser
    )

    if( -not [string]::IsNullOrWhiteSpace($UserId) ) {
        $URISuffix += "/$UserId"
    }
    if ($CurrentUser) {$URISuffix = 'api/v1.0/system/currentUser'}

    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Paging)        {$Params.Add('Paging', $Paging)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    $result = Get-VSAItems @Params

    if ($ResolveIDs)
    {
        [hashtable]$ResolveParams =@{}
        if($VSAConnection) {$ResolveParams.Add('VSAConnection', $VSAConnection)}

        [hashtable]$RolesDictionary = @{}
        [hashtable]$ScopesDictionary = @{}

        Foreach( $Role in $(Get-VSARoles @ResolveParams -ResolveIDs) )
        {
            if ( -Not $RolesDictionary[$Role.RoleId]){
                $RolesDictionary.Add($Role.RoleId, $($Role | Select-Object * -ExcludeProperty RoleId))
            }
        }

        Foreach( $Scope in $(Get-VSAScope @ResolveParams) )
        {
            if ( -Not $ScopesDictionary[$Scope.ScopeId]){
                $ScopesDictionary.Add($Scope.ScopeId, $Scope.ScopeName)
            }
        }
        $result = $result | Select-Object -Property *, `
            @{Name = 'AdminRoles'; Expression = { $RolesDictionary[$_.AdminRoleIds] }},
            @{Name = 'AdminScopes'; Expression = { $ScopesDictionary[$_.AdminScopeIds] }}
    }

    return $result
}
Export-ModuleMember -Function Get-VSAUser