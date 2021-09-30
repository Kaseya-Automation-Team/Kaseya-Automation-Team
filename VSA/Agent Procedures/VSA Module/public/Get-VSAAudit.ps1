function Get-VSAAudit
{
    <#
    .Synopsis
       Returns VSA audit summary.
    .DESCRIPTION
       Returns VSA audit summary.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Inventory
        Specifies inventory to audit.
        Valid values
            AllSummaries
                Returns an array of audit summary records for all agents.
            Credentials
                Returns an array of credentials for an agent.
            Groups
                Returns an array of local user groups on the agent machine.
            DiskVolumes
                Returns an array of disk volumes on the agent machine.
            PCIAndDisk
                Returns an array of disk drives and PCI devices on the agent machine.
            Printers
                Returns an array of printers and ports configured on an agent machine.
            PurchaseAndWarrantyExpire
                Returns the purchase date and warranty expiration date for a single agent.
            LocalGroupMembers
                Returns an array of local users in each local user group on the agent machine.
            AddRemoveProgramsList
                Returns an array of program entries in the add/remove list of Windows machines.
            InstalledApps
                Returns an array of installed applications on the agent machine.
            Licenses
                Returns an array of licenses used by the agent machine.
            SecurityProducts
                Returns an array of security products installed on the agent machine.
            StartupApps
                Returns an array of startup apps on the agent machine.
            Summary
                Returns the audit summary for the agent machine.
            LocalUsers
                Returns an array of user accounts on the agent machine.
    .PARAMETER AgentID
        Specifies Agent ID to return audit entries for.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSAAudit
    .EXAMPLE
       Get-VSAAudit -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent VSA audit summary.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/audit/{0}',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('AllSummaries','Credentials','Groups','DiskVolumes','PCIAndDisk','Printers','PurchaseAndWarrantyExpire','LocalGroupMembers','AddRemoveProgramsList','InstalledApps','Licenses','SecurityProducts','StartupApps','Summary','Users')]
        [string] $Inventory = 'AllSummaries',

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Paging,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Sort
    )
    DynamicParam {
        if ( 'AllSummaries' -notmatch $Inventory ) {
            $attribute = New-Object System.Management.Automation.ParameterAttribute 
            $attribute.ParameterSetName = "__AllParameterSets" 
            $attribute.Mandatory = $true 
 
            $collection = New-Object System.Collections.ObjectModel.Collection[System.Attribute] 
            $collection.Add($attribute) 
 
            $param = New-Object System.Management.Automation.RuntimeDefinedParameter('AgentID', [string], $collection) 
            $dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary 
            $dictionary.Add('AgentID', $param) 
            return $dictionary
        }
    }
    Begin {
        if ( $($PSBoundParameters.AgentID) -and ($($PSBoundParameters.AgentID)  -notmatch "^\d+$")) {
            Write-Error "AgentID must be a numeric value!" -ErrorAction Stop
        }
    }

    Process {

        [string] $AgentID = $PSBoundParameters.AgentID
        if ( [string]::IsNullOrEmpty($AgentID) ) {$AgentID = ''}

        $URISuffix = $URISuffix -f $AgentID

        switch ($Inventory) {
            'Credentials'               {$URISuffix = "$URISuffix/credentials"}
            'Groups'                    {$URISuffix = "$URISuffix/groups"}
            'DiskVolumes'               {$URISuffix = "$URISuffix/hardware/diskvolumes"}
            'PCIAndDisk'                {$URISuffix = "$URISuffix/hardware/pcianddisk"}
            'Printers'                  {$URISuffix = "$URISuffix/hardware/printers"}
            'PurchaseAndWarrantyExpire' {$URISuffix = "$URISuffix/hardware/purchaseandwarrantyexpire"}
            'LocalGroupMembers'         {$URISuffix = "$URISuffix/members"}
            'AddRemoveProgramsList'     {$URISuffix = "$URISuffix/software/addremoveprograms"}
            'InstalledApps'             {$URISuffix = "$URISuffix/software/installedapplications"}
            'Licenses'                  {$URISuffix = "$URISuffix/software/licenses"}
            'SecurityProducts'          {$URISuffix = "$URISuffix/software/securityproducts"}
            'StartupApps'               {$URISuffix = "$URISuffix/software/startupapps"}
            'Summary'                   {$URISuffix = "$URISuffix/summary"}
            'LocalUsers'                {$URISuffix = "$URISuffix/useraccounts"}
        }

        [hashtable]$Params = @{
            URISuffix = $URISuffix
        }

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
        if($Filter)        {$Params.Add('Filter', $Filter)}
        if($Paging)        {$Params.Add('Paging', $Paging)}
        if($Sort)          {$Params.Add('Sort', $Sort)}

        return Get-VSAItems @Params
    }
}
Export-ModuleMember -Function Get-VSAAudit