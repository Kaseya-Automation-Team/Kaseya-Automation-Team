function New-VSAMachineGroup
{
    <#
    .Synopsis
       Creates a new machine group
    .DESCRIPTION
       Creates a new machine group in an organization and parent machine group (if specified).
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
       New-VSAMachineGroup -OrgId "34543554343" -MachineGroupName "Kaseya"
	.EXAMPLE
       New-VSAMachineGroup -OrgId "34543554343" -MachineGroupName "Kaseya" -ParentMachineGroupId "3243243242332"
    .EXAMPLE
       New-VSAMachineGroup -VSAConnection $connection -MachineGroupName "Kaseya"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/system/orgs/{0}/machinegroups",
        
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
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
        [string] $Attributes,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [switch] $ExtendedOutput
    )

    #Check if the Organization exists
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { Write-Debug "New-VSAMachineGroup. Check if the Organization exists" }
    
    $ParentOrganization = try { Get-VSAOrganization -VSAConnection $VSAConnection -OrgID $OrgId } catch {$null}
    if ( $null -eq $ParentOrganization ) { 
        Write-Warning "Could not find find the parent Organization by the OrgId provided '$OrgId' for the new Group '$MachineGroupName'."
        return $false
    } else {
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug "New-VSAMachineGroup: Found Parent Organization '$($ParentOrganization.OrgRef)' for Machine Group '$MachineGroupName'."
        }
    }
    $URISuffix = $URISuffix -f $OrgId

    [string[]]$AllFields = @('MachineGroupName', 'ParentMachineGroupId', 'Attributes')

    [hashtable]$BodyHT = ($(Get-PSCallStack)[0].Arguments).Trim('{}') -replace ',', "`n" | ConvertFrom-StringData

    foreach ( $key in $BodyHT.Keys.Clone() ) {
        if ( $key -notin $AllFields )  { $BodyHT.Remove($key) }
    }

    if ( -not [string]::IsNullOrEmpty($ParentMachineGroupId) ) {
        #Check if the Parent Organization exists
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug "New-VSAMachineGroup. Check if the Parent Machine Group exists."
        }

        $ParentMachineGroup = try {Get-VSAMachineGroup -VSAConnection $VSAConnection -MachineGroupID $ParentMachineGroupId } catch {$null}
            
        if ( [string]::IsNullOrEmpty($ParentMachineGroup) ) {
            Write-Warning "Could not find find the Parent Machine Group by the ParentMachineGroupId provided '$ParentMachineGroupId' for '$MachineGroupName'."
        }
    } else {
        $BodyHT.Remove("ParentMachineGroupId")
    }

    #region Process Attributes
    if ( -not [string]::IsNullOrEmpty($Attributes) ) {
        [hashtable] $AttributesHT = ConvertFrom-StringData -StringData $Attributes
        $BodyHT['Attributes'] = $AttributesHT
    } else {
        $BodyHT.Remove("Attributes")
    }
    #endregion Process Attributes
   
    $Body = $BodyHT | ConvertTo-Json
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "New-VSAMachineGroup. Request Body: $Body"
    }
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        Write-Debug "New-VSAMachineGroup. Request Body: $Body"
    }
    
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
        Body = $Body
        ExtendedOutput = $ExtendedOutput
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Result = Invoke-VSARestMethod @Params
    if ($ExtendedOutput) { $Result = $Result | Select-Object -ExpandProperty Result}

    return $Result
}
New-Alias -Name Add-VSAMachineGroup -Value New-VSAMachineGroup
New-Alias -Name New-VSAMG -Value New-VSAMachineGroup
Export-ModuleMember -Function New-VSAMachineGroup -Alias Add-VSAMachineGroup, New-VSAMG