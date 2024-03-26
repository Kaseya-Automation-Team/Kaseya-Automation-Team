function Add-VSAThirdAppNotification
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
       Add-VSAThirdAppNotification -AppId 4244543666 -Id 097055587852 -Title "Test" -Message "This is test notication"
    .EXAMPLE
       Add-VSAThirdAppNotification -VSAConnection $connection -AppId 4244543666 -Id 097055587852 -Title "Test" -Message "This is test notication"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Success or failure
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NonPersistent')]
        [VSAConnection] $VSAConnection,
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/thirdpartyapps/notification",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [int] $AppId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [decimal] $Id,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Title,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Message,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
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

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Add-VSAThirdAppNotification