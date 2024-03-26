function Update-VSAMachineGroup
{
    <#
    .Synopsis
       Updates name of machine group
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
       Update-VSAMachineGroup -MachineGroupId "34543554343" -MachineGroupName "Kaseya"
    .EXAMPLE
       Update-VSAMachineGroup -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding(SupportsShouldProcess)]
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
        [string] $URISuffix = "api/v1.0/system/machinegroups/{0}",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $MachineGroupId,
		[parameter(ParameterSetName = 'Persistent', Mandatory=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $MachineGroupName
)
	$URISuffix = $URISuffix -f $MachineGroupId
     
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
    }

    $Body = ConvertTo-Json @{"MachineGroupName"="$MachineGroupName" }
	
    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Update-VSAMachineGroup