<#
   Kaseya VSA9 REST API Wrapper
   Version 0.1.3.1
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

    $Msg = "Attempting authentication for user '$UserName' on VSA server '$VSAServer'."
    
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        Write-Verbose $Msg
    }
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug $Msg
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

        $Msg = "`tUser '$UserName' authenticated on VSA server '$VSAServer'.`n`tSession token expiration: $SessionExpiration (UTC).`n"
        Write-Host $Msg
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            Write-Verbose $Msg
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug $Msg
            Write-Debug "New-VSAConnection result: '$($result | ConvertTo-Json)'"
        }
        if ($SetPersistent) {
            $Msg = "`tConnection to server '$VSAServer' set Persistent during the current session so the VSAModule's cmdlets can use the connection implicitly.`n"
            Write-Host $Msg
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                Write-Verbose $Msg
            }
            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                Write-Debug $Msg
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

#region function Update-VSAConnection
function Update-VSAConnection {
<#
.SYNOPSIS
    Updates the token and session expiration for a VSAConnection object.
.DESCRIPTION
    The Update-VSAConnection function updates the authentication token and session expiration for a given VSAConnection object.
    If no explicit VSAConnection object is provided, it attempts to update the persistent VSAConnection object stored in the environment variable.
    The function checks if the session is about to expire and renews it by making a new request to the authentication endpoint.

.PARAMETER VSAConnection
    Specifies the VSAConnection object to be updated. If not provided, the function attempts to use the persistent VSAConnection object.
.INPUTS
    VSAConnection
.OUTPUTS
    None.
.NOTES
    This function is part of the Kaseya VSA 9 REST API Wrapper PowerShell module.
    Ensure that the VSAConnection object or a persistent connection is available before calling this function.

.EXAMPLE
    # Example 1: Update an existing VSAConnection object
    $vsaConnection = New-VSAConnection -VSAServer "https://vsaserver.example.com" -Credential (Get-Credential)
    Update-VSAConnection -VSAConnection $vsaConnection

    # Example 2: Update the persistent VSAConnection object
    Update-VSAConnection

    # Example 3: Update the VSAConnection object using the pipeline
    $vsaConnection | Update-VSAConnection
#>
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $AuthSuffix = 'API/v1.0/Auth'
    )

    if ($null -eq $VSAConnection) {
        if ([VSAConnection]::IsPersistent) {
            $SessionExpiration = $([VSAConnection]::GetPersistentSessionExpiration()).AddMinutes(-1)
        } else {
            Throw "Update-VSAConnection: Neither explicit VSAConnection provided nor persistent VSAConnection found!"
        }
    } else {
        $SessionExpiration = $($VSAConnection.SessionExpiration.AddMinutes(-1))
    }

    # Renew the session if it is about to expire
    if ($SessionExpiration -le [datetime]::Now) {

        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug "The REST API Token is about to expire ($SessionExpiration)."
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            Write-Verbose "The REST API Token is about to expire ($SessionExpiration)."
        }

        # Extract the data needed for repeat Token request
        if ($null -eq $VSAConnection) {
            # The Connection is persistent
            $VSAUserPAT = [VSAConnection]::GetPersistentPAT()
            $VSAUserName = [VSAConnection]::GetPersistentUserName()
            $VSAServer = [VSAConnection]::GetPersistentURI()
            $IgnoreCertificateErrors = [VSAConnection]::GetIgnoreCertErrors()
        } else {
            $VSAUserPAT = $VSAConnection.PAT
            $VSAUserName = $VSAConnection.UserName
            $VSAServer = $VSAConnection.URI
            $IgnoreCertificateErrors = $VSAConnection.IgnoreCertificateErrors
        }

        if ([string]::IsNullOrEmpty( $($VSAUserPAT) ) ) {
            Throw "Update-VSAConnection: No PAT retrieved from the VSAConnection object. Unable to update VSAConnection!"
        }

        $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$VSAUserName`:$VSAUserPAT"))
        $AuthString  = "Basic $Encoded"

        $VSAServerUri = New-Object System.Uri -ArgumentList $VSAServer
        $AuthEndpoint = [System.Uri]::new($VSAServerUri, $AuthSuffix) | Select-Object -ExpandProperty AbsoluteUri

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
            Throw "Server '$VSAServer' returned error`nUser '$UserName'`n$errorMessage"
        }

        #Check if Session token was obtained
        if ([string]::IsNullOrEmpty( $($result.Token) ) ) {
            Throw "Update-VSAConnection: Unable to update VSAConnection object!"
        }

        # Extract data from the request result & update the Connection properties
        $SessionExpiration = [DateTime]::ParseExact($result.SessionExpiration, "yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture)

        if ($null -eq $VSAConnection) {
            # The Connection is persistent
            [VSAConnection]::UpdatePersistentToken($($result.Token))
            [VSAConnection]::UpdatePersistentSessionExpiration($SessionExpiration)
        } else {
            $VSAConnection.UpdateToken($($result.Token))
            $VSAConnection.UpdateSessionExpiration($SessionExpiration)
        }

        $Msg = "`nUpdate-VSAConnection: Session token renewed.`n`tSession token expiration: $SessionExpiration (UTC).`n"
        Write-Host $Msg
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            Write-Verbose $Msg
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug $Msg
        }

    } # the session is about to expire
}
#endregion function Update-VSAConnection

Export-ModuleMember -Function Update-VSAConnection
