function Update-VSAInfoMsg
{
    <#
    .Synopsis
       Sets the IsRead field on messages.
    .DESCRIPTION
       Switches if the specified messages are read.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Reason
        Optional parameter which specifies reason why alarm has been closed
    .EXAMPLE
       Update-VSAInfoMsg -ID 1, 2, 3 -IsRead
    .EXAMPLE
       Update-VSAInfoMsg -ID 1, 2, 3 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if update was successful
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = "api/v1.0/infocenter/messages/{0}",

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            foreach ($item in $_) {
                if ( -not [decimal]::TryParse($item, [ref]$null) ) {
                    throw "All elements must be numeric. '$item' is not a valid number."
                }
            }
            return $true
        })]
        [decimal[]] $ID,

        [switch] $IsRead
    )
    process {

    return Invoke-VSAWriteRequest -Body ($( $ID | ConvertTo-Json -Compress )) -Method 'PUT' -URISuffix ($( $URISuffix -f $IsRead.ToString().ToLower() )) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}

Export-ModuleMember -Function Update-VSAInfoMsg