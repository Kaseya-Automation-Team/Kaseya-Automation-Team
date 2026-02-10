function New-VSAThirdAppNotification
{
    <#
    .Synopsis
       Adds a notification.
    .DESCRIPTION
       Adds a notification to display to admins when they log into a tenant.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AppId
        Specifies id of application
    .PARAMETER Id
        Specifies id of the tenant
    .PARAMETER Title
        Specifies title of the notification
    .PARAMETER Message
        Specifies text of the notification
    .PARAMETER NavigateTo
        Specifies NavigateTo option
    .EXAMPLE
       New-VSAThirdAppNotification -AppId 4244543666 -Id 097055587852 -Title "Test" -Message "This is test notication"
    .EXAMPLE
       New-VSAThirdAppNotification -VSAConnection $connection -AppId 4244543666 -Id 097055587852 -Title "Test" -Message "This is test notication"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Success or failure
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/thirdpartyapps/notification",

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $AppId,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $Id,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Title,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Message,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $NavigateTo
)
	
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
    }

    $BodyHT = @{"AppId"=$AppId; "Id"=$Id; "Title"="$Title"; "Message"="$Message";}

    if ( -not [string]::IsNullOrEmpty($NavigateTo) ) { $BodyHT.Add('NavigateTo', $NavigateTo) }

    $Body = $BodyHT | ConvertTo-Json

    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}
New-Alias -Name Add-VSAThirdAppNotification -Value New-VSAThirdAppNotification
Export-ModuleMember -Function New-VSAThirdAppNotification -Alias Add-VSAThirdAppNotification