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

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
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

    [hashtable]$Params =@{
        URISuffix = $($URISuffix -f $AppId, $MessageId)
        Method = 'DELETE'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Remove-VSAThirdAppNotification