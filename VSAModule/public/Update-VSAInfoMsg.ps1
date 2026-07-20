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
    .PARAMETER ID
        Specifies the Ids of the Info Center messages to update. Accepts an array.
    .PARAMETER IsRead
        Marks the specified messages as read. Omit to mark them as unread.
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
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
        # Info-message ids are 26-digit backend identities: they overflow every integer type and a
        # [decimal] serialises as "N.0". They travel as strings (the ValidateScript still enforces
        # numeric-only input).
        [string[]] $ID,

        [switch] $IsRead
    )
    process {

    return Invoke-VSAWriteRequest -Body ($( $ID | ConvertTo-Json -Compress )) -Method 'PUT' -URISuffix ($( $URISuffix -f $IsRead.ToString().ToLower() )) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}

Export-ModuleMember -Function Update-VSAInfoMsg