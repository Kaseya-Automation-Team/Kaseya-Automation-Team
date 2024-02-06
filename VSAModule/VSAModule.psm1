<#
   Kaseya VSA9 REST API Wrapper
   Version 0.8.1
   Author: Vladislav Semko
#>

#Import additional functions from Private and Public folders
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

Foreach($file in @($Public + $Private)) {
    Try {
        . $file.fullname
    } Catch {
        Write-Warning -Msg "Failed to import commandlet: `'$($file.fullname)`': $_"
		Continue
    }
}
#region Class VSAConnection
Add-Type -TypeDefinition @"
    using System;

    public class VSAConnection
    {
        public string URI { get; set; }
        public string UserName { get; set; }
        public string Token { get; set; }
        public bool IgnoreCertificateErrors { get; set; }
        public DateTime SessionExpiration { get; set; }

        public string GetStatus()
        {
            string Status = "Closed";
            if (!string.IsNullOrEmpty(Token))
            {
                Status = "Open";
            }
            return Status;
        }

        public VSAConnection(
            string uri,
            string userName,
            string token,
            bool ignoreCertificateErrors,
            DateTime sessionExpiration)
        {
            URI = uri;
            Token = token;
            IgnoreCertificateErrors = ignoreCertificateErrors;
            UserName = userName;
            SessionExpiration = sessionExpiration;
        }
    }
"@
#endregion Class VSAConnection

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
#============================================================================================

#region function New-VSAConnection
function New-VSAConnection {
<#
.Synopsis
   Creates VSAConnection object.
.DESCRIPTION
   Creates VSAConnection object that incapsulates access token as well as additional connection information.
   Optionally makes the connection object persistent.
.PARAMETER VSAServer
    Address of the VSA Server to connect.
.PARAMETER UserName
    Specifies existing VSA user thet allowed to connect VSA through REST API.
.PARAMETER AuthSuffix
    Specifies authorization URI suffix if it differs from the default.
.EXAMPLE
   New-VSAConnection -VSAServer https://vsaserver.address.example 
.EXAMPLE
   New-VSAConnection -VSAServer https://vsaserver.address.example -IgnoreCertificateErrors
.INPUTS
   Accepts response object from the authorization API.
.OUTPUTS
   VSAConnection. New-VSAConnection returns object of VSAConnection type that incapsulates access token as well as additional connection information.
#>

    [cmdletbinding()]
    [OutputType([VSAConnection])]
    param(
        [parameter(ValueFromPipeline,
            Mandatory = $true,
            Position = 0)]
        [ValidateScript(
            {if ($_ -match '^http(s)?:\/\/([\w.-]+(?:\.[\w\.-]+)+|((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}|((([0-9a-fA-F]){1,4})\:){7}([0-9a-fA-F]){1,4}|localhost)(\/)?$') {$true}
            else {Throw "$_ is an invalid. Enter a valid address that begins with https://"}}
            )]
        [String]$VSAServer,

        [parameter(Mandatory = $false)]
        [PSCredential] $Credential,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'API/v1.0/Auth',

        [switch] $IgnoreCertificateErrors
    )  

    if ( $IgnoreCertificateErrors ) {
        Write-Warning "Ignoring certificate errors may expose your connection to potential security risks.`nBy enabling this option, you accept all associated risks, and any consequences are solely your responsibility."
    }

    if ( $null -eq $Credential) {
        $Credential = Get-Credential -Message "Please provide Username and Personal Authentication Token"
    }
    
    [string]$UserName = $Credential.username

    # If there's the trailing backslash, remove it
    $VSAServer = $VSAServer.TrimEnd('/')
            
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.password)

    [string]$Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$UserName`:$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR))"))

    [string] $AuthString  = "Basic $Encoded"

    [string]$URI = "{0}/{1}" -f $VSAServer, $URISuffix

    [string]$Msg = "Attempting authentication for user '$UserName' on VSA server '$VSAServer'."
    $Msg | ForEach-Object { Write-Debug $_; Write-Verbose $_; Write-Host $_ -ForegroundColor Gray  }

    [hashtable]$AuthParams = @{
        URI = $URI
        AuthString = $AuthString
        IgnoreCertificateErrors = $IgnoreCertificateErrors
    }

    $result = Get-RequestData @AuthParams | Select-Object -ExpandProperty Result
    
    if ( $result ) {
        [datetime] $SessionExpiration = [DateTime]::ParseExact($result.SessionExpiration, "yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture)
        $SessionExpiration = $SessionExpiration.AddMinutes($result.OffSetInMinutes)

        "Authenticated. Session token expiration date: $SessionExpiration (UTC)." | ForEach-Object { Write-Verbose $_; Write-Debug $_; Write-Host $_}
        $result | ConvertTo-Json | Write-Debug
        $VSAConnection = [VSAConnection]::new($VSAServer, $result.UserName, $result.Token, $ignoreCertificateErrors, $SessionExpiration)

    } else {
        "Could not get authentication response" | ForEach-Object { Write-Verbose $_; Write-Debug $_; Write-Host $_ -ForegroundColor Red}
		throw "Could not get authentication response"
    }

    if ( 'Open' -eq $VSAConnection.GetStatus() ) {
        [string]$Msg = "Authentication successful."
        $Msg | ForEach-Object { Write-Debug $_; Write-Verbose $_; Write-Host $_ -ForegroundColor Green }
    }

    return $VSAConnection
}
#endregion function New-VSAConnection

Export-ModuleMember -Function New-VSAConnection