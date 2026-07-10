<#
   Kaseya VSA9 REST API Wrapper
   Version 1.3.2
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

#region Class VSAConnection
<#
SECURITY NOTES:
1. CREDENTIAL STORAGE: The VSAConnection class stores credentials for REST API authentication.
   - The PAT (Personal Authentication Token) is kept in memory for token renewal operations.
   - When SetPersistent() is called, the connection data is stored in an environment variable.
   - SECURITY: Sensitive data (Token, PAT) is encrypted via ConvertTo-SecureString, using the
     platform-detected strategy selected once at import (F-60): DPAPI on Windows, or AES with a
     runtime-derived, never-stored key on Linux/macOS -- see the "Persistent-connection
     encryption strategy" region below for the full rationale.
   - The environment variable "VSAConnection" is cleared when the connection is no longer persistent.

2. DEFENSE IN DEPTH:
   - Non-persistent connections keep credentials only in memory (safest for single operations)
   - Persistent connections encrypt sensitive data using the platform-detected strategy (F-60)
   - Session tokens are renewed automatically when approaching expiration
   - Credentials are passed through secure channels (HTTPS/TLS only)

3. BEST PRACTICES:
   - Use non-persistent connections when possible for better security
   - Use persistent connections only in secure, interactive PowerShell sessions
   - Always use HTTPS connections to the VSA server
   - Regularly audit sessions with persistent connections enabled
   - Clear persistent connections when no longer needed using: Remove-Item env:\VSAConnection

4. ENCRYPTION MECHANISM:
   - Windows: ConvertTo-SecureString with no -Key uses DPAPI, user- and machine-specific; only
     the current user on the current machine can decrypt the credentials, and they do NOT survive
     system reboot or a different user account.
   - Linux/macOS (no DPAPI exists there): ConvertTo-SecureString -Key <32-byte AES key>, where the
     key is derived at runtime from per-user + per-machine identifiers and never stored. This is
     weaker than DPAPI -- there is no OS-backed secret store underneath it -- but is appropriate
     given the store itself is only a process-scoped environment variable (F-60).

Reference: Microsoft DPAPI and ConvertTo-SecureString
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertto-securestring
#>
# Guard against re-import type collision (F-30): only define the type if it is not already loaded.
if (-not ('VSAConnection' -as [type])) {
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

    // NOTE: These Base64 helpers and the static Get/UpdatePersistent* methods below are legacy
    // and are no longer used for persistence. The encrypted environment blob is written and
    // read entirely by the PowerShell layer (Set-VSAPersistentConnection / Get-VSAPersistentField),
    // which is where the real ConvertTo/ConvertFrom-SecureString encryption happens (DPAPI on
    // Windows, runtime-derived-key AES on Linux/macOS -- F-60).
    private static string EncryptConnectionData(string data)
    {
        byte[] dataBytes = Encoding.UTF8.GetBytes(data);
        return Convert.ToBase64String(dataBytes);
    }

    private static string DecryptConnectionData(string encodedData)
    {
        try
        {
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
        // The class only tracks in-memory state. Writing the persistent, encrypted blob
        // to the environment variable is done by the PowerShell layer (Set-VSAPersistentConnection),
        // so the stored value is genuinely encrypted rather than plain Base64.
        if (!_IsPersistent)
        {
            // Securely clear the environment variable when persistence is turned off.
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
} # end guard: VSAConnection type
#endregion Class VSAConnection

#region Environment detection and edition-specific strategies (F-27)
# Detect the HTTP-stack capability ONCE, at import, and pick the right implementation up front so
# the per-request path (Get-RequestData) carries no edition/version branching.
#
# We branch on the actual FEATURE (does Invoke-RestMethod expose -SkipCertificateCheck?) rather than
# an edition or version label, and we treat Windows PowerShell / .NET Framework as the SAFE FALLBACK
# (the else): PS 5.1 is the must-support target, so if detection is ever ambiguous we degrade to the
# compiled-callback path that must work there, never to a -SkipCertificateCheck that would hard-error.
$script:VSASupportsSkipCertCheck = (Get-Command Invoke-RestMethod).Parameters.ContainsKey('SkipCertificateCheck')

if ($script:VSASupportsSkipCertCheck) {
    # PowerShell 7+ (.NET Core): Invoke-RestMethod honours a per-request switch and ignores the
    # process-global ServicePointManager callbacks entirely, so certificate bypass is scoped to the
    # single request (nothing global to push/restore). TLS negotiation is handled by the OS.
    $script:VSAAddSkipCertCheck = { param($RequestParams) $RequestParams['SkipCertificateCheck'] = $true }
    $script:VSAPushCertBypass   = { }
    $script:VSAPopCertBypass    = { }
} else {
    # Windows PowerShell 5.1 (.NET Framework). Two Framework-specific facts drive this branch:
    #
    # 1. Certificate bypass MUST use a COMPILED type. A PowerShell scriptblock assigned to
    #    ServerCertificateValidationCallback cannot execute on the TLS handshake thread (no runspace
    #    is available there), which aborts the send -> "An unexpected error occurred on a send".
    #    ICertificatePolicy is a real .NET type whose method runs on any thread; it is obsolete on
    #    .NET Core, but this branch is only ever reached on .NET Framework, where it is fully valid.
    # 2. Older Windows + .NET Framework does not enable TLS 1.2 by default. Pin it OUTRIGHT (not
    #    OR-in): a client to a hardened VSA endpoint must offer the strong protocol only, not also
    #    whatever legacy protocols (SSL3/TLS1.0) the host happens to have left enabled.
    if (-not ('VSATrustAllCertificatePolicy' -as [type])) {
        Add-Type -TypeDefinition @'
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class VSATrustAllCertificatePolicy : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint sp, X509Certificate cert, WebRequest req, int problem) {
        return true;
    }
}
'@
    }

    # Pin strong protocols OUTRIGHT (never -bor into the host's existing value, which may still carry
    # SSL3/TLS1.0). TLS 1.2 is always the floor/fallback; TLS 1.3 is added only when the enum defines
    # it (.NET Framework 4.8+). Even then 1.3 only negotiates on Windows 11 / Server 2022 and is
    # harmlessly ignored on older OSes because 1.2 remains available. IsDefined avoids an exception
    # probe on hosts where the Tls13 member does not exist.
    $strongProtocols = [Net.SecurityProtocolType]::Tls12
    if ([enum]::IsDefined([Net.SecurityProtocolType], 'Tls13')) {
        $strongProtocols = $strongProtocols -bor [Net.SecurityProtocolType]'Tls13'
    }
    [Net.ServicePointManager]::SecurityProtocol = $strongProtocols

    $script:VSAAddSkipCertCheck = { param($RequestParams) }  # no-op: bypass is via the policy below
    $script:VSAPushCertBypass   = {
        $script:VSAPreviousCertificatePolicy = [System.Net.ServicePointManager]::CertificatePolicy
        [System.Net.ServicePointManager]::CertificatePolicy = [VSATrustAllCertificatePolicy]::new()
    }
    $script:VSAPopCertBypass    = {
        [System.Net.ServicePointManager]::CertificatePolicy = $script:VSAPreviousCertificatePolicy
    }
}
#endregion Environment detection and edition-specific strategies

#region Persistent-connection encryption strategy (F-60)
# Detect the OS ONCE, at import, and pick the persistent-connection protect/unprotect
# implementation up front, mirroring the F-27 cert-bypass region above.
#
# $IsWindows only exists on PowerShell 6+ (Core); Windows PowerShell 5.1 (Desktop) never shipped
# for a non-Windows OS, so its absence itself is the signal. As with F-27, the ambiguous case
# (variable missing) is resolved toward Windows -- the platform DPAPI already guarantees to work
# there -- rather than toward the non-Windows key-derivation path.
$script:VSAIsWindows = if (Test-Path -Path Variable:IsWindows) { $IsWindows } else { $true }

if ($script:VSAIsWindows) {
    # Windows: ConvertTo-/ConvertFrom-SecureString with NO -Key uses DPAPI, which is bound to the
    # current user AND the current machine. This is unchanged from the original implementation.
    $script:VSAProtectData = {
        param($PlainB64)
        $secureString = ConvertTo-SecureString -String $PlainB64 -AsPlainText -Force
        return (ConvertFrom-SecureString -SecureString $secureString)
    }
    $script:VSAUnprotectData = {
        param($Protected)
        $secureString = ConvertTo-SecureString -String $Protected
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        # PtrToStringBSTR reads the length-prefixed UTF-16 BSTR correctly on every platform;
        # PtrToStringAuto truncates it at the first null byte on non-Windows.
        $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        return $plainText
    }
} else {
    # Linux/macOS: there is no DPAPI. ConvertTo-/ConvertFrom-SecureString WITHOUT -Key still
    # "succeeds" on these platforms, but the result is trivially reversible with no key at all --
    # obfuscation, not encryption. -Key <32-byte AES key> is the supported, real-encryption form.
    #
    # The key is derived at RUNTIME from stable per-user + per-machine identifiers, never stored
    # anywhere (not on disk, not in the env var, not cached beyond the single protect/unprotect
    # call), and re-derives identically every time so no extra state needs to survive between
    # SetPersistent() and a later read. This is weaker than DPAPI (no OS-backed secret store
    # underlies it -- anyone who can compute the same inputs on the same machine can rebuild the
    # key), but it is appropriate here: the store itself is only a process-scoped env var, not
    # on-disk persistence.
    $script:VSADeriveLocalKey = {
        $machineId = if (Test-Path -LiteralPath '/etc/machine-id' -PathType Leaf) {
            (Get-Content -LiteralPath '/etc/machine-id' -Raw -ErrorAction SilentlyContinue)
        }
        $material = @(
            $env:USER
            [System.Net.Dns]::GetHostName()
            $machineId
            'VSAModule.PersistentConnection.v1'
        ) -join '|'
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        try {
            return $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($material))
        } finally {
            $sha256.Dispose()
        }
    }

    $script:VSAProtectData = {
        param($PlainB64)
        $key = & $script:VSADeriveLocalKey
        try {
            $secureString = ConvertTo-SecureString -String $PlainB64 -AsPlainText -Force
            return (ConvertFrom-SecureString -SecureString $secureString -Key $key)
        } finally {
            [Array]::Clear($key, 0, $key.Length)
        }
    }
    $script:VSAUnprotectData = {
        param($Protected)
        $key = & $script:VSADeriveLocalKey
        try {
            $secureString = ConvertTo-SecureString -String $Protected -Key $key
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
            # PtrToStringBSTR reads the length-prefixed UTF-16 BSTR correctly on every platform;
            # PtrToStringAuto truncates it at the first null byte on non-Windows.
            $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            return $plainText
        } finally {
            [Array]::Clear($key, 0, $key.Length)
        }
    }
}
#endregion Persistent-connection encryption strategy

# Import additional functions from Private and Public folders.
# The VSAConnection type must exist before these files are dot-sourced (F-31),
# because their parameter blocks are typed [VSAConnection]. A dot-source error
# must terminate the import (fail loud) rather than be swallowed.
$scriptPaths = Get-ChildItem -Path (Join-Path $PSScriptRoot 'public'), (Join-Path $PSScriptRoot 'private') -Filter '*.ps1' -File -ErrorAction Stop
foreach ($script in $scriptPaths) { . $script.FullName }

#region Secure Storage Functions
function Protect-VSAConnectionData {
    <#
    .SYNOPSIS
        Encrypts VSAConnection data using the platform-detected strategy (F-60).
    .DESCRIPTION
        Takes plain Base64-encoded data and encrypts it via the $script:VSAProtectData strategy
        selected once at module import: Windows DPAPI (ConvertTo-/ConvertFrom-SecureString, no
        -Key -- user- and machine-bound) on Windows, or AES with a runtime-derived, never-stored
        key (ConvertTo-/ConvertFrom-SecureString -Key) on Linux/macOS, where DPAPI does not exist.
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
        return (& $script:VSAProtectData $Data)
    } catch {
        Write-Warning "Failed to encrypt connection data: $_"
        return $null
    }
}

function Unprotect-VSAConnectionData {
    <#
    .SYNOPSIS
        Decrypts VSAConnection data encrypted with Protect-VSAConnectionData (F-60).
    .DESCRIPTION
        Takes data encrypted by Protect-VSAConnectionData and decrypts it via the
        $script:VSAUnprotectData strategy selected once at module import (DPAPI on Windows,
        runtime-derived-key AES on Linux/macOS -- see Protect-VSAConnectionData).
    .PARAMETER EncryptedData
        The encrypted connection data string.
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $EncryptedData
    )

    try {
        return (& $script:VSAUnprotectData $EncryptedData)
    } catch {
        Write-Warning "Failed to decrypt connection data: $_"
        return $null
    }
}

#region Persistent connection storage (platform-detected encryption, F-60)
# The persistent connection lives in the 'VSAConnection' environment variable. PowerShell owns
# reading and writing it so the blob is genuinely protected via Protect/Unprotect-VSAConnectionData
# (DPAPI, user- and machine-scoped, on Windows; runtime-derived-key AES on Linux/macOS, where
# DPAPI does not exist -- see the encryption-strategy region above). The C# class no
# longer writes the raw Base64 to the environment variable.
#
# Serial field order: 0=URI 1=Token 2=PAT 3=UserName 4=SessionExpiration(o) 5=IgnoreCertErrors 6=IsPersistent

function Set-VSAPersistentConnection {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][VSAConnection] $Connection)
    $fields = @(
        $Connection.URI
        $Connection.Token
        $Connection.PAT
        $Connection.UserName
        $Connection.SessionExpiration.ToString('o', [System.Globalization.CultureInfo]::InvariantCulture)
        $Connection.IgnoreCertificateErrors.ToString()
        'True'
    )
    $serial = $fields -join "`t"
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($serial))
    $protected = Protect-VSAConnectionData -Data $b64
    if ([string]::IsNullOrEmpty($protected)) { throw "Failed to protect persistent VSAConnection data." }
    [Environment]::SetEnvironmentVariable('VSAConnection', $protected)
}

function Get-VSAPersistentSerial {
    $stored = [Environment]::GetEnvironmentVariable('VSAConnection')
    if ([string]::IsNullOrEmpty($stored)) { return $null }
    $b64 = Unprotect-VSAConnectionData -EncryptedData $stored
    if ([string]::IsNullOrEmpty($b64)) { return $null }
    try {
        $serial = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
    } catch {
        return $null
    }
    return , ($serial -split "`t")
}

function Get-VSAPersistentField {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][int] $Index)
    $parts = Get-VSAPersistentSerial
    if ($null -eq $parts -or $parts.Count -le $Index) { return [string]::Empty }
    return $parts[$Index]
}

function Update-VSAPersistentField {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][int] $Index,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Value
    )
    $parts = Get-VSAPersistentSerial
    if ($null -eq $parts -or $parts.Count -le $Index) { return }
    $parts[$Index] = $Value
    $serial = $parts -join "`t"
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($serial))
    $protected = Protect-VSAConnectionData -Data $b64
    if (-not [string]::IsNullOrEmpty($protected)) {
        [Environment]::SetEnvironmentVariable('VSAConnection', $protected)
    }
}

function Get-VSAPersistentURI      { return (Get-VSAPersistentField -Index 0) }
function Get-VSAPersistentToken    { return (Get-VSAPersistentField -Index 1) }
function Get-VSAPersistentPAT      { return (Get-VSAPersistentField -Index 2) }
function Get-VSAPersistentUserName { return (Get-VSAPersistentField -Index 3) }

function Get-VSAPersistentSessionExpiration {
    $v = Get-VSAPersistentField -Index 4
    $dt = [datetime]::MinValue
    if ([datetime]::TryParse($v, [ref]$dt)) { return $dt }
    return [datetime]::MinValue
}

function Get-VSAPersistentIgnoreCertErrors {
    $v = Get-VSAPersistentField -Index 5
    $b = $false
    if ([bool]::TryParse($v, [ref]$b)) { return $b }
    return $false
}
#endregion Persistent connection storage

# Shared parser so the logon path and the renewal path compute the local expiration identically (F-24).
function ConvertTo-VSALocalExpiration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object] $SessionExpiration,

        [Parameter(Mandatory = $false)]
        [int] $OffSetInMinutes = 0
    )
    if ($SessionExpiration -is [datetime]) {
        # PowerShell 7 / Core: Invoke-RestMethod (ConvertFrom-Json) auto-deserializes the ISO-8601
        # SessionExpiration string into a [DateTime]. Re-stringifying it under the current culture
        # (e.g. '07/05/2026 13:05:48') breaks ParseExact, so use the DateTime directly (F-19).
        $parsed = [datetime] $SessionExpiration
    } else {
        # Windows PowerShell 5.1: ConvertFrom-Json leaves it as the raw ISO-8601 string.
        $parsed = [DateTime]::ParseExact([string] $SessionExpiration, "yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture)
    }
    return $parsed.AddMinutes($OffSetInMinutes)
}

#endregion Secure Storage Functions

# NOTE: Certificate validation bypass is handled per-request in Get-RequestData,
# branching on the PowerShell edition (Invoke-RestMethod -SkipCertificateCheck on
# PS 7 / Core, and a scoped ServerCertificateValidationCallback on Windows PowerShell
# 5.1 / Desktop). The obsolete ICertificatePolicy-based TrustAllCertsPolicy class was
# removed (F-26): ICertificatePolicy is not available on .NET Core.

#region function New-VSAConnection
function New-VSAConnection {
<#
.SYNOPSIS
    Creates a VSAConnection object with secure credential handling.
.DESCRIPTION
    Creates a VSAConnection object that encapsulates access token as well as additional connection information.
    Optionally makes the connection object persistent with encrypted storage (DPAPI on Windows;
    runtime-derived-key AES on Linux/macOS, where DPAPI does not exist -- see F-60).
    
    SECURITY & CREDENTIAL HANDLING:
    This function implements secure credential handling through the following mechanisms:
    
    1. IN-MEMORY CREDENTIALS (Non-Persistent):
       - Personal Authentication Token (PAT) is stored in memory only
       - Credentials are passed to the VSA API over HTTPS with TLS encryption
       - Best practice for automated scripts and scheduled tasks
       - Session token expires automatically and must be renewed on each script run
    
    2. PERSISTENT CREDENTIALS (SetPersistent):
       - Uses the Data Protection API (DPAPI) to encrypt stored credentials on Windows; on
         Linux/macOS (no DPAPI) uses AES with a key derived at runtime from per-user + per-machine
         identifiers and never stored (F-60)
       - Windows: specific to the current user on the current machine. Linux/macOS: specific to
         the current user + machine identity used to derive the key
       - Only the same user account (on the same machine) can decrypt the stored credentials
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
    - Connection data is encrypted using DPAPI (Windows) or a runtime-derived-key AES (Linux/macOS, F-60)
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
    Version 1.3.2
    SECURITY:
    - Implements DPAPI encryption for persistent connections on Windows (v0.1.5+); runtime-derived-key
      AES on Linux/macOS, where DPAPI does not exist (F-60)
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
            {if ($_ -match '^https:\/\/([\w.-]+(?:\.[\w\.-]+)+|((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}|((([0-9a-fA-F]){1,4})\:){7}([0-9a-fA-F]){1,4}|localhost)(\/)?$') {$true}
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
    # 3. PAT is stored encrypted (DPAPI on Windows, runtime-derived-key AES on Linux/macOS -- F-60)
    #    only if SetPersistent is enabled
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)
    # PtrToStringBSTR reads the length-prefixed UTF-16 BSTR correctly on every platform; the prior
    # PtrToStringAuto decodes it as ANSI/UTF-8 on non-Windows (Core), corrupting the PAT and making
    # auth fail on Linux/macOS. Same fix already applied to the F-60 persistence path (F-18).
    $PAT = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)

    # Create Base64 encoded credentials for Basic Auth header
    $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$UserName`:$PAT"))
    $AuthString  = "Basic $Encoded"
    
    # Securely clear plaintext PAT from memory after encoding
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

    $VSAServerUri = New-Object System.Uri -ArgumentList $VSAServer
    $AuthEndpoint = [System.Uri]::new($VSAServerUri, $AuthSuffix) | Select-Object -ExpandProperty AbsoluteUri

    $LogMessage = "Attempting authentication for user '$UserName' on VSA server '$VSAServer'."
    
            Write-Verbose $LogMessage
    
            Write-Debug $LogMessage
    

    $AuthParams = @{
        URI                     = $AuthEndpoint
        AuthString              = $AuthString
        IgnoreCertificateErrors = $IgnoreCertificateErrors
        ErrorAction             = 'Stop'
    }

    $result = try {
        Get-RequestData @AuthParams | Select-Object -ExpandProperty Result
    } catch {
        throw "Authentication failed on VSA server '$VSAServer' for user '$UserName': $($_.Exception.Message)"
    }

    if ([string]::IsNullOrEmpty($result)) {
        throw "Failed to retrieve authentication response from '$VSAServer' for user '$UserName'."
    }

    $SessionExpiration = ConvertTo-VSALocalExpiration -SessionExpiration $result.SessionExpiration -OffSetInMinutes $result.OffSetInMinutes
    $VSAConnection = [VSAConnection]::new($VSAServer, $result.UserName, $result.Token, $PAT, $SessionExpiration, $IgnoreCertificateErrors, $SetPersistent)

    Write-Verbose "User '$UserName' authenticated on VSA server '$VSAServer'. Session token expiration: $SessionExpiration (UTC)."
            Write-Debug "New-VSAConnection result: '$($result | ConvertTo-Json)'"
    

    if ($SetPersistent) {
        # Persist the connection as a genuinely encrypted blob in the environment variable
        # (DPAPI on Windows, runtime-derived-key AES on Linux/macOS -- F-60).
        Set-VSAPersistentConnection -Connection $VSAConnection
        Write-Verbose "Connection to server '$VSAServer' set persistent for the current session. Clear it with: Remove-Item env:\VSAConnection"
    }

    Write-Output $VSAConnection
}
#endregion function New-VSAConnection

Export-ModuleMember -Function New-VSAConnection

# Endpoint + id maps moved to private/VSAEndpointMaps.ps1 (dot-sourced into module scope above).

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

# Data-driven dispatch: the three maps above pair ~89 command aliases with three shared wrapper
# functions. Each wrapper is exported together with the aliases that resolve to it, because an
# exported alias can only resolve to an EXPORTED command -- PowerShell resolves the alias target in
# the caller's scope, where a module-private function is invisible (proven on both Windows
# PowerShell 5.1 and PS7). Exposing these three generic dispatchers also gives callers an escape
# hatch: Get-VSAItem/Get-VSAItemById/Remove-VSAItem -URISuffix <endpoint> can reach any endpoint
# that has no dedicated alias yet. The transport-layer helpers (Get-RequestData,
# Invoke-VSARestMethod, Update-VSAConnection) have no aliases and deliberately stay private (F-20).
Export-ModuleMember -Function Get-VSAItem     -Alias $($URISuffixGetMap.Keys)
Export-ModuleMember -Function Get-VSAItemById -Alias $($URISuffixGetByIdMap.Keys)
Export-ModuleMember -Function Remove-VSAItem  -Alias $($URISuffixRemoveMap.Keys)