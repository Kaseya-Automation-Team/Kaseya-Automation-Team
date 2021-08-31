<#
POC
   Module VSA
   Version 0.2.3
   Author: Vladislav Semko
   Modified: Aliaksandr Serzhankou
   Modification date: 08-27-21
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

Class VSAConnection
{
    [string] $URI
    [datetime] $ExpiresUTC
    hidden [ConnectionState] $Status
    hidden [string] $Token
    hidden [string] $UserName

#region constructors
    VSAConnection([string] $UserName)
    {
        $this.UserName = $UserName
        $this.Status = [ConnectionState]::Closed
    }

    VSAConnection( 
        [string] $ExistingToken,
        [string] $UserName
    )
    {
        $this.Token = $ExistingToken
        $this.UserName = $UserName
        $this.Status = [ConnectionState]::Open
    }
#endregion constructors

    [string] GetStatus()
    {
        switch ($this.Status)
        {
            Open
            {
                if ( $((Get-Date).ToUniversalTime()) -gt $this.ExpiresUTC )
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
        return $this.Token
    }

    [void] RefreshToken()
    {
    }
}

function Get-VSAConnection {
#region connection object

#endregion connection object

#--------------------------------------------------------------------------------------------
[string] $VSAEndpoint = 'https://54.67.117.115/api/v1.0'
[string] $Username = 'sasha'
[string] $PAT = 'fe47717e-8965-4586-acd4-3eb0b37f290e'


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