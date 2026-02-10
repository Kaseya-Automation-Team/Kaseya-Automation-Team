function Update-VSASDTicketCustomFields
{
    <#
    .Synopsis
       Updates the value of a custom field in a service desk ticket
    .DESCRIPTION
       Updates the value of a custom field in a service desk ticket.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ServiceDeskTicketId
        Specifies id of service desk ticket
    .PARAMETER CustomFieldId
        Specifies id of customer field
    .PARAMETER Value
        Specifies new value of custom field
    .EXAMPLE
       Update-VSASDTicketCustomFields -ServiceDeskTicketId 3256598065654 -CustomFieldId 376887433552 -Value "Automatic"
    .EXAMPLE
       Update-VSASDTicketCustomFields -VSAConnection $connection -ServiceDeskTicketId 3256598065654 -CustomFieldId "Automatic"
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
        [string] $URISuffix = "api/v1.0/automation/servicedesktickets/{0}/customfields/{1}",

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })] 
        [string] $ServiceDeskTicketId,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $CustomFieldId,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Value
)

    [hashtable]$Params =@{
        URISuffix = $($URISuffix -f $ServiceDeskTicketId, $CustomFieldId)
        Method    = 'PUT'
        Body      = "`"$Value`""
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Update-VSASDTicketCustomFields