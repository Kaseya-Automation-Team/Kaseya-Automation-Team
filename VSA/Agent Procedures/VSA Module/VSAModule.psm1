<#
POC
   Module VSA
   Version 0.4.2
   Author: Vladislav Semko
   Modified: Aliaksandr Serzhankou
   Modification date: 09-03-21
#>
#Replace with

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
            Write-Error -Msg "Failed to import function $($import.fullname): $_"
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
    [string] $URI
    [datetime] $SessionExpiration
    hidden [ConnectionState] $Status
    hidden [string] $Token
    hidden [string] $UserName
    static hidden [bool] $IsPersistent #all instances of VSAConnection class use the same environment variable to store connection information

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
        [PSObject] $InputObject
    )
    {
        $this.CopyObject( $InputObject )        
    }

    VSAConnection( 
        [PSCustomObject] $InputObject,
        [string] $URI
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
        if ( [VSAConnection]::IsPersistent -and -not( [string]::IsNullOrEmpty( $env:VSACOnnection) ) )
        {
            $InputObject = [Management.Automation.PSSerializer]::Deserialize([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($env:VSACOnnection)))
            $this.CopyObject( $InputObject )
        }
    }

    [string] GetStatus()
    {
        switch ($this.Status)
        {
            Open
            {
                Write-Host
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
                # If connection is not Open The $env:VSACOnnection should not store the object
                $env:VSACOnnection = $null
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
            $env:VSACOnnection = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([Management.Automation.PSSerializer]::Serialize($this)))
        } else {
            $env:VSACOnnection = $null
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
            $InputObject = [Management.Automation.PSSerializer]::Deserialize([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($env:VSACOnnection)))    
            $TheToken = $InputObject.Token     
        }
        return $TheToken
    }

    static [string] GetPersistentURI()
    {
        [string]$TheURI = $null
        if([VSAConnection]::IsPersistent)
        {
            $InputObject = [Management.Automation.PSSerializer]::Deserialize([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($env:VSACOnnection)))    
            $TheURI = $InputObject.URI    
        }
        return $TheURI
    }
}
#endregion Class VSAConnection

#region function New-VSAConnection
function New-VSAConnection {
<#
.PARAMETER VSAServer
    Address of the VSA Server to connect
#>
    [cmdletbinding()]
    [OutputType([VSAConnection])]
    param(
        [parameter(ValueFromPipeline,
            Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$VSAServer,
        [parameter(ValueFromPipeline,
            Mandatory = $true,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String] $UserName,
        [parameter(ValueFromPipeline,
            Mandatory = $true,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [String] $PAT,
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $AuthSuffix = 'API/v1.0/Auth',
        [parameter(Mandatory=$false)]
        [switch] $MakePersistent
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
    $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$Username`:$PAT"))

    $URI = "$VSAServer/$AuthSuffix"
    $AuthString  = "Basic $Encoded"

    Log-Event -Msg "Attempting to authenticate" -Id 0001 -Type "Information"
    $result = Get-RequestData -URI $URI -authString $AuthString
    
    if ($result)
    {
        [VSAConnection]$conn = [VSAConnection]::new( $result, $VSAServer )

        [datetime]$ExpiresAsUTC = $result.SessionExpiration -replace "T"," "
        Log-Event -Msg "Successfully authenticated. Token expiration date: $ExpiresAsUTC (UTC)." -Id 0002 -Type "Information"

        if ($MakePersistent) { $conn.SetPersistent( $true ) }
    }
    else
    {
        throw "Could not get authentication response"
    }

    return $conn    
}
#endregion function New-VSAConnection

Export-ModuleMember -Function New-VSAConnection

function Get-VSAConnection {
#region connection object

#endregion connection object

#--------------------------------------------------------------------------------------------
[string] $VSAEndpoint = ''
[string] $Username = ''
[string] $PAT = ''


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

$Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$Username`:$PAT"))

[string] $AuthSuffix = 'Auth'
$URI = "$VSAEndpoint/$AuthSuffix"
$AuthString  = "Basic $Encoded"
#endregion authentication stuff
#--------------------------------------------------------------------------------------------

Log-Event -Msg "Attempting to authenticate" -Id 0001 -Type "Information"
$result = Get-RequestData -URI $URI -authString $AuthString

if ($result)
{
    #If authentication attempt seems to be OK, create VSAConnection object
    [VSAConnection]$conn = [VSAConnection]::new( $result.Token, $result.UserName )

    [datetime]$ExpiresAsUTC = $result.SessionExpiration -replace "T"," "
    Log-Event -Msg "Successfully authenticated. Token expiration date: $ExpiresAsUTC (UTC)." -Id 0002 -Type "Information"
    $conn.URI = $VSAEndpoint
    $conn.ExpiresUTC = $ExpiresAsUTC
    $conn.Status = [ConnectionState]::Open

        
    #Get-VSAUsers -VSAConnection $conn
}
return $conn
}

Export-ModuleMember -Function Get-VSAConnection

#region function Get-VSAUsers

#endregion function Get-VSAUsers

#============================================================================================