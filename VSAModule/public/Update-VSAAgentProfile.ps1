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
        [string] $URISuffix = "api/v1.0/assetmgmt/agent/{0}/settings/userprofile",
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $AdminEmail,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $UserName,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $UserEmail,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $UserPhone,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Notes,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [int] $ShowToolTip,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [switch] $AutoAssignTickets = $false
)
    $URISuffix = $URISuffix -f $AgentId
	
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
    }

    $Body = ConvertTo-Json @{"AdminEmail"="$AdminEmail"; "UserName"="$UserName"; "UserEmail"="$UserEmail"; "UserPhone"="$UserPhone"; "Notes"="$Notes"; "ShowToolTip"="$ShowToolTip"; "AutoAssignTickets"="$AutoAssignTickets"}
	
    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Update-VSAAgentProfile