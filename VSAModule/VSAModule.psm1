<#
   Kaseya VSA9 REST API Wrapper
   Version 0.1.2
   Author: Vladislav Semko
   Description:
   VSAModule for Kaseya VSA 9 REST API is a PowerShell module that provides cmdlets for interacting with the Kaseya VSA 9 platform via its REST API.
   This module simplifies the process of automating tasks, retrieving data, and managing resources within the Kaseya VSA 9 environment directly from PowerShell scripts or the command line.

    Key Features:
    - Intuitive cmdlets for common operations such as retrieving information about assests and managing entities.
    - Secure authentication methods, including support for API tokens, ensuring the confidentiality of sensitive information.
    - Examples to help users get started quickly and effectively integrate Kaseya VSA 9 functionality into their automation workflows.

    This module is distributed under the MIT License, allowing for free use, modification, and distribution by users.
#>

#Import additional functions from Private and Public folders
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

Foreach($import in @($Public + $Private)) {
    Try {
        . $import.fullname
    } Catch {
        Write-Warning -Msg "Failed to import function $($import.fullname): $_"
		Continue
    }
}

#region Class VSAConnection
Add-Type -TypeDefinition @'
using System;

public class VSAConnection
{
    // Properties to store connection details
    public string URI { get; set; }
    public string UserName { get; set; }
    public string Token { get; set; }
    public bool IgnoreCertificateErrors { get; set; }
    public DateTime SessionExpiration { get; set; }
    public static bool IsPersistent { get; set; } // Changed to static

    // Method to check connection status
    public string GetStatus()
    {
        string status = "Closed";
        if (!string.IsNullOrEmpty(Token))
        {
            status = "Open";
        }
        return status;
    }

    // Constructor to initialize connection properties
    public VSAConnection(
       string uri,
       string userName,
       string token,
       DateTime sessionExpiration,
       bool ignoreCertificateErrors = false,
       bool isPersistent = false)
    {
        URI = uri;
        UserName = userName;
        Token = token;
        SessionExpiration = sessionExpiration;
        IgnoreCertificateErrors = ignoreCertificateErrors;
        IsPersistent = isPersistent;
        if (isPersistent)
        {
            SetPersistent(isPersistent);
        }
    }

    public string GetToken()
    {
        return Token;
    }

    public void SetPersistent(bool isPersistent = true)
    {
        IsPersistent = isPersistent;
        if (IsPersistent)
        {
            string serial = URI + "\t" + Token + "\t" + UserName + "\t" + SessionExpiration + "\t" + IgnoreCertificateErrors + "\t" + IsPersistent;
            string encoded = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(serial));
            Environment.SetEnvironmentVariable("VSAConnection", encoded);
        }
        else
        {
            Environment.SetEnvironmentVariable("VSAConnection", null);
        }
    }

    public static bool GetPersistent()
    {
        return IsPersistent;
    }

    public static string GetPersistentURI()
    {
        string theURI = string.Empty;
        if (IsPersistent)
        {
            string encoded = Environment.GetEnvironmentVariable("VSAConnection");
            if (encoded != null)
            {
                string serial = System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(encoded));
                string[] separateValues = serial.Split('\t');
                theURI = separateValues[0];
            }
        }
        return theURI;
    }

    public static string GetPersistentToken()
    {
        string theToken = string.Empty;
        if (IsPersistent)
        {
            string encoded = Environment.GetEnvironmentVariable("VSAConnection");
            if (encoded != null)
            {
                string serial = System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(encoded));
                string[] separateValues = serial.Split('\t');
                theToken = separateValues[1];
            }
        }
        return theToken;
    }

    public static bool GetIgnoreCertErrors()
    {
        bool ignoreCertErrors = false;
        if (IsPersistent)
        {
            string encoded = Environment.GetEnvironmentVariable("VSAConnection");
            if (encoded != null)
            {
                string serial = System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(encoded));
                string[] separateValues = serial.Split('\t');
                bool.TryParse(separateValues[4], out ignoreCertErrors);
            }
        }
        return ignoreCertErrors;
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
    Indicates whether to make the VSAConnection object persistent during the session so that module commandlets will use the connection information implicitly.
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
    $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$UserName`:$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR))"))
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
    }

    $response = Get-RequestData @AuthParams
    $result = $response | Select-Object -ExpandProperty Result

    if ([string]::IsNullOrEmpty($result)) {
        throw "Failed to retrieve authentication response from '$VSAServer' for user '$username'`n$("Response Code: '$($response.ResponseCode)'`nResponse Error: '$($response.Error)'`n")"
    } else {
        $SessionExpiration = [DateTime]::ParseExact($result.SessionExpiration, "yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture)
        $SessionExpiration = $SessionExpiration.AddMinutes($result.OffSetInMinutes)
        $VSAConnection = [VSAConnection]::new($VSAServer, $result.UserName, $result.Token, $SessionExpiration, $IgnoreCertificateErrors, $SetPersistent)

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
            $Msg = "`tConnection to server '$VSAServer' set Persistent during the current session so the VSAModule's commandlets can use the connection implicitly.`n"
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
    }

    return $VSAConnection
}
#endregion function New-VSAConnection

Export-ModuleMember -Function New-VSAConnection