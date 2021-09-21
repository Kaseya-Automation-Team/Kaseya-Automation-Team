<#
POC
   Module VSA
   Version 0.5
   Author: Vladislav Semko
   Modified: Aliaksandr Serzhankou
   Modification date: 09-10-21
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

Enum ConnectionState
{
    Closed = 0
    Open = 1
    Expired = 2
}
#region Class VSAConnection
Class VSAConnection
{
    <#
        Encapsulates connection information such as:
        - VSA Server address
        - user's name
        - user's token
        - connection status
        - if the connection is persistent ( i.e. stored in the session's environment variable)
    #>
    [string] $URI
    [datetime] $SessionExpiration
    hidden [ConnectionState] $Status
    hidden [string] $Token
    hidden [string] $UserName
    static hidden [bool] $IsPersistent #if true: all instances of VSAConnection class share the same environment variable to store the connection information.

    hidden [void] CopyObject( $InputObject )
    {
        if( $($InputObject.URI) )
        {
            $this.URI = $InputObject.URI
            $this.Token = $InputObject.Token
            $this.UserName = $InputObject.UserName
            $this.UserName = $InputObject.UserName
            $this.SessionExpiration = $( $InputObject.SessionExpiration -replace "T"," " )
        }
        else
        {
            throw "The Input Obect Does Not Contain URI"
        }
        if ( $($InputObject.Status) ) {
            $this.Status = $InputObject.Status
        } else {
            $this.Status = [ConnectionState]::Open
        }
    }

#region constructors

    VSAConnection( 
        [PSObject] $InputObject # Existing connection object.
    )
    {
        $this.CopyObject( $InputObject )        
    }

    VSAConnection( 
        [PSCustomObject] $InputObject, # Response from the authorization interface doen't contain the VSA server address
        [string] $URI                  # the VSA server address 
    )
    {
        $this.Status = [ConnectionState]::Open
        if( -not $($InputObject.URI) )
        {
            $InputObject | Add-Member -NotePropertyName 'URI' -NotePropertyValue $URI
        }
        $this.CopyObject( $InputObject )
    }

#endregion constructors    

    hidden [void] RestorePersistent ( )
    {
        if ( [VSAConnection]::IsPersistent -and -not( [string]::IsNullOrEmpty( $env:VSAConnection) ) )
        {
            $InputObject = [Management.Automation.PSSerializer]::Deserialize([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($env:VSAConnection)))
            $this.CopyObject( $InputObject )
        }
    }

    [string] GetStatus()
    {
        switch ($this.Status)
        {
            Open
            {
                if ( $((Get-Date).ToUniversalTime()) -gt $this.SessionExpiration )
                {
                    $this.Status = [ConnectionState]::Expired
                }
            }
            default
            {
                if( [string]::IsNullOrEmpty($this.Token) )
                {
                    $this.Status = [ConnectionState]::Closed
                }
                # If connection is not Open The $env:VSAConnection should not store the object
                $env:VSAConnection = $null
                [VSAConnection]::IsPersistent = $false
            }
        }
        return $this.Status 
    }

    [string] GetUserName()
    {
        return $this.UserName
    }

    [string] GetToken()
    {
        if( [VSAConnection]::IsPersistent )
        {
            $this.RestorePersistent()
        }
        return $this.Token
    }

    [void] SetPersistent( [bool] $IsPersistent )
    {
        [VSAConnection]::IsPersistent = $IsPersistent

        if( [VSAConnection]::IsPersistent ) {
            $env:VSAConnection = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([Management.Automation.PSSerializer]::Serialize($this)))
        } else {
            $env:VSAConnection = $null
        }
    }

    [void] SetPersistent()
    {
        $this.SetPersistent( $true )
    }

    [bool] GetPersistent()
    {
        return [VSAConnection]::IsPersistent
    }

    static [string] GetPersistentToken()
    {
        [string]$TheToken = $null
        if([VSAConnection]::IsPersistent)
        {
            $InputObject = [Management.Automation.PSSerializer]::Deserialize([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($env:VSAConnection)))    
            $TheToken = $InputObject.Token     
        }
        return $TheToken
    }

    static [string] GetPersistentURI()
    {
        [string]$TheURI = $null
        if([VSAConnection]::IsPersistent)
        {
            $InputObject = [Management.Automation.PSSerializer]::Deserialize([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($env:VSAConnection)))    
            $TheURI = $InputObject.URI    
        }
        return $TheURI
    }
}
#endregion Class VSAConnection

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
        [switch] $NonInteractive
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
    if ($NonInteractive) {
        Log-Event -Msg "Running in non-interactive mode" -Id 0000 -Type "Information"

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

    $URI = "$VSAServer/$AuthSuffix"
    $AuthString  = "Basic $Encoded"

    Log-Event -Msg "Attempting to authenticate with $VSAServer" -Id 0000 -Type "Information"
    $result = Get-RequestData -URI $URI -authString $AuthString  | Select-Object -ExpandProperty Result
    
    if ($result)
    {
        [VSAConnection]$conn = [VSAConnection]::new( $result, $VSAServer )

        [datetime]$ExpiresAsUTC = $result.SessionExpiration -replace "T"," "
        Log-Event -Msg "Successfully authenticated. Token expiration date: $ExpiresAsUTC (UTC)." -Id 2000 -Type "Information"

        if ($MakePersistent) { $conn.SetPersistent( $true ) }
    }
    else
    {
        Log-Event -Msg "Could not get authentication response" -Id 4001 -Type "Error"
		throw "Could not get authentication response"
		
    }

    return $conn    
}
#endregion function New-VSAConnection

Export-ModuleMember -Function New-VSAConnection