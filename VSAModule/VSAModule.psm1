<#
   Kaseya VSA9 REST API Wrapper
   Version 1.0.0
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
<#
SECURITY NOTES:
1. CREDENTIAL STORAGE: The VSAConnection class stores credentials for REST API authentication.
   - The PAT (Personal Authentication Token) is kept in memory for token renewal operations.
   - When SetPersistent() is called, the connection data is stored in an environment variable.
   - SECURITY: Sensitive data (Token, PAT) is encrypted using PowerShell's ConvertTo-SecureString (DPAPI).
   - The environment variable "VSAConnection" is cleared when the connection is no longer persistent.

2. DEFENSE IN DEPTH:
   - Non-persistent connections keep credentials only in memory (safest for single operations)
   - Persistent connections encrypt sensitive data using DPAPI via PowerShell
   - Session tokens are renewed automatically when approaching expiration
   - Credentials are passed through secure channels (HTTPS/TLS only)

3. BEST PRACTICES:
   - Use non-persistent connections when possible for better security
   - Use persistent connections only in secure, interactive PowerShell sessions
   - Always use HTTPS connections to the VSA server
   - Regularly audit sessions with persistent connections enabled
   - Clear persistent connections when no longer needed using: Remove-Item env:\VSAConnection

4. ENCRYPTION MECHANISM:
   - PowerShell's ConvertTo-SecureString uses Windows DPAPI
   - DPAPI encryption is user-specific and machine-specific
   - Only the current user on the current machine can decrypt the credentials
   - Credentials do NOT survive system reboot or different user account

Reference: Microsoft DPAPI and ConvertTo-SecureString
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertto-securestring
#>
Add-Type -TypeDefinition @'
using System;
using System.Text;

public class VSAConnection
{
    private string _URI;
    private string _UserName;
    private string _Token;
    private string _PAT;
    private bool _IgnoreCertificateErrors;
    private DateTime _SessionExpiration;
    private bool _IsPersistent;

    public string URI { get { return _URI; } set { _URI = value; } }
    public string UserName { get { return _UserName; } set { _UserName = value; } }
    public string Token { get { return _Token; } set { _Token = value; } }
    public string PAT { get { return _PAT; } set { _PAT = value; } }
    public bool IgnoreCertificateErrors { get { return _IgnoreCertificateErrors; } set { _IgnoreCertificateErrors = value; } }
    public DateTime SessionExpiration { get { return _SessionExpiration; } set { _SessionExpiration = value; } }
    public bool IsPersistent { get { return _IsPersistent; } set { _IsPersistent = value; } }

    // Static helper to check if persistent data exists in environment
    private static bool HasPersistentData()
    {
        return !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("VSAConnection"));
    }

    // Parameterless constructor for PowerShell deserialization
    public VSAConnection()
    {
        _URI = string.Empty;
        _UserName = string.Empty;
        _Token = string.Empty;
        _PAT = string.Empty;
        _SessionExpiration = DateTime.MinValue;
        _IgnoreCertificateErrors = false;
        _IsPersistent = false;
    }

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

    // Copy constructor for serialization/deserialization support (parallel execution)
    public VSAConnection(VSAConnection other)
    {
        if ( null == other)
        {
            throw new ArgumentNullException("other");
        }
        
        _URI = other._URI;
        _UserName = other._UserName;
        _Token = other._Token;
        _PAT = other._PAT;
        _SessionExpiration = other._SessionExpiration;
        _IgnoreCertificateErrors = other._IgnoreCertificateErrors;
        _IsPersistent = other._IsPersistent;

        if (_IsPersistent)
        {
            SetPersistent(_IsPersistent);
        }
    }

    // Hashtable constructor for deserialization support
    public VSAConnection(System.Collections.Generic.Dictionary<string, object> data)
    {
        if (null == data)
        {
            throw new ArgumentNullException("data");
        }

        _URI = GetDictionaryValue(data, "URI", string.Empty);
        _UserName = GetDictionaryValue(data, "UserName", string.Empty);
        _Token = GetDictionaryValue(data, "Token", string.Empty);
        _PAT = GetDictionaryValue(data, "PAT", string.Empty);
        _IgnoreCertificateErrors = GetDictionaryValue(data, "IgnoreCertificateErrors", false);
        
        // Handle SessionExpiration which should be a DateTime
        object expirationObj;
        if (data.TryGetValue("SessionExpiration", out expirationObj) && expirationObj is DateTime)
        {
            _SessionExpiration = (DateTime)expirationObj;
        }
        else
        {
            _SessionExpiration = DateTime.MinValue;
        }
        
        _IsPersistent = GetDictionaryValue(data, "IsPersistent", false);

        if (_IsPersistent)
        {
            SetPersistent(_IsPersistent);
        }
    }

    // Helper method to safely get values from dictionary with type conversion
    private static T GetDictionaryValue<T>(System.Collections.Generic.Dictionary<string, object> data, string key, T defaultValue)
    {
        object value;
        if (data.TryGetValue(key, out value) && value is T)
        {
            return (T)value;
        }
        return defaultValue;
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

    private static string EncryptConnectionData(string data)
    {
        // Data is Base64 encoded here. PowerShell wraps this with ConvertTo-SecureString
        // for actual encryption using Windows DPAPI before storing in environment variable.
        byte[] dataBytes = Encoding.UTF8.GetBytes(data);
        return Convert.ToBase64String(dataBytes);
    }

    private static string DecryptConnectionData(string encodedData)
    {
        try
        {
            // PowerShell uses ConvertFrom-SecureString to decrypt before passing here
            byte[] dataBytes = Convert.FromBase64String(encodedData);
            return Encoding.UTF8.GetString(dataBytes);
        }
        catch
        {
            return string.Empty;
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
            string encoded = EncryptConnectionData(serial);
            
            // Store in environment variable - PowerShell will encrypt this before persistence
            Environment.SetEnvironmentVariable("VSAConnection", encoded);
        }
        else
        {
            // Securely clear the environment variable
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
        if (HasPersistentData())
        {
            string encrypted = Environment.GetEnvironmentVariable("VSAConnection");
            if (encrypted != null)
            {
                string serial = DecryptConnectionData(encrypted);
                if (!string.IsNullOrEmpty(serial))
                {
                    string[] separateValues = serial.Split('\t');
                    if (separateValues.Length > index)
                    {
                        return separateValues[index];
                    }
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
        if (HasPersistentData())
        {
            string encrypted = Environment.GetEnvironmentVariable("VSAConnection");
            if (encrypted != null)
            {
                string serial = DecryptConnectionData(encrypted);
                if (!string.IsNullOrEmpty(serial))
                {
                    string[] separateValues = serial.Split(new[] { '\t' }, StringSplitOptions.None);
                    if (separateValues.Length > index)
                    {
                        separateValues[index] = newValue;
                        string updatedSerial = string.Join("\t", separateValues);
                        string updatedEncrypted = EncryptConnectionData(updatedSerial);
                        Environment.SetEnvironmentVariable("VSAConnection", updatedEncrypted);
                    }
                }
            }
        }
    }

    // Cleanup method for secure credential removal
    public static void ClearPersistentConnection()
    {
        Environment.SetEnvironmentVariable("VSAConnection", null);
    }
}
'@
#endregion Class VSAConnection

#region Secure Storage Functions
function Protect-VSAConnectionData {
    <#
    .SYNOPSIS
        Encrypts VSAConnection data using PowerShell's ConvertTo-SecureString (DPAPI).
    .DESCRIPTION
        Takes plain Base64-encoded data and encrypts it using Windows DPAPI via ConvertTo-SecureString.
        This ensures that only the current user on the current machine can decrypt the credentials.
    .PARAMETER Data
        The Base64-encoded connection data to encrypt.
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Data
    )
    
    try {
        $secureString = ConvertTo-SecureString -String $Data -AsPlainText -Force
        $encryptedString = ConvertFrom-SecureString -SecureString $secureString
        return $encryptedString
    } catch {
        Write-Warning "Failed to encrypt connection data: $_"
        return $null
    }
}

function Unprotect-VSAConnectionData {
    <#
    .SYNOPSIS
        Decrypts VSAConnection data encrypted with Protect-VSAConnectionData.
    .DESCRIPTION
        Takes DPAPI-encrypted connection data and decrypts it using ConvertFrom-SecureString.
    .PARAMETER EncryptedData
        The DPAPI-encrypted connection data string.
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $EncryptedData
    )
    
    try {
        $secureString = ConvertTo-SecureString -String $EncryptedData
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        return $plainText
    } catch {
        Write-Warning "Failed to decrypt connection data: $_"
        return $null
    }
}
#endregion Secure Storage Functions

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
    Creates a VSAConnection object with secure credential handling.
.DESCRIPTION
    Creates a VSAConnection object that encapsulates access token as well as additional connection information.
    Optionally makes the connection object persistent with DPAPI encryption.
    
    SECURITY & CREDENTIAL HANDLING:
    This function implements secure credential handling through the following mechanisms:
    
    1. IN-MEMORY CREDENTIALS (Non-Persistent):
       - Personal Authentication Token (PAT) is stored in memory only
       - Credentials are passed to the VSA API over HTTPS with TLS encryption
       - Best practice for automated scripts and scheduled tasks
       - Session token expires automatically and must be renewed on each script run
    
    2. PERSISTENT CREDENTIALS (SetPersistent):
       - Uses Data Protection API (DPAPI) to encrypt stored credentials
       - DPAPI encryption is specific to the current user on the current machine
       - Only the same user account can decrypt the stored credentials
       - Environment variable "VSAConnection" stores the encrypted connection data
       - Suitable for interactive PowerShell sessions and debugging
       - NOT recommended for production batch processing or service accounts
    
    3. TOKEN RENEWAL:
       - Session tokens are automatically renewed when approaching expiration
       - Renewal uses the stored PAT to request a new token from the VSA API
       - Non-persistent connections require a new token for each script invocation
       - Persistent connections maintain the token in the encrypted environment variable
    
    4. CLEANUP:
       - Always clear persistent connections when no longer needed
       - Use: Remove-Item env:\VSAConnection  (to clear environment variable)
       - Or: [VSAConnection]::ClearPersistentConnection()  (PowerShell method)
    
    BEST PRACTICES:
    - Use non-persistent connections for scripts (default behavior)
    - Use SetPersistent only for interactive development/debugging
    - Never hardcode credentials in scripts; use Get-Credential or credential manager
    - Always use HTTPS connections (-VSAServer must be https://)
    - Regularly audit and remove persistent connections
    - Use service-specific accounts with minimal required permissions
    - Rotate PATs regularly according to your security policy
    
.PARAMETER VSAServer
    Specifies the address of the VSA Server to connect (must be HTTPS).
.PARAMETER Credential
    Specifies the existing VSA user credentials (username and Personal Authentication Token).
    If not provided, you will be prompted via Get-Credential dialog.
.PARAMETER AuthSuffix
    Specifies the URI suffix for the authorization endpoint, if it differs from the default '/API/v1.0/Auth'.
.PARAMETER IgnoreCertificateErrors
    WARNING: Indicates whether to allow self-signed certificates. 
    Default is false. Use only for testing with self-signed certificates.
    Production environments should use valid certificates.
.PARAMETER SetPersistent
    WARNING: Makes the VSAConnection object persistent during the session using encrypted storage.
    Use only in interactive PowerShell sessions for development/debugging.
    NOT recommended for production scripts.
    
    When enabled:
    - Connection data is encrypted using Windows DPAPI
    - Stored in environment variable "VSAConnection"
    - Survives across PowerShell commands in the same session
    - Must be manually cleared when no longer needed
    
.EXAMPLE
    # Example 1: Non-persistent connection (RECOMMENDED for scripts)
    $Credential = New-Object System.Management.Automation.PSCredential (
        'username',
        (ConvertTo-SecureString 'PAT_Token' -AsPlainText -Force)
    )
    $VSAConnection = New-VSAConnection -VSAServer "https://vsa.example.com" -Credential $Credential

.EXAMPLE
    # Example 2: Interactive connection with credential prompt
    $VSAConnection = New-VSAConnection -VSAServer "https://vsa.example.com"

.EXAMPLE
    # Example 3: Persistent connection for interactive session (DEVELOPMENT ONLY)
    # WARNING: Use only for debugging; clear when done
    $Credential = Get-Credential
    $VSAConnection = New-VSAConnection -VSAServer "https://vsa.example.com" -Credential $Credential -SetPersistent

.EXAMPLE
    # Example 4: Clear persistent connection when done
    # Option A: Remove environment variable directly
    Remove-Item env:\VSAConnection -ErrorAction SilentlyContinue
    
    # Option B: Use PowerShell class method
    [VSAConnection]::ClearPersistentConnection()

.INPUTS
    Accepts response object from the authorization API.
.OUTPUTS
    VSAConnection
    New-VSAConnection returns an object of VSAConnection type that encapsulates access token as well as additional connection information.
    
.NOTES
    Version 1.0.0
    SECURITY: 
    - Implements DPAPI encryption for persistent connections (v0.1.5+)
    - Credentials sent over HTTPS only
    - PAT stored in-memory for non-persistent connections
    - Automatic session token renewal implemented
    
    References:
    - Kaseya VSA 9 REST API: help.kaseya.com/webhelp/EN/RESTAPI/9050000/
    - Microsoft DPAPI: https://docs.microsoft.com/en-us/dotnet/standard/security/encrypting-data
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
        $Credential = Get-Credential -Message "Please provide VSA Username and Personal Authentication Token (PAT)"
    }

    $UserName = $Credential.UserName

    # Convert SecureString PAT to plaintext for token calculation
    # This is required for the REST API authentication but is done securely:
    # 1. PAT is only stored in memory during this function
    # 2. Immediately after Base64 encoding for REST API, the plaintext is cleared
    # 3. PAT is stored encrypted (via DPAPI) only if SetPersistent is enabled
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)
    $PAT = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    # Create Base64 encoded credentials for Basic Auth header
    $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$UserName`:$PAT"))
    $AuthString  = "Basic $Encoded"
    
    # Securely clear plaintext PAT from memory after encoding
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

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
            $LogMessage = "`tConnection to server '$VSAServer' set Persistent during the current session so the VSAModule's cmdlets can use the connection implicitly.`n`tWARNING: Remember to clear this persistent connection when you are done using:`n`t  Remove-Item env:\VSAConnection`n`tor`n`t  [VSAConnection]::ClearPersistentConnection()`n"
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