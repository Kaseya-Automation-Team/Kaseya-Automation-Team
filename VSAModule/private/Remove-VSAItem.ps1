function Remove-VSAItem {
    <#
    .SYNOPSIS
        Removes VSA objects based on the alias used, targeting specific object types for deletion.

    .DESCRIPTION
        The `Remove-VSAItem` function removes various VSA objects depending on the alias used. 
        Each alias corresponds to a specific object type (e.g., agent install packages, notes, assets) and allows for 
        targeted removal using an identifier (ID). The function uses the REST API to perform the deletion based on 
        the object’s ID and the alias-specified URI suffix.
    
        This cmdlet can remove multiple object types, such as agent notes, organization records, machine groups, 
        roles, and more.

        The following aliases map to specific VSA object removals:
   
        - **Remove-VSAAgentInstallPkg**: Removes an agent install package with a specified Package Id.
        - **Remove-VSAAgentNote**: Removes an agent note with a specified Note Id.
        - **Remove-VSAAPQL**: Removes specified agent procedure from quick launch in "Quick View" window.
        - **Remove-VSAAsset**: Removes a specified asset.
        - **Remove-VSADepartment**: Removes a specified department.
        - **Remove-VSAInfoMsg**: Removes a specified item from Inbox in Info Center.
        - **Remove-VSAMachineGroup**: Removes a specified machine group.
        - **Remove-VSAOrganization**: Removes a specified organization.
        - **Remove-VSARole**: Removes a user role with a specified Role Id.
        - **Remove-VSAScope**: Removes a VSA scope with a specified Scope Id.
        - **Remove-VSAStaff**: Removes a VSA staff record with a specified Org Staff Id.
        - **Remove-VSATenant**: Removes a VSA tenant partition with a specified Tenant Id.
        - **Remove-VSATenantRoleType**: Removes a roletype from the entire VSA.

    .PARAMETER VSAConnection
        Specifies an existing non-persistent VSAConnection. Required for the API call.

    .PARAMETER URISuffix
        Specifies the URI suffix for the REST API call. This is typically determined by the alias used and is not manually specified.

    .PARAMETER ID
        Specifies the numeric ID of the object being removed (e.g., Agent Install Package ID, Note ID, Asset ID). 
        Required for object deletion.

    .EXAMPLE
        Remove-VSAAgentInstallPkg -ID 12345
        Removes the agent install package with ID 12345.

    .EXAMPLE
        Remove-VSAAsset -ID 54321
        Removes the asset with ID 54321 from the VSA.

    .EXAMPLE
        Remove-VSAAgentNote -ID 98765
        Removes the agent note with ID 98765.

    .NOTES
        This cmdlet is designed to work with multiple aliases that remove specific VSA object types. Each alias passes a 
        different URI suffix to `Remove-VSAItem` to remove different types of data.
    
        **Aliases**:
        - Remove-VSAAgentInstallPkg
        - Remove-VSAAgentNote
        - Remove-VSAAPQL
        - Remove-VSAAsset
        - Remove-VSAInfoMsg
        - Remove-VSADepartment
        - Remove-VSAMachineGroup
        - Remove-VSAOrganization
        - Remove-VSARole
        - Remove-VSAScope
        - Remove-VSAStaff
        - Remove-VSATenant
        - Remove-VSATenantRoleType
    #>

    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix,

        [Alias('NoteId', 'PackageId', 'AgentProcedureId', 'AssetId', 'DepartmentId', 'MachineGroupId', 'OrgId', 'RoleId', 'ScopeId', 'OrgStaffId', 'TenantId', 'RoleTypeId')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })] 
        [string] $Id
    )
                            

    if ( [string]::IsNullOrEmpty($URISuffix) ) {

        $URISuffix = $URISuffixRemoveMap[$PSCmdlet.MyInvocation.InvocationName]
        if ( [string]::IsNullOrEmpty($URISuffix) ) {
            throw "No VSA Object specified for alias $($PSCmdlet.MyInvocation.InvocationName)!"
        }
    }
    $URISuffix = $URISuffix -f $Id

    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Method        = 'DELETE'
    }
    foreach ( $key in $Params.Keys.Clone() ) {
        if ( -not $Params[$key] )  { $Params.Remove($key) }
    }

    if( $PSCmdlet.ShouldProcess( $Id ) ) {
        return Invoke-VSARestMethod @Params
    }
}