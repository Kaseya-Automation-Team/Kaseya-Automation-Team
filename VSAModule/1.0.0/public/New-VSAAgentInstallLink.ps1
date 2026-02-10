function New-VSAAgentInstallLink
{
    <#
    .Synopsis
       Add agents install package
    .DESCRIPTION
       Adds an agent install package record.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER PartitionId
        Specifies partition id
    .PARAMETER MachineGroupName
        Specifies name of machine group
    .EXAMPLE
       New-VSAAgentInstallLink -PartitionId 1 -MachineGroupName "MyOrg.root"
    .EXAMPLE
       New-VSAAgentInstallLink -VSAConnection $VSAConnection -PartitionId 1 -MachineGroupName "MyOrg.root"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/agent/packagelink",

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })] 
        [string] $PartitionId,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $MachineGroupName
)

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
        Body = "{`"PartitionId`":`"$PartitionId`",`"MachineGroupName`":`"$MachineGroupName`"}"
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

New-Alias -Name Add-VSAAgentInstallLink -Value New-VSAAgentInstallLink
Export-ModuleMember -Function New-VSAAgentInstallLink -Alias Add-VSAAgentInstallLink