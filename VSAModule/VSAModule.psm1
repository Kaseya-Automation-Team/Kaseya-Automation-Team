<#
   Kaseya VSA9 REST API Wrapper
   Version 0.1.5
   Author: Vladislav Semko
   Description:
   VSAModule for Kaseya VSA 9 REST API is a PowerShell module that provides cmdlets for interacting with the Kaseya VSA 9 platform via its REST API.
   This module simplifies the process of automating tasks, retrieving data, and managing resources within the Kaseya VSA 9 environment directly from PowerShell scripts or the command line.

    Key Features:
    - Intuitive cmdlets for common operations such as retrieving information about assets and managing entities.
    - Secure authentication methods, including support for API tokens, ensuring the confidentiality of sensitive information.
    - Examples to help users get started quickly and effectively integrate Kaseya VSA 9 functionality into their automation workflows.

    This module is distributed under the MIT License, allowing for free use, modification, and distribution by users.
#>

# Import additional functions from Private and Public folders
$scriptPaths = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1", "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue

foreach ($script in $scriptPaths) {
    try {
        . $script.FullName
    } catch {
        Write-Warning "Failed to import function $($script.FullName): $_"
    }
}

#region Class VSAConnection
Add-Type -TypeDefinition @'
using System;

public class VSAConnection
{
    private string _URI;
    private string _UserName;
    private string _Token;
    private string _PAT;
    private bool _IgnoreCertificateErrors;
    private DateTime _SessionExpiration;
    private static bool _IsPersistent;

    public string URI { get { return _URI; } }
    public string UserName { get { return _UserName; } }
    public string Token { get { return _Token; } }
    public string PAT { get { return _PAT; } }
    public bool IgnoreCertificateErrors { get { return _IgnoreCertificateErrors; } }
    public DateTime SessionExpiration { get { return _SessionExpiration; } }
    public static bool IsPersistent { get { return _IsPersistent; } }

    public VSAConnection(
        string uri,
        string userName,
        string token,
        string pat,
        DateTime sessionExpiration,
        bool ignoreCertificateErrors,
        bool isPersistent)
    {
        _URI = uri;
        _UserName = userName;
        _Token = token;
        _PAT = pat;
        _SessionExpiration = sessionExpiration;
        _IgnoreCertificateErrors = ignoreCertificateErrors;
        _IsPersistent = isPersistent;

        if (isPersistent)
        {
            SetPersistent(isPersistent);
        }
    }

    public string GetStatus()
    {
        return !string.IsNullOrEmpty(_Token) ? "Open" : "Closed";
    }

    public void UpdateToken(string newToken)
    {
        _Token = newToken;
        if (_IsPersistent)
        {
            SetPersistent(true);
        }
    }

    public void UpdateSessionExpiration(DateTime newSessionExpiration)
    {
        _SessionExpiration = newSessionExpiration;
        if (_IsPersistent)
        {
            SetPersistent(true);
        }
    }

    public void SetPersistent(bool isPersistent)
    {
        _IsPersistent = isPersistent;
        if (_IsPersistent)
        {
            string serial = string.Format("{0}\t{1}\t{2}\t{3}\t{4}\t{5}\t{6}",
                _URI,
                _Token,
                _PAT,
                _UserName,
                _SessionExpiration.ToString("o"),
                _IgnoreCertificateErrors,
                _IsPersistent);
            string encoded = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(serial));
            Environment.SetEnvironmentVariable("VSAConnection", encoded);
        }
        else
        {
            Environment.SetEnvironmentVariable("VSAConnection", null);
        }
    }

    public static string GetPersistentURI()
    {
        return GetPersistentField(0);
    }

    public static string GetPersistentToken()
    {
        return GetPersistentField(1);
    }

    public static string GetPersistentPAT()
    {
        return GetPersistentField(2);
    }

    public static string GetPersistentUserName()
    {
        return GetPersistentField(3);
    }

    public static DateTime GetPersistentSessionExpiration()
    {
        DateTime sessionExpiration;
        return DateTime.TryParse(GetPersistentField(4), out sessionExpiration) ? sessionExpiration : DateTime.MinValue;
    }

    public static bool GetIgnoreCertErrors()
    {
        bool ignoreCertErrors;
        return bool.TryParse(GetPersistentField(5), out ignoreCertErrors) ? ignoreCertErrors : false;
    }

    private static string GetPersistentField(int index)
    {
        if (_IsPersistent)
        {
            string encoded = Environment.GetEnvironmentVariable("VSAConnection");
            if (encoded != null)
            {
                string serial = System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(encoded));
                string[] separateValues = serial.Split('\t');
                if (separateValues.Length > index)
                {
                    return separateValues[index];
                }
            }
        }
        return string.Empty;
    }

    // Static method to update session expiration
    public static void UpdatePersistentSessionExpiration(DateTime newSessionExpiration)
    {
        UpdatePersistentField(4, newSessionExpiration.ToString("o"));
    }

    // Static method to update token
    public static void UpdatePersistentToken(string newToken)
    {
        UpdatePersistentField(1, newToken);
    }

    // Helper method to update a specific field in the environment variable
    private static void UpdatePersistentField(int index, string newValue)
    {
        if (_IsPersistent)
        {
            string encoded = Environment.GetEnvironmentVariable("VSAConnection");
            if (encoded != null)
            {
                string serial = System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(encoded));
                string[] separateValues = serial.Split(new[] { '\t' }, StringSplitOptions.None);
                if (separateValues.Length > index)
                {
                    separateValues[index] = newValue;
                    string updatedSerial = string.Join("\t", separateValues);
                    string updatedEncoded = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(updatedSerial));
                    Environment.SetEnvironmentVariable("VSAConnection", updatedEncoded);
                }
            }
        }
    }
}
'@
#endregion Class VSAConnection

#region Class TrustAllCertsPolicy
# Define a TrustAllCertsPolicy class to handle certificate validation
Add-Type -TypeDefinition @'
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy
    {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem)
        {
                return true;
        }
    }
'@
#endregion Class TrustAllCertsPolicy

#region function New-VSAConnection
function New-VSAConnection {
<#
.SYNOPSIS
    Creates a VSAConnection object.
.DESCRIPTION
    Creates a VSAConnection object that encapsulates access token as well as additional connection information.
    Optionally makes the connection object persistent.
.PARAMETER VSAServer
    Specifies the address of the VSA Server to connect.
.PARAMETER Credential
    Specifies the existing VSA user credentials that are allowed to connect to the VSA through the REST API.
.PARAMETER AuthSuffix
    Specifies the URI suffix for the authorization endpoint, if it differs from the default '/API/v1.0/Auth'.
.PARAMETER IgnoreCertificateErrors
    Indicates whether to allow self-signed certificates. Default is false.
.PARAMETER SetPersistent
    Indicates whether to make the VSAConnection object persistent during the session so that module cmdlets will use the connection information implicitly.
.EXAMPLE
    # Example 1: Creating a VSAConnection object with persistent setting
    # This command creates a VSAConnection object to connect to a VSA server with the provided credentials and makes the connection persistent during the session.
    New-VSAConnection -VSAServer "https://vsaserver.example.com" -Credential (Get-Credential) -SetPersistent

    # Example 2: Creating a VSAConnection object with custom authorization URI suffix
    # This command creates a VSAConnection object and ignores certificate errors.
    New-VSAConnection -VSAServer "https://vsaserver.example.com" -Credential (Get-Credential) -IgnoreCertificateErrors
.INPUTS
    Accepts response object from the authorization API.
.OUTPUTS
    VSAConnection.
    New-VSAConnection returns an object of VSAConnection type that encapsulates access token as well as additional connection information.
#>

    [cmdletbinding()]
    [OutputType([VSAConnection])]
    param(
        [parameter(
            Mandatory = $true,
            Position = 0)]
        [ValidateScript(
            {if ($_ -match '^http(s)?:\/\/([\w.-]+(?:\.[\w\.-]+)+|((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}|((([0-9a-fA-F]){1,4})\:){7}([0-9a-fA-F]){1,4}|localhost)(\/)?$') {$true}
            else {Throw "$_ is invalid. Enter a valid address that begins with https://"}}
            )]
        [String]$VSAServer,

        [parameter(Mandatory = $false)]
        [PSCredential] $Credential,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $AuthSuffix = 'API/v1.0/Auth',

        [parameter(Mandatory=$false)]
        [switch] $IgnoreCertificateErrors,

        [parameter(Mandatory=$false)]
        [Alias('MakePersistent')]
        [switch] $SetPersistent
    )

    #region Apply Certificate Policy
    if ($IgnoreCertificateErrors) {
        Write-Warning -Message "Ignoring certificate errors may expose your connection to potential security risks.`nBy enabling this option, you accept all associated risks, and any consequences are solely your responsibility.`n"
    }
    #endregion Apply Certificate Policy

    if (-not $Credential) {
        $Credential = Get-Credential -Message "Please provide Username and Personal Authentication Token"
    }

    $UserName = $Credential.UserName

    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)
    $PAT = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$UserName`:$PAT"))
    $AuthString  = "Basic $Encoded"

    $VSAServerUri = New-Object System.Uri -ArgumentList $VSAServer
    $AuthEndpoint = [System.Uri]::new($VSAServerUri, $AuthSuffix) | Select-Object -ExpandProperty AbsoluteUri

    $LogMessage = "Attempting authentication for user '$UserName' on VSA server '$VSAServer'."
    
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        Write-Verbose $LogMessage
    }
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug $LogMessage
    }

    $AuthParams = @{
        URI                     = $AuthEndpoint
        AuthString              = $AuthString
        IgnoreCertificateErrors = $IgnoreCertificateErrors
        ErrorAction             = 'Stop'
    }

    $result =  try {
        Get-RequestData @AuthParams | Select-Object -ExpandProperty Result
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Server '$VSAServer' returned error`nUser '$UserName'`n$errorMessage"
        return
    } 

    if ([string]::IsNullOrEmpty($result)) {
        throw "Failed to retrieve authentication response from '$VSAServer' for user '$username'`n$("Response Code: '$($response.ResponseCode)'`nResponse Error: '$($response.Error)'`n")"
    } else {
        $SessionExpiration = [DateTime]::ParseExact($result.SessionExpiration, "yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture)
        $SessionExpiration = $SessionExpiration.AddMinutes($result.OffSetInMinutes)
        $VSAConnection = [VSAConnection]::new($VSAServer, $result.UserName, $result.Token, $PAT, $SessionExpiration, $IgnoreCertificateErrors, $SetPersistent)

        $LogMessage = "`tUser '$UserName' authenticated on VSA server '$VSAServer'.`n`tSession token expiration: $SessionExpiration (UTC).`n"
        Write-Host $LogMessage
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            Write-Verbose $LogMessage
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug $LogMessage
            Write-Debug "New-VSAConnection result: '$($result | ConvertTo-Json)'"
        }
        if ($SetPersistent) {
            $LogMessage = "`tConnection to server '$VSAServer' set Persistent during the current session so the VSAModule's cmdlets can use the connection implicitly.`n"
            Write-Host $LogMessage
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                Write-Verbose $LogMessage
            }
            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                Write-Debug $LogMessage
            }
        }
    }

    if ($SetPersistent) {
        $VSAConnection.SetPersistent($true)
    } else {
        Write-Output $VSAConnection
    }
}
#endregion function New-VSAConnection

Export-ModuleMember -Function New-VSAConnection

# Initialize the $URISuffixMap globally (at the module level)
$URISuffixGetMap = @{
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
    'Get-VSAAgentPackage'   = 'api/v1.0/assetmgmt/assets/packages'
    'Get-VSAAgentPackages'  = 'api/v1.0/assetmgmt/assets/packages'
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
}

$URISuffixGetByIdMap = @{
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
}

$URISuffixRemoveMap = @{
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
}

# Automatically Create Aliases on Module Load

$URISuffixGetMap.Keys | ForEach-Object {
    New-Alias -Name $_ -Value Get-VSAItem -Force
}
$URISuffixGetByIdMap.Keys | ForEach-Object {
    New-Alias -Name $_ -Value Get-VSAItemById -Force
}
$URISuffixRemoveMap.Keys | ForEach-Object {
    New-Alias -Name $_ -Value Remove-VSAItem -Force
}

# Export the functions and aliases
Export-ModuleMember -Function Get-VSAItem -Alias $($URISuffixGetMap.Keys)
Export-ModuleMember -Function Get-VSAItemById -Alias $($URISuffixGetByIdMap.Keys)
Export-ModuleMember -Function Remove-VSAItem -Alias $($URISuffixRemoveMap.Keys)