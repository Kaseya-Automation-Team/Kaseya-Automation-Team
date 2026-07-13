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

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/system/scopes',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ScopeName,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        # Accepts a [hashtable]/[pscustomobject] (preferred) or the legacy "Key=value" string.
        [object] $Attributes
    )
    process {

    [hashtable]$BodyHT = @{'ScopeName'= $ScopeName }

    if ( $null -ne $Attributes ) {
        [hashtable] $AttributesHT = ConvertTo-VSAHashtable $Attributes
        if ( 0 -lt $AttributesHT.Count ) { $BodyHT.Add('Attributes', $AttributesHT ) }
    }
    $Body = $BodyHT | ConvertTo-Json

    if( $PSCmdlet.ShouldProcess( $ScopeName ) ) {
        return Invoke-VSAWriteRequest -Body $Body -Method POST -URISuffix $URISuffix -VSAConnection $VSAConnection
    }
    }
}
New-Alias -Name Add-VSAScope -Value New-VSAScope
Export-ModuleMember -Function New-VSAScope -Alias Add-VSAScope
