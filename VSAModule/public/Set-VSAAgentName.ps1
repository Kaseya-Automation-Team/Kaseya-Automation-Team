function Set-VSAAgentName
{
    <#
    .Synopsis
       Renames the agent
    .DESCRIPTION
       Renames the agent
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies numeric id of machine group
    .PARAMETER Name
        Specifies new name of agent
    .EXAMPLE
       Set-VSAAgentName -AgentId 581411914 -Name "newname"
    .EXAMPLE
       Set-VSAAgentName -VSAConnection $connection -AgentId 581411914 -Name "newname"
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       No output
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = "api/v1.0/assetmgmt/agents/{0}/rename/{1}",

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName=$true)]
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
        [string] $Name
)
    process {

    return Invoke-VSAWriteRequest -Method PUT -VSAConnection $VSAConnection `
        -URISuffix ($URISuffix -f $AgentId, (Format-VSAPathSegment $Name)) -Caller $PSCmdlet
    }
}

New-Alias -Name Update-VSAAgentName -Value Set-VSAAgentName
Export-ModuleMember -Function Set-VSAAgentName -Alias Update-VSAAgentName