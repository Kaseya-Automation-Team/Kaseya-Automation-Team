function Update-VSAAgentProfile
{
    <#
    .Synopsis
       Updates the user profile settings for an agent.
    .DESCRIPTION
       Updates the user profile settings for an agent.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies numeric id of agent machine
    .PARAMETER AdminEmail
        Specifies email address of administrator
    .PARAMETER UserName
        Specifies username
    .PARAMETER UserEmail
        Specifies email of user
    .PARAMETER UserPhone
        Specifies phone number of user
    .PARAMETER Notes
        Specifies phone number of user
    .PARAMETER ShowToolTip
        Specifies to show tooltip or not
    .EXAMPLE
       Update-VSAAgentProfile -AgentId 323232323 -AdminEmail "support@yourcompany.com" -UserName "admin" -UserEmail "admin@yourcompany.com" -UserPhone "+183234334" -Notes "Alan's computer" -ShowToolTip 1 -AutoAssignTickets
    .EXAMPLE
       Update-VSAAgentProfile -VSAConne-AgentId 323232323 -AdminEmail "support@yourcompany.com" -UserName "admin" -UserEmail "admin@yourcompany.com" -UserPhone "+183234334" -Notes "Alan's computer" -ShowToolTip 0
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/assetmgmt/agent/{0}/settings/userprofile",

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $AdminEmail,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $UserName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $UserEmail,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $UserPhone,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Notes,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $ShowToolTip,

        [switch] $AutoAssignTickets
)
	
    [hashtable]$Params =@{
        URISuffix = $($URISuffix -f $AgentId)
        Method = 'PUT'
        Body = $("{""AdminEmail"":""$AdminEmail"",""UserName"":""$UserName"",""UserEmail"":""$UserEmail"",""UserPhone"":""$UserPhone"",""Notes"":""$Notes"",""ShowToolTip"":""$ShowToolTip"",""AutoAssignTickets"":""$AutoAssignTickets""}")
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Update-VSAAgentProfile