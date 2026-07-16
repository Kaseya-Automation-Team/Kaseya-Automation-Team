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
    .PARAMETER AuditOf
        Specifies inventory to audit.
        Valid values
            AllAgentsSummaries
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
    .PARAMETER Sort
        Specifies REST API Sorting.
    .PARAMETER Parallel
        Fetches the remaining pages of a large collection concurrently instead of one after another.
        Opt-in: without it, behaviour is unchanged. Results are identical either way (same records,
        merged in $skip order). Only engages once the collection is large enough to be worth it
        (see -ParallelThreshold).
    .PARAMETER ThrottleLimit
        Maximum number of concurrent requests when -Parallel is used (default 8). On shared SaaS you
        are one tenant among many, so a modest value is a good citizen; the engine also reduces
        concurrency automatically if the server returns HTTP 429, then recovers.
    .PARAMETER ParallelThreshold
        Minimum total record count before -Parallel actually engages. 0 (default) means automatic:
        two full throttle windows, i.e. 2 * ThrottleLimit * 100 records. Below that the sequential
        path is used, because it is faster than paying to set up extra connections.    .EXAMPLE
       Get-VSAAudit -AuditOf DiskVolumes -AgentID 757824222824211
    .EXAMPLE
       Get-VSAAudit -VSAConnection $connection -AuditOf DiskVolumes -AgentID 757824222824211
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

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/audit/{0}',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('AllAgentsSummaries','Credentials','Groups','DiskVolumes','PCIAndDisk','Printers','PurchaseAndWarrantyExpire','LocalGroupMembers','AddRemoveProgramsList','InstalledApps','Licenses','SecurityProducts','StartupApps','Summary','LocalUsers')]
        [string] $AuditOf = 'AllAgentsSummaries',

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Sort,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            # Empty is valid: AgentID is not used for -AuditOf AllAgentsSummaries (F-24).
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "AgentID must be a numeric value!"
            }
            return $true
        })]
        [string] $AgentID,

        # Opt-in parallel paging for large collections (see Invoke-VSARestMethod). No effect on small
        # ones: below -ParallelThreshold the sequential path is used.
        [parameter(Mandatory = $false)]
        [switch] $Parallel,

        [parameter(Mandatory = $false)]
        [ValidateRange(1, 64)]
        [int] $ThrottleLimit = 8,

        [parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $ParallelThreshold = 0
    )
    Begin {
        # AgentID is mandatory for every AuditOf value except 'AllAgentsSummaries'. This used to
        # be enforced via a DynamicParam block; DynamicParam blocks are evaluated on every
        # Get-Command/tab-completion, so any REST call inside one runs far more often than the
        # cmdlet is actually invoked (F-44). This cmdlet never made a REST call from DynamicParam,
        # but the pattern is replaced here for consistency and to avoid the unnecessary overhead.
        if ($AuditOf -ne 'AllAgentsSummaries' -and [string]::IsNullOrEmpty($AgentID)) {
            throw "Get-VSAAudit: -AgentID is required when -AuditOf is not 'AllAgentsSummaries'."
        }
    }

    Process {

        if ( [string]::IsNullOrEmpty($AgentID) ) {$AgentID = ''}

        switch ($AuditOf) {
            # All-agents summaries is the base collection GET /assetmgmt/audit (no agent id) -- the
            # default value. Strip the '/{0}' agent placeholder; appending an id gives 403 and an
            # empty id gives a trailing-slash URL, so the default invocation was broken (F-24).
            'AllAgentsSummaries'        {$URISuffix = $URISuffix -replace '/\{0\}$', ''}
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
            URISuffix     = $($URISuffix -f $AgentId)
            VSAConnection = $VSAConnection
            Filter        = $Filter
            Sort          = $Sort
        }

        foreach ( $key in @($Params.Keys)  ) {
            if ( -not $Params[$key]) { $Params.Remove($key) }
        }

    # Forward the opt-in parallel controls to the shared read path, which owns the paging engine.
    if ($Parallel) {
        $Params['Parallel']      = $true
        $Params['ThrottleLimit'] = $ThrottleLimit
        if ($ParallelThreshold -gt 0) { $Params['ParallelThreshold'] = $ParallelThreshold }
    }
        return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Get-VSAAudit
