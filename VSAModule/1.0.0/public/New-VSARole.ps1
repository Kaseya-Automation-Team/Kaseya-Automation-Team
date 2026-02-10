function New-VSARole
{
    <#
    .Synopsis
       Adds a new user role
    .DESCRIPTION
       Adds a new user role in VSA with specified role type Ids
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER RoleName
        Specifies name of the role
    .PARAMETER RoleTypeIds
        Specifies array of role type ids
    .EXAMPLE
       New-VSARole -RoleName "Remote desktop" -RoleTypeIds 4, 6, 100, 101
    .EXAMPLE
       New-VSARole -VSAConnection $connection -RoleName "Remote desktop" -RoleTypeIds 4, 6, 100, 101
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/roles',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $RoleName,

		[parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( 0 -ge $_.Count ) {
                throw 'No value provided for RoleTypeIds'
            }
            return $true
        })]
        [string[]] $RoleTypeIds,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $Attributes
)
    
    [hashtable]$BodyHT = @{ RoleName = $RoleName }

    $BodyHT.Add('RoleTypeIds', $RoleTypeIds )

    if ( -not [string]::IsNullOrEmpty($Attributes) ) {
        [hashtable] $AttributesHT = ConvertFrom-StringData -StringData $Attributes
        $BodyHT.Add('Attributes', $AttributesHT )
    }

    $Body = $BodyHT | ConvertTo-Json
    $Body | Write-Debug

    [hashtable]$Params =@{
        URISuffix      = $URISuffix
        Method         = 'POST'
        Body           = $Body
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "New-VSARole: $($Params | Out-String)"
    }
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        Write-Verbose "New-VSARole: $($Params | Out-String)"
    }


    if( $PSCmdlet.ShouldProcess( $RoleName ) ) {

        $Result = Invoke-VSARestMethod @Params

        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug "New-VSARole: $($Result| Out-String)"
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            Write-Verbose "New-VSARole: $($Result| Out-String)"
        }
    }
    return $Result
}

New-Alias -Name Add-VSARole -Value New-VSARole
Export-ModuleMember -Function New-VSARole -Alias Add-VSARole