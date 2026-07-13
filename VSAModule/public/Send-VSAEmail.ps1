function Send-VSAEmail
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
       Send-VSAEmail -FromAddress "noreply@yourcompany.com" -ToAddress "email@yourcompany.com" -Subject "Email from administrator" -Body "This is test email from your administrator"  -UniqueTag "test"
    .EXAMPLE
       Send-VSAEmail -FromAddress "noreply@yourcompany.com" -ToAddress "email@yourcompany.com" -Subject "Email from administrator" -Body "This is test email from your administrator"  -Html -Priority 3 -UniqueTag "test"
    .EXAMPLE
       Send-VSAEmail -VSAConnection $VSAConnection -FromAddress "noreply@yourcompany.com" -ToAddress "email@yourcompany.com" -Subject "Email from administrator" -Body "This is test email from your administrator"  -UniqueTag "test"
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       Success or failure
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = "api/v1.0/email",

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $FromAddress,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ToAddress,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Subject,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Body,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $UniqueTag,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [int] $Priority = 0,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [switch] $Html = $false

)

    $BodyHT = @{"FromAddress"="$FromAddress"; "ToAddress"="$ToAddress"; "Subject"="$Subject"; "Body"="$Body"; "Priority"=$Priority; "IsBodyHtml"=$Html.ToBool()}

    if ( -not [string]::IsNullOrEmpty($UniqueTag) ) { $BodyHT.Add('UniqueTag', $UniqueTag) }

    $Body = $BodyHT | ConvertTo-Json -Compress

    return Invoke-VSAWriteRequest -Body $Body -Method 'POST' -URISuffix ($URISuffix) -VSAConnection $VSAConnection -Caller $PSCmdlet
}

New-Alias -Name Add-VSAEmail -Value Send-VSAEmail
Export-ModuleMember -Function Send-VSAEmail -Alias Add-VSAEmail