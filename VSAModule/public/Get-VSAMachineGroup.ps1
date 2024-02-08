function Get-VSAMachineGroup
{
    <#
    .Synopsis
       Returns Machine Groups.
    .DESCRIPTION
       Returns Machine Groups.
    .PARAMETER VSAConnection
        Specifies established VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER MachineGroupID
        Specifies MachineGroup ID to get. All Machine Groups are returned if no MachineGroupID specified.
    .PARAMETER OrgID
        Specifies Organization ID to return machine groups that belong to.
        Please use {0} as a placeholder for OrgID in case a custom URISuffix provided.
    .PARAMETER Filter.
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .PARAMETER ResolveIDs
        Return Organizations' info as well as their respective IDs.
    .EXAMPLE
       Get-VSAMachineGroup
    .EXAMPLE
       Get-VSAMachineGroup -OrgID '10001'
    .EXAMPLE
       Get-VSAMachineGroup -MachineGroupID '10001' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent Machine Groups.
    #>
    [alias("Get-VSAMG")]
    [CmdletBinding()] 
    param ( 
        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')] 
        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Group')] 
        [ValidateNotNull()] 
        [VSAConnection] $VSAConnection, 
 
        [parameter(Mandatory=$true, 
            ValueFromPipelineByPropertyName=$true, 
            ParameterSetName = 'Organization',
            HelpMessage = "Please  use {0} as a placeholder for OrgID in case a custom URISuffix provided.")]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $OrgID, 
 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Group')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $MachineGroupID,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Group')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization',
            HelpMessage = "Please  use {0} as a placeholder for OrgID in case a custom URISuffix provided.")]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix,
 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Group')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Group')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Group')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Group')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [switch] $ResolveIDs
        )

        
        if ( $OrgID ) { 
            #Machine groups for specific organization
            if( [string]::IsNullOrEmpty($URISuffix) ) { $URISuffix = "api/v1.0/system/orgs/{0}/machinegroups" }
            $URISuffix = $URISuffix -f $OrgID
        } else { 
            #Machine groups for all organizations
            if( [string]::IsNullOrEmpty($URISuffix) ) { $URISuffix= "api/v1.0/system/machinegroups" }

            if( -not [string]::IsNullOrEmpty($MachineGroupID)) {
                $URISuffix = "{0}/{1}" -f $URISuffix, $MachineGroupID
            }
        }

        [hashtable]$Params = @{
            VSAConnection = $VSAConnection
            URISuffix     = $URISuffix
        }

        if($Filter)        {$Params.Add('Filter', $Filter)}
        if($Paging)        {$Params.Add('Paging', $Paging)}
        if($Sort)          {$Params.Add('Sort', $Sort)}

        $result = Invoke-VSARestMethod @Params

        if ($ResolveIDs)
        {
            [hashtable]$ResolveParams =@{
                VSAConnection = $VSAConnection
            }

            [hashtable]$OrganizationDictionary = @{}

            Foreach( $Organization in $(Get-VSAOrganization @ResolveParams) )
            {
                if ( -Not $OrganizationDictionary[$Organization.OrgId]) {
                    $OrganizationDictionary.Add($Organization.OrgId, $($Organization | Select-Object * -ExcludeProperty OrgId))
                }
            }

            $result = $result | Select-Object -Property *, `
                @{Name = 'Organization'; Expression = { $OrganizationDictionary[$_.OrgId] }}
        }
    
        return $result
} 
Export-ModuleMember -Function Get-VSAMachineGroup