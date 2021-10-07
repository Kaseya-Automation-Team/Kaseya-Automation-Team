function Add-VSAEmail
{
    <#
    .Synopsis
       Sends an email to a specified recipient.
    .DESCRIPTION
       Sends an email to a specified recipient.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER FromAddress
        Specifies recepient's email address
    .PARAMETER ToAddress
        Specifies email address of sender
    .PARAMETER Subject
        Specifies subject of email
    .PARAMETER Body
        Specifies content of email    
    .PARAMETER Html
        Specifies if email should be sent in HTML or plain text format   
    .PARAMETER Priority
        Specifies priority
    .PARAMETER UniqueTag
        Specifies unique tag 
    .EXAMPLE
       Add-VSAEmail -FromAddress "noreply@yourcompany.com" -ToAddress "email@yourcompany.com" -Subject "Email from administrator" -Body "This is test email from your administrator"  -UniqueTag "test"
    .EXAMPLE
       Add-VSAEmail -FromAddress "noreply@yourcompany.com" -ToAddress "email@yourcompany.com" -Subject "Email from administrator" -Body "This is test email from your administrator"  -Html -Priority 3 -UniqueTag "test"
    .EXAMPLE
       Add-VSAEmail -VSAConnection $VSAConnection -FromAddress "noreply@yourcompany.com" -ToAddress "email@yourcompany.com" -Subject "Email from administrator" -Body "This is test email from your administrator"  -UniqueTag "test"
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
        [string] $URISuffix = "api/v1.0/email",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $FromAddress,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $ToAddress,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Subject,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Body,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [switch] $Html =$false,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [int] $Priority = 0,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $UniqueTag
)
	
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
    }

    $BodyHT = @{"FromAddress"="$FromAddress"; "ToAddress"="$ToAddress"; "Subject"="$Subject"; "Body"="$Body"; "Priority"=$Priority; "IsBodyHtml"=$Html.ToBool()}

    if ( -not [string]::IsNullOrEmpty($UniqueTag) ) { $BodyHT.Add('UniqueTag', $UniqueTag) }

    $Body = $BodyHT | ConvertTo-Json
	
    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Add-VSAEmail