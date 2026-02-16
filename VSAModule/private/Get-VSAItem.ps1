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

    The `Get-VSAItemById` alias retrieves specific VSA Objects based on a provided ID. 
        Each alias corresponds to a different type of object (e.g., agent logs, 2FA settings, patch status).
    
        This function is versatile because it accepts multiple aliases that map to different REST API endpoints.
        The `Id` parameter is essential and typically refers to the ID of the object being retrieved (e.g., Agent ID, Module ID).

    SECURITY NOTE: The ID parameter accepts only positive numeric values to prevent injection attacks.


        KASEYA VSA 9 REST API ID FORMATS:
        - Agent IDs: Positive integers (e.g., 123456)
        - Machine Group IDs: Positive integers (e.g., 789)
        - Organization IDs: Positive integers (e.g., 1)
        - Module IDs: Positive integers
        - Service Desk IDs: Positive integers
        - Ticket IDs: Positive integers
        
        All VSA object IDs follow a standard numeric format in the Kaseya VSA 9 REST API.
        Reference: https://help.vsa9.kaseya.com/help/Content/Modules/rest-api/home.htm

        The following aliases map to specific VSA object retrievals:
    
        - **Get-VSAAgent2FA**: Retrieves 2FA settings for a specified Agent ID.
            - **Returned Object**: 2FA settings.

        - **Get-VSAAgentInView** and **Get-VSAAgentsInView**: Retrieves agent records in a specified view.
            - **Returned Object**: Array of Agent records.

        - **Get-VSAAgentLog**: Retrieves VSA agent's logs.
            - **Returned Object**: Array of Agent's logs.

        - **Get-VSAAgentOnNet** and **Get-VSAAgentsOnNet**: Retrieves agents in a specified Discovery network.
            - **Returned Object**: Array of Agents in a specified Discovery network.

        - **Get-VSAAgentPkgPage**: Retrieves logo, title and description displayed by the deployment page for a specified tenant partition.
            - **Returned Object**: Agent Deployment Page.

        - **Get-VSAAgentRCNotify**: Retrieves the remote control notify policy for an agent machine.
            - **Returned Object**: Remote control notify policy object.

        - **Get-VSAAgentSettings**: Retrieves settings of specific agent machine.
            - **Returned Object**: Agent machine's settings.

        - **Get-VSAAlarmLog**: Retrieves alarm log for given Agent Id.
            - **Returned Object**: Array of Alarm log records.

        - **Get-VSAAPHistory**: Retrieves Agent Procedure runtime history records.
            - **Returned Object**: Array of Agent Procedure history records.

        - **Get-VSAAPLog**: Retrieves VSA Agent Procedures' log.
            - **Returned Object**: Array of Agent Procedures' log records.

        - **Get-VSAAppEventLog**: Retrieves Application event log for a specified Agent Id.
            - **Returned Object**: Array of Application event log records.

        - **Get-VSAAPScheduled** and **Get-VSAScheduledAP**: Retrieves scheduled Agent Procedures for a specified Agent Id.
            - **Returned Object**: Array of scheduled Agent Procedures.

        - **Get-VSACfgChangeLog** and **Get-VSACfgChangesLog**: Retrieves VSA configuration changes for a specified Agent Id.
            - **Returned Object**: Array of configuration changes log records.
        
        - **Get-VSADirEventLog**: Retrieves directory services log records for a specified Agent Id.
            - **Returned Object**: Array of directory services event log records.

        - **Get-VSADNSEventLog**: Retrieves DNS server event log for a specified Agent Id.
            - **Returned Object**: Array of DNS server event log records.

        - **Get-VSAIEEventLog**: Retrieves Internet Explorer event log for a specified Agent Id.
            - **Returned Object**: Array of Internet Explorer event log records.

        - **Get-VSAKaseyaRCLog**: Retrieves Kaseya Remote Control log records for a specified Agent Id.
            - **Returned Object**: Array of Kaseya Remote Control event log records.

        - **Get-VSALegacyRCLog**: Retrieves VSA legacy remote control log records for a specified Agent Id.
            - **Returned Object**: Array of VSA legacy remote control event log records.

        - **Get-VSALogMonitoringLog**: Retrieves VSA log monitoring log for a specified Agent Id.
            - **Returned Object**: Array of VSA log monitoring log records.

        - **Get-VSAModuleActivated**: Retrieves VSA Module activation status for a specified Module ID.
            - **Returned Object**: True or false, based on whether the specified Module is activated.

        - **Get-VSAModuleStatus**: Retrieves VSA Module installation status for a specified Module ID.
            - **Returned Object**: True or false, based on whether the specified Module is installed.

        - **Get-VSAMonitorLog**: Retrieves VSA monitor action log for a specified Agent Id.
            - **Returned Object**: Array of the VSA monitor action log records.

        - **Get-VSANetStatLog**: Retrieves VSA network statistics log for a specified Agent Id.
            - **Returned Object**: Array of the VSA network statistics log records.

        - **Get-VSAPatchHistory**: Retrieves patch history for a specified Agent Id.
            - **Returned Object**: Array of the patch history records.

        - **Get-VSAPatchStatus**: Retrieves patch status of an agent machine with a specified Agent Id.
            - **Returned Object**: Array of objects that represent patch status details.

        - **Get-VSASDCategory** and **Get-VSASDCategories**: Retrieves custom fields for a specified Service Desk Id.
            - **Returned Object**: Array of ticket categories.

        - **Get-VSASDCustomField** and **Get-VSASDCustomFields**: Retrieves custom fields for a specified Service Desk Id.
            - **Returned Object**: Array of custom fields.

        - **Get-VSASDPriority** and **Get-VSASDPriorities**: Retrieves ticket priorities for a specified Service Desk Id.
            - **Returned Object**: Array of ticket priorities.

        - **Get-VSASDTicketNote** and **Get-VSASDTicketNotes**: Retrieves notes for a specified Service Desk Ticket Id.
            - **Returned Object**: Array of notes.

        - **Get-VSASDTicketStatus**: Retrieves ticket statuses for a specified Service Desk Id.
            - **Returned Object**: Array of ticket statuses.

        - **Get-VSASecurityEventLog**: Retrieves VSA security event log for a specified Agent Id.
            - **Returned Object**: Array of VSA security event log records.

        - **Get-VSASystemEventLog**: Retrieves VSA system event log for a specified Agent Id.
            - **Returned Object**: Array of VSA system event log records.

        - **Get-VSAThirdAppStatus**: Retrieves status of third party apps a specified Tenant Id.
            - **Returned Object**: Array of third party apps.

        - **Get-VSAWorkOrder** and **Get-VSAWorkOrders**: Retrieves Work Orders for the given Customer Id and within the scope of the sessionId.
            - **Returned Object**: Array of Work Orders.

    .PARAMETER VSAConnection
        Specifies an existing non-persistent VSAConnection. Required for the API call.

    .PARAMETER URISuffix
        Specifies the URI suffix for the REST API call. Defaults are set based on the alias used.

    .PARAMETER Filter
        Specifies REST API filters.

    .PARAMETER Paging
        Specifies REST API paging options.

    .PARAMETER Sort
        Specifies REST API sorting options.

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
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix,

        [Alias('AgentId', 'ViewId', 'NetworkId', 'PartitionId', 'AlarmId', 'AssetId', 'ModuleId', 'ServiceDeskId', 'ServiceDeskTicketId', 'CustomerId')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if ($_ -match '^\d+$') {
                $true
            } else {
                throw "ID must be a positive integer containing only digits."
            }
        })]
        [string] $Id,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    # Validate Id is provided for ById aliases
    if ($URISuffixGetByIdMap.ContainsKey($MyInvocation.InvocationName) -and !$PSBoundParameters.ContainsKey('Id')) {
        throw "Parameter '-Id' is required when invoked as '$($MyInvocation.InvocationName)'"
    }

    if ($URISuffixGetByIdMap.ContainsKey($MyInvocation.InvocationName)) {
        if ([string]::IsNullOrEmpty($URISuffix)) {
            $URISuffix = $URISuffixGetByIdMap[$MyInvocation.InvocationName]
            if ([string]::IsNullOrEmpty($URISuffix)) {
                throw "No VSA Object specified for alias $($MyInvocation.InvocationName)!"
            }
            $URISuffix = $URISuffix -f $Id
        }
    } else {
        if ([string]::IsNullOrEmpty($URISuffix)) {
            $URISuffix = $URISuffixGetMap[$MyInvocation.InvocationName]
            if ([string]::IsNullOrEmpty($URISuffix)) {
                throw "No VSA Object specified for alias $($MyInvocation.InvocationName)!"
            }
        }
    }

    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Filter        = $Filter
        Paging        = $Paging
        Sort          = $Sort
    }
    
    # Remove any empty parameters
    foreach ($key in $Params.Keys.Clone()) {
        if (-not $Params[$key]) {
            $Params.Remove($key)
        }
    }

    return Invoke-VSARestMethod @Params
}