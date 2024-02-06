function New-VSAScope
{
    <#
    .Synopsis
       Creates a new scope.
    .DESCRIPTION
       Creates a new VSA scope.
    .PARAMETER VSAConnection
        Specifies an established VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ScopeName
        Specifies the Scope Name.
    .EXAMPLE
       Add-VSAScope -ScopeName 'ANewScope' -VSAConnection $connection
    .INPUTS
       Accepts piped established VSAConnection
    .OUTPUTS
       True if creation was successful.
    .NOTES
        Version 0.1.1
    #>
    [alias("Add-VSAScope")]
    [CmdletBinding(SupportsShouldProcess)]
    param ( 
        [parameter(Mandatory = $true, 
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
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Method        = 'POST'
        Body          = $Body
    }

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "New-VSAScope. Request Params`:$($Params | Out-String)"
    }
    

    if( $PSCmdlet.ShouldProcess( $ScopeName ) ) {

        $Result = Invoke-VSARestMethod @Params

        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            $Result | Out-String | Write-Debug
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            $Result | Out-String | Write-Verbose
        }

        return $Result
    }
}
Export-ModuleMember -Function New-VSAScope