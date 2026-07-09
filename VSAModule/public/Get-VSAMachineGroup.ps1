function Get-VSAMachineGroup
{
    <#
    .Synopsis
        Returns Machine Groups.
    .DESCRIPTION
        Returns Machine Groups.
        Takes either persistent or non-persistent connection information.
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
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Group')] 
        [ValidateNotNull()] 
        [VSAConnection] $VSAConnection, 
 
        [parameter(Mandatory=$true, 
            ValueFromPipelineByPropertyName=$true, 
            ParameterSetName = 'Organization',
            HelpMessage = "Please  use {0} as a placeholder for OrgId in case a custom URISuffix provided.")]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $OrgId, 
 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Group')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $MachineGroupId,

        [parameter(DontShow,Mandatory = $false,  
             
            ParameterSetName = 'Group')]
        [parameter(DontShow, Mandatory = $false,  
             
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
        [string] $Sort,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Group')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [switch] $ResolveIDs
        )
    process {

        if ( $OrgId ) { 
            #Machine groups for specific organization
            if( [string]::IsNullOrEmpty($URISuffix) ) { $URISuffix = "api/v1.0/system/orgs/{0}/machinegroups" }
            $URISuffix = $URISuffix -f $OrgId
        } else { 
            #Machine groups for all organizations
            if( [string]::IsNullOrEmpty($URISuffix) ) { $URISuffix= "api/v1.0/system/machinegroups" }

            if( -not [string]::IsNullOrEmpty($MachineGroupId)) {
                $URISuffix = "{0}/{1}" -f $URISuffix, $MachineGroupId
            }
        }

        [hashtable]$Params = @{
            VSAConnection = $VSAConnection
            URISuffix     = $URISuffix
            Filter        = $Filter
            Sort          = $Sort
        }
        
        #Remove empty keys
        foreach ( $key in @($Params.Keys)  ) {
            if ( -not $Params[$key]) { $Params.Remove($key) }
        }

        $result = Invoke-VSARestMethod @Params

        if ($ResolveIDs)
        {
            [hashtable]$ResolveParams =@{}
            # F-26: this added VSAConnection to $Params (which already carries it) instead of to the
            # $ResolveParams passed to Get-VSAOrganization -> "Item has already been added" and the
            # resolve lookup ran with no connection. Add it to $ResolveParams.
            if ($VSAConnection) {$ResolveParams.Add('VSAConnection', $VSAConnection)}

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
} 
Export-ModuleMember -Function Get-VSAMachineGroup
