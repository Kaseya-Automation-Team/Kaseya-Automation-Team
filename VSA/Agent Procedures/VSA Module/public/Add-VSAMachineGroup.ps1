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
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/system/orgs/{0}/machinegroups",

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $OrgId,

		[parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -match "\.") ) {
                throw "MachineGroupName cannot contain the following special characters: ."
            }
            return $true
        })]
        [string] $MachineGroupName,

		[parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $ParentMachineGroupId,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $Attributes
)
	$URISuffix = $URISuffix -f $OrgId
     
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
    }

    [hashtable]$BodyHT = @{"MachineGroupName"="$MachineGroupName" }
    if ( -not [string]::IsNullOrEmpty($ParentMachineGroupId) ) { $BodyHT.Add('ParentMachineGroupId', $ParentMachineGroupId) }
    if ( -not [string]::IsNullOrEmpty($Attributes) ) {
        [hashtable] $AttributesHT = ConvertFrom-StringData -StringData $Attributes
        $BodyHT.Add('Attributes', $AttributesHT )
    }
   
    $Body = $BodyHT | ConvertTo-Json
    $Body | Out-String | Write-Debug
	
    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Add-VSAMachineGroup