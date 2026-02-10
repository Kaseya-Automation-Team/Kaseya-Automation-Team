function Rename-VSAMachineGroup
{
    <#
    .Synopsis
       Renames a machine group
    .DESCRIPTION
       Updates name of specified machine group to new one.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER MachineGroupId
        Specifies numeric id of machine group
    .PARAMETER MachineGroupName
        Specifies new name of machine group
    .EXAMPLE
       Rename-VSAMachineGroup -MachineGroupId "34543554343" -MachineGroupName "Kaseya"
    .EXAMPLE
       Rename-VSAMachineGroup -MachineGroupId "34543554343" -MachineGroupName "Kaseya" -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/system/machinegroups/{0}",

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $MachineGroupId,

		[parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $MachineGroupName
)
     
    [hashtable]$Params =@{
        URISuffix = $($URISuffix -f $MachineGroupId)
        Method = 'PUT'
        Body = "{`"MachineGroupName`":`"$MachineGroupName`"}"
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}
New-Alias -Name Update-VSAMachineGroup -Value Rename-VSAMachineGroup
Export-ModuleMember -Function Rename-VSAMachineGroup -Alias Update-VSAMachineGroup