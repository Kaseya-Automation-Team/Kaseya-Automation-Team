<#
POC
   Module VSA
   Version 0.7
   Author: Vladislav Semko
   Modified: Aliaksandr Serzhankou
   Modification date: 24-10-21
#>

#Import additional functions from Private and Public folders
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

Foreach($import in @($Public + $Private))
    {
        Try
        {
            . $import.fullname
        }
        Catch
        {
            Write-Warning -Msg "Failed to import function $($import.fullname): $_"
			Continue
        }
    }
Add-Type @'
using System;

public class VSAConnection
{
    enum ConnectionState
    {
        Closed,
        Open,
        Expired
    }

    public string URI = string.Empty;
    public string Token = string.Empty;
    public string UserName = string.Empty;
    public DateTime SessionExpiration;

    private ConnectionState Status = ConnectionState.Open;
    static private bool IsPersistent = false; //if true: all instances of VSAConnection class share the same environment variable to store the connection information.

    public VSAConnection()
    {
    }
    private void RestorePersistent()
    {
        string Encoded = Environment.GetEnvironmentVariable("VSAConnection");
        string Serial = System.Text.Encoding.UTF8.GetString(System.Convert.FromBase64String(Encoded));
        string[] SeparateValues = Serial.Split('\t'); 
        this.URI = SeparateValues[0];
        this.Token = SeparateValues[1];
        this.UserName = SeparateValues[2];
        this.SessionExpiration = DateTime.Parse(SeparateValues[3]);
    }

    private void CopyObject( VSAConnection InputObject )
    {
        if ( string.IsNullOrEmpty(InputObject.URI))
        {
            throw new ArgumentNullException("The Input Object Does Not Contain URI");
        }
        else
        {
            this.URI = InputObject.URI;
            this.Token = InputObject.Token;
            this.UserName = InputObject.UserName;
            this.SessionExpiration = InputObject.SessionExpiration;
        }

        if ( string.IsNullOrEmpty(InputObject.Status.ToString()) )
        {
            this.Status = ConnectionState.Open;
        }
        else
        {
            this.Status = InputObject.Status;            
        }
    }

    public string GetStatus()
    {
        switch(Status) 
        {
        case ConnectionState.Open:
            if (DateTime.Compare(DateTime.Now, SessionExpiration) > 0)
            {
                this.Status = ConnectionState.Expired;
            }
            break;
        default:
            if ( string.IsNullOrEmpty(Token) )
            {
                this.Status = ConnectionState.Closed;
            }
            break;
        }
        return this.Status.ToString();
    }

    public string GetToken()
    {
        return this.Token;
    }

    public void SetPersistent()
    {
        IsPersistent = true;
        string Serial = String.Format("{0}\t{1}\t{2}\t{3}", this.URI, this.Token, this.UserName, this.SessionExpiration);
        string Encoded = System.Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(Serial));
        Environment.SetEnvironmentVariable("VSAConnection", Encoded);
    }

    public void SetPersistent( bool Persistent )
    {
        IsPersistent = Persistent;
        if(IsPersistent)
        {
            string Serial = String.Format("{0}\t{1}\t{2}\t{3}", this.URI, this.Token, this.UserName, this.SessionExpiration);
            string Encoded = System.Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(Serial));
            Environment.SetEnvironmentVariable("VSAConnection", Encoded);
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
        string TheURI = string.Empty;
        if( IsPersistent )
        {
            string Encoded = Environment.GetEnvironmentVariable("VSAConnection");
            string Serial = System.Text.Encoding.UTF8.GetString(System.Convert.FromBase64String(Encoded));
            string[] SeparateValues = Serial.Split('\t'); 
            TheURI = SeparateValues[0];
        }
        return TheURI;
    }

    public static string GetPersistentToken()
    {
        string TheToken = string.Empty;
        if( IsPersistent )
        {
            string Encoded = Environment.GetEnvironmentVariable("VSAConnection");
            string Serial = System.Text.Encoding.UTF8.GetString(System.Convert.FromBase64String(Encoded));
            string[] SeparateValues = Serial.Split('\t'); 
            TheToken = SeparateValues[1];
        }
        return TheToken;
    }
}
'@
#endregion Class VSAConnection

#--------------------------------------------------------------------------------------------
#region function Get-StringHash 
function Get-StringHash {
    [cmdletbinding()]
    [OutputType([String])]
    param(
        [parameter(ValueFromPipeline, Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$InputString,
        [parameter(ValueFromPipelineByPropertyName, Mandatory = $false, Position = 1)]
        [ValidateSet("MD5", "RIPEMD160", "SHA1", "SHA256", "SHA384", "SHA512")]
        [String]$HashName = "SHA256"
    )
    $HashStringBuilder = New-Object System.Text.StringBuilder
    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($InputString)) | `
        Foreach-Object  {
            [Void]$HashStringBuilder.Append($_.ToString("x2"))
        }
    $HashStringBuilder.ToString()
}

#--------------------------------------------------------------------------------------------

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
.PARAMETER MakePersistent
    Specifies whether make the VSAConnection object persistent during the session so that module commandlets will use implicitly.
.PARAMETER NonInteractive
    Specifies whether to use stored credentials.
.EXAMPLE
   New-VSAConnection -VSAServer https://theserver.address.example -NonInteractive -MakePersistent
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
            {if ($_ -match '^http(s)?:\/\/([\w.-]+(?:\.[\w\.-]+)+|localhost)$') {$true}
            else {Throw "$_ is an invalid. Enter a valid address that begins with https://"}}
            )]
        [String]$VSAServer,

        [parameter(ValueFromPipeline,
            Mandatory = $false,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String] $UserName,

        #[parameter(ValueFromPipeline,
        #    Mandatory = $true,
        #    Position = 2)]
        #[ValidateNotNullOrEmpty()]
        #[String] $PAT,
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $AuthSuffix = 'API/v1.0/Auth',
        [parameter(Mandatory=$false)]
        [switch] $MakePersistent,
        [parameter(Mandatory=$false)] 
        [switch] $NonInteractive,
        [parameter(Mandatory=$false)] 
        [switch] $OldAuthMethod
    )
    
    #region set to ignore self-signed SSL certificate
Add-Type @'
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
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    #endregion set to ignore self-signed SSL certificate

    $URI = "$VSAServer/$AuthSuffix"

    [string] $Encoded = ''

    if ($OldAuthMethod) {  #OldAuthMethod
        $creds = Get-Credential -Message "Old Authentication method. Please provide UserName and Password"
        $username = $creds.UserName
        if ( [string]::IsNullOrEmpty($username) )
        {
            Write-Error "No UserName provided.`nQuit"
            return $null
        }
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($creds.Password )
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

        [string]$Random = (Get-Random).ToString()

        [string]$RawSHA256Hash = Get-StringHash $Password
        [string]$CoveredSHA256HashTemp = Get-StringHash ($Password+$Username)
        [string]$CoveredSHA256Hash = Get-StringHash ($CoveredSHA256HashTemp+$Random) 
        [string]$RawSHA1Hash = Get-StringHash $Password "SHA1"
        [string]$CoveredSHA1HashTemp = Get-StringHash ($Password+$Username) "SHA1"
        [string]$CoveredSHA1Hash = Get-StringHash ($CoveredSHA1HashTemp+$Random) "SHA1"

        [string[]]$Format = @(
            $Username
            $CoveredSHA256Hash
            $CoveredSHA1Hash
            $RawSHA256Hash
            $RawSHA1Hash
            $Random
            )

        $Encoded = [Convert]::ToBase64String( [Text.Encoding]::UTF8.GetBytes( $("user={0},pass2={1},pass1={2},rpass2={3},rpass1={4},rand2={5}" -f $Format) ) )
    } #OldAuthMethod
    else #NewAuthMethod
    {
        if ($NonInteractive) {
            Log-Event -Msg "Running in non-interactive mode" -Id 0000 -Type "Information" | Out-Null

        if ($Username) {
            Write-Host "Username is NOT required parameter in non-interactive mode and will be ignored"
        }
            $file = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($(Get-Content -Path "$PSScriptRoot\private\pat.txt")))
            $creds = $file -split ":"

            $username = $creds[0]

            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($($creds[1] | ConvertTo-SecureString))

        } else {

            $creds = Get-Credential -Message "Please provide username and Personal Authentication Token"
            $username = $creds.username
            
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($creds.password)
        }

        $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$username`:$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR))"))
    }#NewAuthMethod

    [string] $AuthString  = "Basic $Encoded"

    Log-Event -Msg "Attempting to authenticate with $VSAServer" -Id 0000 -Type "Information" | Out-Null
    Write-Verbose "Performing REST API request"
    Write-Debug "Performing REST API request"
    $result = Get-RequestData -URI $URI -authString $AuthString | Select-Object -ExpandProperty Result
    
    if ($result)
    {
        [string] $SessionExpiration = $($result.SessionExpiration  -replace "T"," ")

        Log-Event -Msg "Successfully authenticated. Token expiration date: $SessionExpiration (UTC)." -Id 2000 -Type "Information" | Out-Null
        $result | ConvertTo-Json | Write-Debug
        $connectionObject = [VSAConnection] @{
                                                URI               = $VSAServer
                                                Token             = $result.Token
                                                UserName          = $result.UserName
                                                SessionExpiration = $SessionExpiration
                                            }
        if ($MakePersistent) { $connectionObject.SetPersistent( $true ) }
    }
    else
    {
        Log-Event -Msg "Could not get authentication response" -Id 4001 -Type "Error" | Out-Null
		throw "Could not get authentication response"
    }
    return $connectionObject
}
#endregion function New-VSAConnection

Export-ModuleMember -Function New-VSAConnection