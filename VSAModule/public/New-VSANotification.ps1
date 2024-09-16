function New-VSANotification
{
    <#
    .Synopsis
       Adds a single notification record.
    .DESCRIPTION
       Adds a single notification record.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Title
        Specifies numeric id of agent machine
    .PARAMETER Text
        Specifies email address of administrator
    .EXAMPLE
       New-VSANotification -Title "Title goes here" -Text "Text message goes here"
    .EXAMPLE
       New-VSANotification -VSAConnection $VSAConnection -Title "Title goes here" -Text "Text message goes here"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/notification',

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Title,

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Text
)
	
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
        Body = "{`"Title`":`"$Title`",`"Body`":`"$Text`"}"
    }
    
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

New-Alias -Name Add-VSANotification -Value New-VSANotification
Export-ModuleMember -Function New-VSANotification -Alias Add-VSANotification