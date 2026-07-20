function Get-VSAItem {
    <#
    .SYNOPSIS
       Returns VSA Objects using various aliases to retrieve different types of data.

    .DESCRIPTION
       The `Get-VSAItem` function retrieves an array of VSA Objects based on the alias used.
       This function serves as a generic cmdlet for multiple specific VSA retrievals via aliases.

       The following aliases map to specific VSA object retrievals:

       - **Get-VSAActivityType** and **Get-VSAActivityTypes**: Retrieves all available VSA Activity Types.
         - **Returned Object**: Array of Activity Types.

       - **Get-VSAAgentGW**: Retrieves Connection Gateway IP addresses for VSA agents.
         - **Returned Object**: Array of Connection Gateway IP addresses for agents.

       - **Get-VSAAgentNote**: Retrieves agent notes.
         - **Returned Object**: Array of agent notes.

       - **Get-VSAAgentPackage** and **Get-VSAAgentPackages**: Retrieves all agent installation packages.
         - **Returned Object**: Array of agent installation packages.

       - **Get-VSAAgentView** and **Get-VSAAgentViews**: Retrieves all available agent views.
         - **Returned Object**: Array of agent views.

       - **Get-VSAAP**: Retrieves existing VSA Agent Procedures.
         - **Returned Object**: Array of Agent Procedures.

       - **Get-VSAAPPortal**: Retrieves Agent Procedures displayed in the user portal.
         - **Returned Object**: Array of Agent Procedures from the user portal.

       - **Get-VSAAPQL**: Retrieves Agent Procedures available for quick launch in the Quick View window.
         - **Returned Object**: Array of quick-launch Agent Procedures.

       - **Get-VSAAPSettings**: Retrieves the setting for the 'Ask before executing' checkbox in the Quick View dialog.
         - **Returned Object**: Array of 'Ask before executing' settings.

       - **Get-VSAAssetType** and **Get-VSAAssetTypes**: Retrieves all VSA Asset Types.
         - **Returned Object**: Array of Asset Types.

       - **Get-VSAAuditSum**: Retrieves audit summaries.
         - **Returned Object**: Array of audit summaries.

       - **Get-VSACBServer** and **Get-VSACBServers**: Retrieves the status of physical servers using Cloud Backup.
         - **Returned Object**: Array of Cloud Backup server statuses.

       - **Get-VSACBVM**: Retrieves the status of virtual machines using Cloud Backup.
         - **Returned Object**: Array of Cloud Backup virtual machine statuses.

       - **Get-VSACBWS**: Retrieves the status of physical workstations using Cloud Backup.
         - **Returned Object**: Array of Cloud Backup workstation statuses.

       - **Get-VSACustomer** and **Get-VSACustomers**: Retrieves customers in scope of the session.
         - **Returned Object**: Array of customers.

       - **Get-VSAEnvironment**: Retrieves system-wide properties of the VSA environment.
         - **Returned Object**: Array of system properties.

       - **Get-VSAFunction** and **Get-VSAFunctions**: Retrieves a list of available VSA function IDs.
         - **Returned Object**: Array of function IDs.

       - **Get-VSAInfoMsg**: Retrieves a list of messages from the Inbox in Info Center.
         - **Returned Object**: Array of incoming messages.

       - **Get-VSASD**: Retrieves Service Desk definitions.
         - **Returned Object**: Array of Service Desk definitions.

       - **Get-VSASessionId**: Retrieves current session information and renews the session.
         - **Returned Object**: Session information.

       - **Get-VSATenant** and **Get-VSATenants**: Retrieves tenant information.
         - **Returned Object**: Array of tenant information.

       - **Get-VSAWorkOrderType** and **Get-VSAWorkOrderTypes**: Retrieves all available Work Order Types.
         - **Returned Object**: Array of Work Order Types.

       Each alias calls `Get-VSAItem` with specific parameters tailored to the object type being retrieved.

    .PARAMETER VSAConnection
        Specifies an existing non-persistent VSAConnection. Required for the API call.

    .PARAMETER URISuffix
        Specifies the URI suffix for the REST API call. Defaults are set based on the alias used.

    .PARAMETER Filter
        Specifies REST API filters.

    .PARAMETER Sort
        Specifies REST API sorting options.

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
        path is used, because it is faster than paying to set up extra connections.

    .EXAMPLE
        Get-VSAActivityType
        Retrieves all available VSA Activity Types.

    .EXAMPLE
        Get-VSAAgentGW
        Retrieves Connection Gateway IP addresses for VSA agents.

    .EXAMPLE
        Get-VSAWorkOrderType
        Retrieves all available Work Order Types in the VSA system.

    .NOTES
        This cmdlet is designed to work with multiple aliases that retrieve specific VSA object types. Each alias passes a
        different URI suffix to `Get-VSAItem` to retrieve different types of data.

        **Aliases**:
        - Get-VSAActivityType
        - Get-VSAActivityTypes
        - Get-VSAAgentGW
        - Get-VSAAgentNote
        - Get-VSAAgentPackage
        - Get-VSAAgentPackages
        - Get-VSAAgentView
        - Get-VSAAgentViews
        - Get-VSAAP
        - Get-VSAAPPortal
        - Get-VSAAPQL
        - Get-VSAAPSettings
        - Get-VSAAssetType
        - Get-VSAAuditSum
        - Get-VSACBServer
        - Get-VSACBServers
        - Get-VSACBVM
        - Get-VSACBWS
        - Get-VSACustomer
        - Get-VSACustomers
        - Get-VSAEnvironment
        - Get-VSAFunction
        - Get-VSAFunctions
        - Get-VSAInfoMsg
        - Get-VSASD
        - Get-VSASessionId
        - Get-VSATenant
        - Get-VSATenants
        - Get-VSAWorkOrderType
        - Get-VSAWorkOrderTypes

        Added in v1.4.0 (live-Swagger gap analysis):
        - Get-VSAAlertDefinition (alert definitions)
        - Get-VSARCService (default remote-control services)
        - Get-VSARCMachine (remote-control-enabled machines)
        - Get-VSATemporaryAgent (temporary/KLC agents)
        - Get-VSATemporaryAgentConfig (temporary-agent configuration)
        - Get-VSAAgentActiveAdmin (agents with an active administrator)
        - Get-VSAAgentUserProfile (agent user-profile settings)
        - Get-VSAAPList (agent-procedure list)
        - Get-VSAAPProcHistory (agent-procedure list history)
        - Get-VSAAPExecHistory (agent-procedure execution history)
        - Get-VSAAPPrompt (agent-procedure prompts)
        - Get-VSAAPVariable (managed variables)
        - Get-VSAOrgType (organization types)
        - Get-VSAOrgLocation (organization locations)
        - Get-VSATenantLogonPolicy (tenant logon policy)
        - Get-VSADocumentServiceAudit (audited services across documents)
        - Get-VSADocumentVolumeLabel (all volume labels)
        - Get-VSADocumentServiceName (distinct service names)
        - Get-VSADocumentDistinctVolumeLabel (distinct volume labels)
    #>

    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Sort,

        # Opt-in parallel paging for large collections (see Invoke-VSARestMethod). No effect on small
        # result sets; absent, behaviour is identical to before.
        [Parameter(Mandatory = $false)]
        [switch] $Parallel,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 64)]
        [int] $ThrottleLimit = 8,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $ParallelThreshold = 0
    )
    process {

    if ([string]::IsNullOrEmpty($URISuffix)) {
        # Resolve into a LOCAL first: assigning a $null map miss straight into $URISuffix (which is
        # [ValidateNotNullOrEmpty]) would throw the opaque "not a valid value for URISuffix" instead of
        # the actionable message below (the same class as F-4).
        $invName  = $PSCmdlet.MyInvocation.InvocationName
        $resolved = $URISuffixGetMap[$invName]
        if ([string]::IsNullOrEmpty($resolved)) {
            throw "Get-VSAItem is the internal read-dispatch engine and has no endpoint of its own; call it through one of its aliases (e.g. Get-VSAOrganization). List them with: Get-Alias -Definition Get-VSAItem. (Invoked as '$invName'.)"
        }
        $URISuffix = $resolved
    }

    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Filter        = $Filter
        Sort          = $Sort
    }

    # Remove any empty parameters
    foreach ($key in @($Params.Keys)) {
        if (-not $Params[$key]) {
            $Params.Remove($key)
        }
    }

    # Forward the parallel-paging controls only when opted in, so the default call is unchanged.
    if ($Parallel) {
        $Params['Parallel']      = $true
        $Params['ThrottleLimit'] = $ThrottleLimit
        if ($ParallelThreshold -gt 0) { $Params['ParallelThreshold'] = $ParallelThreshold }
    }

    return Invoke-VSARestMethod @Params
    }
}
