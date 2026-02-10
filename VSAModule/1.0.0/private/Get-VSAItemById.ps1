function Get-VSAItemById {
    <#
    .SYNOPSIS
        Retrieves VSA Objects for a specified ID using aliases to target specific data types.

    .DESCRIPTION
        The `Get-VSAItemById` function retrieves specific VSA Objects based on a provided ID. 
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
        Reference: help.kaseya.com/webhelp/EN/RESTAPI/9050000/

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
        Specifies an existing non-persistent VSAConnection. This can either be passed as a parameter or piped into the function. 
        Required for the API call.

    .PARAMETER URISuffix
        Specifies the URI suffix for the REST API call. Defaults are automatically set based on the alias used, so this typically
        doesn't need to be manually specified.

    .PARAMETER Id
        Specifies the numeric ID of the VSA object being retrieved. The ID refers to a different type of object depending on the alias used.
        For example, with **Get-VSAAgentLog**, the ID would represent an Agent ID, while with **Get-VSAModuleStatus**, the ID represents a Module ID.

    .PARAMETER Filter
        Specifies REST API filters for narrowing down the data results.

    .PARAMETER Paging
        Specifies REST API paging options for large datasets.

    .PARAMETER Sort
        Specifies REST API sorting options for organizing the returned data.

    .EXAMPLE
        Get-VSAAgent2FA -Id 12345
        Retrieves 2FA settings for the agent with ID 12345.

    .EXAMPLE
        Get-VSASDTicketStatus -Id 98765
        Retrieves the status of the service desk ticket with ID 98765.

    .NOTES
        This cmdlet is designed to work with multiple aliases that retrieve specific VSA object types. Each alias passes a 
        different URI suffix to `Get-VSAItemById` to retrieve different types of data.
    
        **Aliases**:
        - Get-VSAAgent2FA
        - Get-VSAAgentInView
        - Get-VSAAgentsInView
        - Get-VSAAgentLog
        - Get-VSAAgentOnNet
        - Get-VSAAgentsOnNet
        - Get-VSAAgentPkgPage
        - Get-VSAAgentRCNotify
        - Get-VSAAgentSettings
        - Get-VSAAlarmLog
        - Get-VSAAPHistory
        - Get-VSAAPLog
        - Get-VSAAppEventLog
        - Get-VSAAPScheduled
        - Get-VSAScheduledAP
        - Get-VSACfgChangeLog
        - Get-VSACfgChangesLog
        - Get-VSADirEventLog
        - Get-VSADNSEventLog
        - Get-VSAIEEventLog
        - Get-VSAKaseyaRCLog
        - Get-VSALegacyRCLog
        - Get-VSALogMonitoringLog
        - Get-VSAModuleActivated
        - Get-VSAModuleStatus
        - Get-VSAMonitorLog
        - Get-VSANetStatLog
        - Get-VSAPatchHistory
        - Get-VSAPatchStatus
        - Get-VSASDCategory
        - Get-VSASDCategories
        - Get-VSASDCustomField
        - Get-VSASDCustomFields
        - Get-VSASDPriority
        - Get-VSASDPriorities
        - Get-VSASDTicketNote
        - Get-VSASDTicketNotes
        - Get-VSASDTicketStatus
        - Get-VSASecurityEventLog
        - Get-VSASystemEventLog
        - Get-VSAThirdAppStatus
        - Get-VSAWorkOrder
        - Get-VSAWorkOrders
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
        [parameter(Mandatory=$true,
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
                            

    if ( [string]::IsNullOrEmpty($URISuffix) ) {

        $URISuffix = $URISuffixGetByIdMap[$PSCmdlet.MyInvocation.InvocationName]
        if ( [string]::IsNullOrEmpty($URISuffix) ) {
            throw "No VSA Object specified for alias $($PSCmdlet.MyInvocation.InvocationName)!"
        }
    }
    $URISuffix = $URISuffix -f $Id

    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Filter        = $Filter
        Paging        = $Paging
        Sort          = $Sort
    }
    foreach ( $key in $Params.Keys.Clone() ) {
        if ( -not $Params[$key] )  { $Params.Remove($key) }
    }

    return Invoke-VSARestMethod @Params
}