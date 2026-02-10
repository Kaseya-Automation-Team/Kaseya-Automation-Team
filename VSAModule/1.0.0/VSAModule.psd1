@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'VSAModule.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID = 'd0697c18-0238-4427-bd14-1dace2ba29a7'

    # Author of this module
    Author = 'Vladislav.Semko'

    # Company or vendor of this module
    CompanyName = 'Kaseya'

    # Copyright statement for this module
    Copyright = '(c) 2026 Kaseya ProServ.'

    # Description of the functionality provided by this module
    Description = 'PowerShell wrapper module for the Kaseya VSA 9 REST API. Provides cmdlets for automating tasks, retrieving data, and managing resources within the Kaseya VSA 9 environment.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Get-RequestData'
        'Invoke-VSARequest'
        'Get-VSAItem'
        'Get-VSAItemById'
        'Update-VSAConnection'
        'Remove-VSAItem'
        'New-VSAConnection'
        'Add-VSAItemToScope'
        'Add-VSASDStaffToTicket'
        'Add-VSAUserToRole'
        'Clear-VSATenantRoleType'
        'Close-VSAAlarm'
        'Copy-VSAMGStructure'
        'Copy-VSAOrgStructure'
        'Disable-VSATenant'
        'Disable-VSAUser'
        'Enable-VSATenantModule'
        'Enable-VSATenantRoleType'
        'Enable-VSAUser'
        'Get-VSAAdminTask'
        'Get-VSAAgent'
        'Get-VSAAgentUptime'
        'Get-VSAAlarm'
        'Get-VSAAPFile'
        'Get-VSAAsset'
        'Get-VSAAudit'
        'Get-VSAAuditDocument'
        'Get-VSACustomExtensionFSItem'
        'Get-VSACustomField'
        'Get-VSADepartment'
        'Get-VSAMachineGroup'
        'Get-VSAOrganization'
        'Get-VSAPatchMissing'
        'Get-VSARoleType'
        'Get-VSAScope'
        'Get-VSASDTicket'
        'Get-VSASDTicketCustomField'
        'Get-VSASessionTimer'
        'Get-VSAStaff'
        'Get-VSAStorageContent'
        'Get-VSATenantModuleLicense'
        'Get-VSATenantRoletypeFunclist'
        'Get-VSAThirdAppNotification'
        'Get-VSATicket'
        'Get-VSAUser'
        'Get-VSAWorkOrderItem'
        'Move-VSADocument'
        'New-VSAAdminTask'
        'New-VSAAgentInstallLink'
        'New-VSAAgentInstallPkg'
        'New-VSAAgentNote'
        'New-VSAAPScheduled'
        'New-VSACustomExtensionFolder'
        'New-VSACustomField'
        'New-VSADepartment'
        'New-VSADocumentFolder'
        'New-VSALCAuditLog'
        'New-VSAMachineGroup'
        'New-VSANotification'
        'New-VSAOrganization'
        'New-VSAPatchScan'
        'New-VSARole'
        'New-VSAScheduleAuditBaseLine'
        'New-VSAScope'
        'New-VSASDTicketNote'
        'New-VSAStaff'
        'New-VSATenant'
        'New-VSATenantRoleType'
        'New-VSAThirdAppNotification'
        'Publish-VSACustomExtensionFile'
        'Publish-VSADocument'
        'Remove-VSAAgent'
        'Remove-VSACustomExtensionFolder'
        'Remove-VSACustomField'
        'Remove-VSADocument'
        'Remove-VSAGetFile'
        'Remove-VSAPatch'
        'Remove-VSAPatchIgnore'
        'Remove-VSASessionTimer'
        'Remove-VSATenantModule'
        'Remove-VSAThirdAppNotification'
        'Remove-VSAUser'
        'Rename-VSADocument'
        'Rename-VSAMachineGroup'
        'Rename-VSATenant'
        'Send-VSAEmail'
        'Set-VSAAgentName'
        'Set-VSAAuditSchedule'
        'Set-VSAPatchIgnore'
        'Set-VSAScheduleAuditSysInfo'
        'Set-VSATenantModuleLicense'
        'Set-VSATenantModuleUsageType'
        'Set-VSATenantRoletypeLimit'
        'Start-VSAAP'
        'Start-VSAAuditBaseLine'
        'Start-VSAAuditLatest'
        'Start-VSAAuditSysInfo'
        'Start-VSAPatchScan'
        'Start-VSAPatchUpdate'
        'Start-VSAPurchaseWarrantyExpirationDatesUpdate'
        'Stop-VSAPatchProcess'
        'Stop-VSAScheduledAP'
        'Test-VSASSL'
        'Update-VSAAgentCheckinCtl'
        'Update-VSAAgentNote'
        'Update-VSAAgentProfile'
        'Update-VSAAgentTempDir'
        'Update-VSAAPQL'
        'Update-VSAAPSettings'
        'Update-VSACustomField'
        'Update-VSADepartment'
        'Update-VSAInfoMsg'
        'Update-VSAOrganization'
        'Update-VSASDCustomField'
        'Update-VSASDTicketPriority'
        'Update-VSASDTicketStatus'
        'Update-VSAStaff'
        'Update-VSAThirdApp'
        'Update-VSAUser'
        'Update-VSAWarrantyExpiration'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @(
        # Dynamic aliases created for Get-VSAItem wrapper (retrieves collections)
        'Get-VSAActivityType'
        'Get-VSAActivityTypes'
        'Get-VSAAgentGW'
        'Get-VSAAgentNote'
        'Get-VSAAgentPackage'
        'Get-VSAAgentPackages'
        'Get-VSAAgentView'
        'Get-VSAAgentViews'
        'Get-VSAAP'
        'Get-VSAAPPortal'
        'Get-VSAAPQL'
        'Get-VSAAPSettings'
        'Get-VSAAssetType'
        'Get-VSAAssetTypes'
        'Get-VSAAuditSum'
        'Get-VSACBServer'
        'Get-VSACBServers'
        'Get-VSACBVM'
        'Get-VSACBWS'
        'Get-VSACustomer'
        'Get-VSACustomers'
        'Get-VSAEnvironment'
        'Get-VSAFunction'
        'Get-VSAFunctions'
        'Get-VSAInfoMsg'
        'Get-VSASD'
        'Get-VSASessionId'
        'Get-VSATenant'
        'Get-VSATenants'
        'Get-VSAWorkOrderType'
        'Get-VSAWorkOrderTypes'
        # Dynamic aliases created for Get-VSAItemById wrapper (retrieves specific items by ID)
        'Get-VSAAgent2FA'
        'Get-VSAAgentInView'
        'Get-VSAAgentsInView'
        'Get-VSAAgentLog'
        'Get-VSAAgentOnNet'
        'Get-VSAAgentsOnNet'
        'Get-VSAAgentPkgPage'
        'Get-VSAAgentRCNotify'
        'Get-VSAAgentSettings'
        'Get-VSAAlarmLog'
        'Get-VSAAPHistory'
        'Get-VSAAPLog'
        'Get-VSAAppEventLog'
        'Get-VSAAPScheduled'
        'Get-VSAScheduledAP'
        'Get-VSACfgChangeLog'
        'Get-VSACfgChangesLog'
        'Get-VSADirEventLog'
        'Get-VSADNSEventLog'
        'Get-VSAIEEventLog'
        'Get-VSAKaseyaRCLog'
        'Get-VSALegacyRCLog'
        'Get-VSALogMonitoringLog'
        'Get-VSAModuleActivated'
        'Get-VSAModuleStatus'
        'Get-VSAMonitorLog'
        'Get-VSANetStatLog'
        'Get-VSAPatchHistory'
        'Get-VSAPatchStatus'
        'Get-VSASDCategory'
        'Get-VSASDCategories'
        'Get-VSASDCustomField'
        'Get-VSASDCustomFields'
        'Get-VSASDPriority'
        'Get-VSASDPriorities'
        'Get-VSASDTicketNote'
        'Get-VSASDTicketNotes'
        'Get-VSASDTicketStatus'
        'Get-VSASecurityEventLog'
        'Get-VSASystemEventLog'
        'Get-VSAThirdAppStatus'
        'Get-VSAWorkOrder'
        'Get-VSAWorkOrders'
        # Dynamic aliases created for Remove-VSAItem wrapper (removes specific items by ID)
        'Remove-VSAAgentInstallPkg'
        'Remove-VSAAgentNote'
        'Remove-VSAAPQL'
        'Remove-VSAAsset'
        'Remove-VSADepartment'
        'Remove-VSAInfoMsg'
        'Remove-VSAMachineGroup'
        'Remove-VSAOrganization'
        'Remove-VSARole'
        'Remove-VSAScope'
        'Remove-VSAStaff'
        'Remove-VSATenant'
        'Remove-VSATenantRoleType'
        # Aliases for specific public functions
        'Add-VSASDStaff'
        'Copy-VSAMachineGroupStructure'
        'Get-VSAAlarms'
        'Get-VSAAgentsUptime'
        'Get-VSACustomExtensionFSItems'
    )

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Kaseya', 'VSA', 'VSA9', 'REST-API', 'Automation', 'API-Wrapper')

            # A URL to the license for this module.
            LicenseUri = 'https://raw.githubusercontent.com/Kaseya-Automation-Team/Kaseya-Automation-Team/main/VSAModule/LICENSE.txt'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/Kaseya-Automation-Team/Kaseya-Automation-Team/tree/main/VSAModule'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/Kaseya-Automation-Team/Kaseya-Automation-Team/tree/main/VSAModule/README.md'

            # Flag indicating whether this module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    HelpInfoUri = './VSAModule-help.xml'

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
