function New-VSAScope
{
    <#
    .Synopsis
       Creates a new scope.
    .DESCRIPTION
       Creates a new VSA scope.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ScopeName
        Specifies the Scope Name.
    .EXAMPLE
       New-VSAScope -ScopeName 'NewScope'
    .EXAMPLE
       New-VSAScope -ScopeName 'NewScope' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if creation was successful.
    .NOTES
        Version 1.0.0
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/scopes',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ScopeName,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $Attributes
    )

    [hashtable]$BodyHT = @{'ScopeName'= $ScopeName }

    if ( -not [string]::IsNullOrEmpty($Attributes) ) {
        [hashtable] $AttributesHT = ConvertFrom-StringData -StringData $Attributes
        $BodyHT.Add('Attributes', $AttributesHT )
    }
    $Body = $BodyHT | ConvertTo-Json

    [hashtable]$Params =@{
        VSAConnection  = $VSAConnection
        URISuffix      = $URISuffix
        Method         = 'POST'
        Body           = $Body
    }

    #Remove empty keys
    foreach ( $key in $Params.Keys.Clone() ) {
        if ( -not $Params[$key] )  { $Params.Remove($key) }
    }

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "New-VSAScope. Request Params`:$($Params | Out-String)"
    }

    if( $PSCmdlet.ShouldProcess( $ScopeName ) ) {
        return Invoke-VSARestMethod @Params
    }
}
New-Alias -Name Add-VSAScope -Value New-VSAScope
Export-ModuleMember -Function New-VSAScope -Alias Add-VSAScope
