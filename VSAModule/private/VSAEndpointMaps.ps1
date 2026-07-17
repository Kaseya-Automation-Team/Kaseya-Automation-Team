<#
    VSAModule endpoint + id maps (extracted from VSAModule.psm1 for readability).

    Dot-sourced by the module loader into module scope, so these $script:-scoped maps are visible to
    the data-driven dispatchers (Get-VSAItem / Get-VSAItemById / Remove-VSAItem), to the tenant
    cmdlets (Enable-VSATenantModule / Clear-VSATenantRoleType), and to the alias-creation block that
    still lives at the end of the .psm1.
#>
# Initialize the $URISuffixMap globally (at the module level)
$script:URISuffixGetMap = @{
    'Get-VSAAuditSum'       = 'api/v1.0/assetmgmt/audit'
    'Get-VSAAPSettings'     = 'api/v1.0/automation/agentprocs/quicklaunch/askbeforeexecuting'
    'Get-VSAAPQL'           = 'api/v1.0/automation/agentprocs/quicklaunch'
    'Get-VSAAPPortal'       = 'api/v1.0/automation/agentprocsportal'
    'Get-VSAAP'             = 'api/v1.0/automation/agentprocs'
    'Get-VSAAgentNote'      = 'api/v1.0/assetmgmt/agent/notes'
    'Get-VSAAgentGW'        = 'api/v1.0/assetmgmt/connectiongatewayips'
    'Get-VSAEnvironment'    = 'api/v1.0/environment'
    'Get-VSAInfoMsg'        = 'api/v1.0/infocenter/messages'
    'Get-VSACBVM'           = 'api/v1.0/kcb/virtualmachines'
    'Get-VSACBWS'           = 'api/v1.0/kcb/workstations'
    'Get-VSASD'             = 'api/v1.0/automation/servicedesks'
    'Get-VSASessionId'      = 'api/v1.0/authx'
    'Get-VSAActivityType'   = 'api/v1.0/system/customers/activitytypes'
    'Get-VSAActivityTypes'  = 'api/v1.0/system/customers/activitytypes'
    'Get-VSAWorkOrderType'  = 'api/v1.0/system/customers/resourcetypes'
    'Get-VSAWorkOrderTypes' = 'api/v1.0/system/customers/resourcetypes'
    'Get-VSAAssetType'      = 'api/v1.0/assetmgmt/assettypes'
    'Get-VSAAssetTypes'     = 'api/v1.0/assetmgmt/assettypes'
    'Get-VSAAgentView'      = 'api/v1.0/system/views'
    'Get-VSAAgentViews'     = 'api/v1.0/system/views'
    'Get-VSAAgentPackage'   = 'api/v1.0/assetmgmt/agents/packages'
    'Get-VSAAgentPackages'  = 'api/v1.0/assetmgmt/agents/packages'
    'Get-VSACBServer'       = 'api/v1.0/kcb/servers'
    'Get-VSACBServers'      = 'api/v1.0/kcb/servers'
    'Get-VSAFunction'       = 'api/v1.0/functions'
    'Get-VSAFunctions'      = 'api/v1.0/functions'
    'Get-VSACustomer'       = 'api/v1.0/system/customers'
    'Get-VSACustomers'      = 'api/v1.0/system/customers'
    'Get-VSARole'           = 'api/v1.0/system/roles'
    'Get-VSARoles'          = 'api/v1.0/system/roles'
    'Get-VSATenant'         = 'api/v1.0/tenant'
    'Get-VSATenants'        = 'api/v1.0/tenant'

    # --- Endpoints added in v1.4.0 (collection GETs) ---
    'Get-VSAAlertDefinition'             = 'api/v1.0/automation/alertdefinitions'
    'Get-VSARCService'                   = 'api/v1.0/assetmgmt/assets/getrcservices'
    'Get-VSARCMachine'                   = 'api/v1.0/assetmgmt/assets/rcmachines'
    'Get-VSATemporaryAgent'              = 'api/v1.0/assetmgmt/temporaryagents'
    'Get-VSATemporaryAgentConfig'        = 'api/v1.0/temporaryagent/config'
    'Get-VSAAgentActiveAdmin'            = 'api/v1.0/assetmgmt/agentactiveadmins'
    'Get-VSAAgentUserProfile'            = 'api/v1.0/assetmgmt/agent/settings/userprofiles'
    # Get-VSAAPList is NOT here: its endpoint returns XML (ScExport), not JSON, so it is a dedicated
    # function (public/Get-VSAAPList.ps1) rather than a JSON dispatcher alias (F-72).
    'Get-VSAAPProcHistory'               = 'api/v1.0/automation/agentprocs/proclist/history'
    'Get-VSAAPExecHistory'               = 'api/v1.0/automation/agentprocs/proclist/execution/history'
    'Get-VSAAPPrompt'                    = 'api/v1.0/automation/agentprocs/prompts'
    'Get-VSAAPVariable'                  = 'api/v1.0/automation/variables'
    'Get-VSAOrgType'                     = 'api/v1.0/system/orgs/types'
    'Get-VSAOrgLocation'                 = 'api/v1.0/system/orgs/locations'
    'Get-VSATenantLogonPolicy'           = 'api/v1.0/tenantmanagement/settings/logonpolicy'
    'Get-VSADocumentServiceAudit'        = 'api/v1.0/assetmgmt/documents/allservicesaudits'
    'Get-VSADocumentVolumeLabel'         = 'api/v1.0/assetmgmt/documents/allvolumelabels'
    'Get-VSADocumentServiceName'         = 'api/v1.0/assetmgmt/documents/distinctservicenames'
    'Get-VSADocumentDistinctVolumeLabel' = 'api/v1.0/assetmgmt/documents/distinctvolumelabels'
}

$script:URISuffixGetByIdMap = @{
    'Get-VSAAgent2FA'         = 'api/v1.0/assetmgmt/agent/{0}/twofasettingst'
    'Get-VSAAgentInView'      = 'api/v1.0/assetmgmt/agentsinview/{0}'
    'Get-VSAAgentsInView'     = 'api/v1.0/assetmgmt/agentsinview/{0}'
    'Get-VSAAgentLog'         = 'api/v1.0/assetmgmt/logs/{0}/agent'
    'Get-VSAAgentOnNet'       = 'api/v1.0/assetmgmt/agentsonnetwork/{0}'
    'Get-VSAAgentsOnNet'      = 'api/v1.0/assetmgmt/agentsonnetwork/{0}'
    'Get-VSAAgentPkgPage'     = 'api/v1.0/agent/{0}/deploypagecustomization'
    'Get-VSAAgentRCNotify'    = 'api/v1.0/remotecontrol/notifypolicy/{0}'
    'Get-VSAAlarmLog'         = 'api/v1.0/assetmgmt/logs/{0}/alarms'
    'Get-VSAAgentSettings'    = 'api/v1.0/assetmgmt/agent/{0}/settings'
    'Get-VSAAPHistory'        = 'api/v1.0/automation/agentprocs/{0}/history'
    'Get-VSAAPLog'            = 'api/v1.0/assetmgmt/logs/{0}/agentprocedure'
    'Get-VSAAppEventLog'      = 'api/v1.0/assetmgmt/logs/{0}/eventlog/application'
    'Get-VSAAPScheduled'      = 'api/v1.0/automation/agentprocs/{0}/scheduledprocs'
    'Get-VSAScheduledAP'      = 'api/v1.0/automation/agentprocs/{0}/scheduledprocs'
    'Get-VSACfgChangeLog'     = 'api/v1.0/assetmgmt/logs/{0}/configurationchanges'
    'Get-VSACfgChangesLog'    = 'api/v1.0/assetmgmt/logs/{0}/configurationchanges'
    'Get-VSADirEventLog'      = 'api/v1.0/assetmgmt/logs/{0}/eventlog/directoryservice'
    'Get-VSADNSEventLog'      = 'api/v1.0/assetmgmt/logs/{0}/eventlog/dnsserver'
    'Get-VSAIEEventLog'       = 'api/v1.0/assetmgmt/logs/{0}/eventlog/internetexplorer'
    'Get-VSAKaseyaRCLog'      = 'api/v1.0/assetmgmt/logs/{0}/remotecontrol'
    'Get-VSALegacyRCLog'      = 'api/v1.0/assetmgmt/logs/{0}/legacyremotecontrol'
    'Get-VSALogMonitoringLog' = 'api/v1.0/assetmgmt/logs/{0}/logmonitoring'
    'Get-VSAModuleActivated'  = 'api/v1.0/ismoduleactivated/{0}'
    'Get-VSAModuleStatus'     = 'api/v1.0/ismoduleinstalled/{0}'
    'Get-VSAMonitorLog'       = 'api/v1.0/assetmgmt/logs/{0}/monitoractions'
    'Get-VSANetStatLog'       = 'api/v1.0/assetmgmt/logs/{0}/networkstats'
    'Get-VSAPatchHistory'     = 'api/v1.0/assetmgmt/patch/{0}/history'
    'Get-VSAPatchStatus'      = 'api/v1.0/assetmgmt/patch/{0}/status'
    'Get-VSASDCategory'       = 'api/v1.0/automation/servicedesks/{0}/categories'
    'Get-VSASDCategories'     = 'api/v1.0/automation/servicedesks/{0}/categories'
    'Get-VSASDCustomField'    = 'api/v1.0/automation/servicedesks/{0}/customfields'
    'Get-VSASDCustomFields'   = 'api/v1.0/automation/servicedesks/{0}/customfields'
    'Get-VSASDPriority'       = 'api/v1.0/automation/servicedesks/{0}/priorities'
    'Get-VSASDPriorities'     = 'api/v1.0/automation/servicedesks/{0}/priorities'
    'Get-VSASDTicketNote'     = 'api/v1.0/automation/servicedesktickets/{0}/notes'
    'Get-VSASDTicketNotes'    = 'api/v1.0/automation/servicedesktickets/{0}/notes'
    'Get-VSASDTicketStatus'   = 'api/v1.0/automation/servicedesks/{0}/status'
    'Get-VSASecurityEventLog' = 'api/v1.0/assetmgmt/logs/{0}/eventlog/security'
    'Get-VSASystemEventLog'   = 'api/v1.0/assetmgmt/logs/{0}/eventlog/system'
    'Get-VSAThirdAppStatus'   = 'api/v1.0/thirdpartyapps/{0}/status'
    'Get-VSAWorkOrder'        = 'api/v1.0/system/customers/{0}/workorders'
    'Get-VSAWorkOrders'       = 'api/v1.0/system/customers/{0}/workorders'

    # --- Endpoints added in v1.4.0 (by-Id GETs) ---
    'Get-VSARCServiceByAsset'     = 'api/v1.0/assetmgmt/assets/{0}/getrcservices'
    'Get-VSARCMachineByView'      = 'api/v1.0/assetmgmt/assets/rcmachines/{0}'
    'Get-VSAAgentUpdateSchedule'  = 'api/v1.0/assetmgmt/agent/schedule/update/{0}'
    'Get-VSAAssetAudit'           = 'api/v1.0/assetmgmt/assets/{0}/agentaudit'
    'Get-VSAAssetById'            = 'api/v1.0/assetmgmt/assets/getassetbyid/{0}'
    'Get-VSAAPPromptById'         = 'api/v1.0/automation/agentprocs/{0}/prompts'
    'Get-VSASDTicketByDesk'       = 'api/v1.0/automation/servicedesks/{0}/tickets'
    'Get-VSASDTicketById'         = 'api/v1.0/automation/servicedesktickets/{0}'
    'Get-VSATenantDefaultSetting' = 'api/v1.0/tenantmanagement/settings/defaultsetting/{0}'
    'Get-VSACBStatus'             = 'api/v1.0/kcb/status/{0}'
    'Get-VSAFunctionById'         = 'api/v1.0/functions/{0}'
}

$script:URISuffixRemoveMap = @{
    'Remove-VSAAgentNote'       = 'api/v1.0/assetmgmt/agent/note/{0}'
    'Remove-VSAAgentInstallPkg' = 'api/v1.0/assetmgmt/agents/packages/{0}'
    'Remove-VSAAPQL'            = 'api/v1.0/automation/agentProcs/quicklaunch/{0}'
    'Remove-VSAAsset'           = 'api/v1.0/assetmgmt/assets/{0}'
    'Remove-VSADepartment'      = 'api/v1.0/system/departments/{0}'
    'Remove-VSAInfoMsg'         = 'api/v1.0/infocenter/messages/{0}'
    'Remove-VSAMachineGroup'    = 'api/v1.0/system/machinegroups/{0}'
    'Remove-VSAOrganization'    = 'api/v1.0/system/orgs/{0}'
    'Remove-VSARole'            = 'api/v1.0/system/roles/{0}'
    'Remove-VSAScope'           = 'api/v1.0/system/scopes/{0}'
    'Remove-VSAStaff'           = 'api/v1.0/system/staff/{0}'
    'Remove-VSATenant'          = 'api/v1.0/tenantmanagement/tenant?tenantId={0}'
    'Remove-VSATenantRoleType'  = 'api/v1.0/tenantmanagement/roletypes/{0}'

    # --- Endpoints added in v1.4.0 ---
    'Remove-VSATemporaryAgent'  = 'api/v1.0/temporaryagent/{0}'
}

# Module name -> Id map, shared by Enable-VSATenantModule and Remove-VSATenantModule (F-53):
# previously duplicated verbatim in both files.
$script:TenantModuleIdMap = @{
    'Agent'                          = 9
    'Agent Procedures'               = 3
    'Anti-Malware'                   = 97
    'Antivirus'                      = 95
    'AuthAnvil'                      = 115
    'Backup'                         = 12
    'Cloud Backup'                   = 54
    'Data Backup'                    = 34
    'Desktop Management: Migration'  = 29
    'Desktop Management: Policy'     = 30
    'Discovery'                      = 70
    'Kaseya System Patch'            = 0
    'Mobility'                       = 50
    'Network Monitoring'             = 47
    'Patch Management'               = 6
    'Policy'                         = 44
    'Service Billing'                = 42
    'Service Desk'                   = 18
    'Software Deployment'            = 53
    'Software Management'            = 60
    'System Backup and Recovery'     = 64
    'Time Tracking'                  = 41
    'vPro Management'                = 85
    'Web Service API'                = 57
}

# NOTE: the former $TenantRoleTypeIdMap (a hardcoded role-type name -> Id map) was removed in F-64.
# Role types are instance-specific -- an instance can carry custom and multi-tenant role types with
# instance-specific Ids -- so Enable-VSATenantRoleType / Clear-VSATenantRoleType / Set-VSATenantRoletypeLimit
# now resolve names to Ids at runtime via Get-VSARoleType instead of a static, always-stale map.
