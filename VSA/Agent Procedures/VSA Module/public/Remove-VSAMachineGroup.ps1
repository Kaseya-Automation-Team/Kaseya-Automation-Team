function Remove-VSAMachineGroup
{
    <#
    .Synopsis
       Removes machine group
    .DESCRIPTION
       Removes specified VSA machine group.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER MachineGroupId
        Specifies numeric id of machine group
    .EXAMPLE
       Remove-VSAMachineGroup -MachineGroupId 10001 -Confirm:$false
    .EXAMPLE
       Remove-VSAMachineGroup -VSAConnection $connection -MachineGroupId 10001
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
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
        [string] $MachineGroupId
)
    $URISuffix = $URISuffix -f $MachineGroupId
	
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'DELETE'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    
    if($PSCmdlet.ShouldProcess($MachineGroupId)){
        return Update-VSAItems @Params
    }
}

Export-ModuleMember -Function Remove-VSAMachineGroup