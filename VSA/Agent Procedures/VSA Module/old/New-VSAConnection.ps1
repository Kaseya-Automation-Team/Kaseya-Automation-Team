<#
POC
   Module VSA
   Version 0.2.1
   Author: Vladislav Semko
   Modified: Aliaksandr Serzhankou
   Modification date: 08-24-21
#>


#region connection object
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
                Write-Host
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
#endregion connection object

#Check if log source alread exists
$SourceExists = [System.Diagnostics.EventLog]::SourceExists("VSA API Module")

#If not, create a new one
if ($SourceExists -eq $false) {
    New-EventLog –LogName Application –Source “VSA API Module”
}

#Log entries to Application log
function Log-Event {
    param(        
        [Parameter(Mandatory=$true)][String]$Msg,
        [Parameter(Mandatory=$true)][Int]$Id,
        [Parameter(Mandatory=$true)][String]$Type
    )
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
        [string] $Filter
    )

    $ConnectionStatus = $VSAConnection.GetStatus()

    if ( $ConnectionStatus -eq [ConnectionState]::Open) #if token is valid
    {
        $result = Get-RequestData -URI "$($VSAConnection.URI)/$SystemUsersSuffix" -authString "Bearer $($VSAConnection.GetToken())"
        return $result
    }
    else
    { throw "Connection status: $ConnectionStatus" }
}
#endregion function Get-VSAUsers

#============================================================================================

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

<#
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
#endregion function Get-StringHash 

#region authentication stuff
#[string]$ReqId = [guid]::NewGuid().ToString()
[string]$Random = (Get-Random).ToString()

[string]$RawSHA256Hash = Get-StringHash $PAT
[string]$CoveredSHA256HashTemp = Get-StringHash ($PAT+$Username)
[string]$CoveredSHA256Hash = Get-StringHash ($CoveredSHA256HashTemp+$Random) 
[string]$RawSHA1Hash = Get-StringHash $PAT "SHA1"
[string]$CoveredSHA1HashTemp = Get-StringHash ($PAT+$Username) "SHA1"
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

#>

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

    
    #Get-VSAUsers -VSAConnection $conn
}