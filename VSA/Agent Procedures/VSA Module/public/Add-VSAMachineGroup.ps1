function Add-VSAMachineGroup
{
    <#
    .Synopsis
       Adds new machine group
    .DESCRIPTION
       Adds new machine group in particular organization and parent machine group (if specified).
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER OrgId
        Specifies numeric id of organization
    .PARAMETER MachineGroupName
        Specifies name of new machine group
    .PARAMETER ParentMachineGroupId
        Optional parameter, specifies numeric id of parent machine group
    .EXAMPLE
       Add-VSAMachineGroup -OrgId "34543554343" -MachineGroupName "Kaseya"
	.EXAMPLE
       Add-VSAMachineGroup -OrgId "34543554343" -MachineGroupName "Kaseya" -ParentMachineGroupId "3243243242332"
    .EXAMPLE
       Add-VSAMachineGroup -VSAConnection $connection -MachineGroupName "Kaseya"
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
        [string] $URISuffix = "api/v1.0/system/orgs/{0}/machinegroups",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $OrgId,
		[parameter(ParameterSetName = 'Persistent', Mandatory=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $MachineGroupName,
		[parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $ParentMachineGroupId
)
	$URISuffix = $URISuffix -f $OrgId
     
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
    }

	if ($ParentMachineGroupId) {
		$Body = ConvertTo-Json @{"MachineGroupName"="$MachineGroupName";"ParentMachineGroupId"="$ParentMachineGroupId" }
	} else {
		$Body = ConvertTo-Json @{"MachineGroupName"="$MachineGroupName" }
	}
	
    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Add-VSAMachineGroup