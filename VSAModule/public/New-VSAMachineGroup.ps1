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
    .PARAMETER Attributes
        Specifies additional attributes to send in the request body.
    .PARAMETER ExtendedOutput
        Returns the full API response envelope instead of only the result set.
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
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
        # Accepts a [hashtable]/[pscustomobject] (preferred) or the legacy "Key=value" string.
        [object] $Attributes,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [switch] $ExtendedOutput
    )
    process {

    #Check if the Organization exists
    Write-Debug "New-VSAMachineGroup. Check if the Organization exists"

    $ParentOrganization = try { Get-VSAOrganization -VSAConnection $VSAConnection -OrgID $OrgId } catch {$null}
    if ( $null -eq $ParentOrganization ) {
        Write-Warning "Could not find find the parent Organization by the OrgId provided '$OrgId' for the new Group '$MachineGroupName'."
        return $false
    } else {
        Write-Debug "New-VSAMachineGroup: Found Parent Organization '$($ParentOrganization.OrgRef)' for Machine Group '$MachineGroupName'."

    }

    [string[]]$AllFields = @('MachineGroupName', 'ParentMachineGroupId')

    # Build the request body from bound parameters, preserving values exactly (F-39).
    [hashtable]$BodyHT = ConvertTo-VSARequestBody -BoundParameters $PSBoundParameters -Include $AllFields

    if ( [string]::IsNullOrEmpty($ParentMachineGroupId) ) {
        $BodyHT.Remove("ParentMachineGroupId")
    } else {
        #Check if the Parent Organization exists
        Write-Debug "New-VSAMachineGroup. Check if the Parent Machine Group exists."

        $ParentMachineGroup = try {Get-VSAMachineGroup -VSAConnection $VSAConnection -MachineGroupID $ParentMachineGroupId } catch {$null}

        if ( $null -eq $ParentMachineGroup ) {
            Write-Warning "Could not find find the Parent Machine Group by the ParentMachineGroupId provided '$ParentMachineGroupId' for '$MachineGroupName'."
            $BodyHT.Remove("ParentMachineGroupId")
        }
    }

    #region Process Attributes
    $BodyHT.Remove("Attributes")
    if ( $null -ne $Attributes ) {
        [hashtable] $AttributesHT = ConvertTo-VSAHashtable $Attributes
        if ( 0 -lt $AttributesHT.Count ) { $BodyHT['Attributes'] = $AttributesHT }
    }
    #endregion Process Attributes

    $Body = $BodyHT | ConvertTo-Json
    Write-Debug "New-VSAMachineGroup. Request Body: $Body"

    return Invoke-VSAWriteRequest -Body $Body -Method POST -URISuffix ($URISuffix -f $OrgId) `
        -VSAConnection $VSAConnection -ExtendedOutput:$ExtendedOutput -Caller $PSCmdlet
    }
}
New-Alias -Name Add-VSAMachineGroup -Value New-VSAMachineGroup
New-Alias -Name New-VSAMG -Value New-VSAMachineGroup
Export-ModuleMember -Function New-VSAMachineGroup -Alias Add-VSAMachineGroup, New-VSAMG