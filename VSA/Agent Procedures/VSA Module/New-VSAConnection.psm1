<#
POC
   Module VSA
   Version 0.2.2
   Author: Vladislav Semko
   Modified: Aliaksandr Serzhankou
   Modification date: 08-24-21
#>

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


#Log entries to Application log
function Log-Event {
    param(        
        [Parameter(Mandatory=$true)][String]$Msg,
        [Parameter(Mandatory=$true)][Int]$Id,
        [Parameter(Mandatory=$true)][String]$Type
    )

    #Check if log source alread exists
    $SourceExists = [System.Diagnostics.EventLog]::SourceExists("VSA API Module")

    #If not, create a new one
    if ($SourceExists -eq $false) {
        New-EventLog –LogName Application –Source “VSA API Module”
    }

    Write-EventLog –LogName Application –Source “VSA API Module” –EntryType $Type –EventID $Id  –Message $Msg -Category 0
    $CurrentTime = Get-Date
    Write-Host "$CurrentTime`: $Type`: $Msg"
}

#region function Get-RequestData
function Get-RequestData
{
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()] 
        [string] $URI,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()] 
        [string] $AuthString,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)] 
        [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH")]
        [string] $Method = "GET"
    )

    $authHeader = @{
        Authorization = $AuthString
    }

    $requestParameters = @{
        Uri = $URI
        Method = $Method
        Headers = $authHeader
    }
    
    Log-Event -Msg "Executing call $Method : $URI" -Id 0010 -Type "Information"
    $response = Invoke-RestMethod @requestParameters
    if (0 -eq $response.ResponseCode) {
        return $response.Result
    } else {
        throw $response.Error
    }
}
Export-ModuleMember -Function Get-RequestData
#endregion function Get-RequestData

#region function Get-VSAUsers
function Get-VSAUsers
{

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [VSAConnection] $VSAConnection,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $SystemUsersSuffix = 'system/users',
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    if ( $($VSAConnection.GetStatus()) -eq "Open") #if token is valid
    {
        $CombinedURL = "$($VSAConnection.URI)/$SystemUsersSuffix"
        
        if ($Filter) {
            $CombinedURL = -join ($CombinedURL, "`?`$filter=$Filter")
        }

        if ($Paging) {
            if ($Filter -or $Sort) {
                $CombinedURL = -join ($CombinedURL, "`&`$$Paging")
            } else {
                $CombinedURL = -join ($CombinedURL, "`?`$$Paging")
            }
        }

        $result = Get-RequestData -URI "$CombinedURL" -AuthString "Bearer $($VSAConnection.GetToken())"

        return $result
    }
    else
    { throw "Connection status: $ConnectionStatus" }
}
Export-ModuleMember -Function Get-VSAUsers
#endregion function Get-VSAUsers

#============================================================================================