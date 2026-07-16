function Remove-VSAThirdAppNotification {
    <#
    .Synopsis
       Deletes a third party app notification message.
    .DESCRIPTION
       Deletes a third party app notification message.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AppId
        Specifies id of application
    .PARAMETER MessageId
        Specifies id of the notification message
    .EXAMPLE
       Remove-VSAThirdAppNotification -AppId 233434543543543 -MessageId 0328649898
    .EXAMPLE
       Remove-VSAThirdAppNotification -VSAConnection $connection -AppId 233434543543543 -MessageId 0328649898
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       Success or failure
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = "api/v1.0/thirdpartyapps/notification/{0}/{1}",

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AppId,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $MessageId
    )
    process {

    return Invoke-VSAWriteRequest -Method 'DELETE' -URISuffix ($($URISuffix -f $AppId, $MessageId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}

Export-ModuleMember -Function Remove-VSAThirdAppNotification