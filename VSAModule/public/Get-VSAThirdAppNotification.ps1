function Get-VSAThirdAppNotification {
    <#
    .Synopsis
       Gets notifications.
    .DESCRIPTION
       Gets notification settings of specified App or details of specified notification message.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AppId
        Specifies app id of the tenant.
    .PARAMETER MessageId
        Specifies id of notification message.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSAThirdAppNotification -AppId 233434543543543
    .EXAMPLE
       Get-VSAThirdAppNotification -AppId 233434543543543 -MessageId 0328649898
    .EXAMPLE
       Get-VSAThirdAppNotification -VSAConnection $connection -AppId 233434543543543
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of items that represent notifications or details of specific notification message
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/thirdpartyapps/notification/{0}',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })] 
        [string] $AppId,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })] 
        [string] $MessageId,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    $URISuffix = $URISuffix -f $AppId

    if( -not [string]::IsNullOrWhiteSpace( $MessageId) ) {
        $URISuffix += "/$MessageId"
    }

    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    [hashtable]$Params = @{
        URISuffix     = $URISuffix
        VSAConnection = $VSAConnection
        Filter        = $Filter
        Paging        = $Paging
        Sort          = $Sort
    }

    foreach ( $key in $Params.Keys.Clone()  ) {
        if ( -not $Params[$key]) { $Params.Remove($key) }
    }

    return Invoke-VSARestMethod @Params
}
Export-ModuleMember -Function Get-VSAThirdAppNotification