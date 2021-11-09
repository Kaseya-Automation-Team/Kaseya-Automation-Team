function Update-VSAItems
{
<#
.Synopsis
   Updates VSA items using Get  REST API method
.DESCRIPTION
   Creates, modifies or deletes VSA objects. Returns if update was successful.
   Takes either persistent or non-persistent connection information.
.PARAMETER VSAConnection
    Specifies existing non-persistent VSAConnection.
.PARAMETER URISuffix
    Specifies URI suffix if it differs from the default.
.PARAMETER Method
    Specifies REST API Method.
.PARAMETER ExtendedOutput
    Specifies wether to return the Result field of the REST API response.
.EXAMPLE
   Update-VSAItems
.EXAMPLE
   Update-VSAItems -VSAConnection $connection
.INPUTS
   Accepts piped non-persistent VSAConnection 
.OUTPUTS
   True if method call was successful or False elsewhere.
   The Result field of the REST API response if the ExtendedOutput specified.
#>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateSet("POST", "PUT", "DELETE", "PATCH")]
        [string] $Method,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Body,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ContentType,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [switch] $ExtendedOutput
    )

    [bool]$result = $false #by default
    $ExtendedResult

    if ( $null -eq $VSAConnection )
    {
        if ( [VSAConnection]::GetPersistent() )
        {
            $CombinedURL = "$([VSAConnection]::GetPersistentURI())/$URISuffix"
            $UsersToken = "Bearer $( [VSAConnection]::GetPersistentToken() )"
        }
    }
    else
    {
        $ConnectionStatus = $VSAConnection.GetStatus()

        if ( 'Open' -eq $ConnectionStatus )
        {
            $CombinedURL = "$($VSAConnection.URI)/$URISuffix"
            $UsersToken = "Bearer $( $VSAConnection.GetToken() )"
        }
        else
        {
            throw "Connection status: $ConnectionStatus"
        }
    }

    $requestParameters = @{
        Uri = $CombinedURL
        Method = $Method
        AuthString = $UsersToken
    }

    if( $Body ) {
        $requestParameters.Add('Body', $Body)
    }

    if( $ContentType ) {

        [string[]]$AllowedContentTypes = @("application/json", "multipart/form-data")

        if ( ( $AllowedContentTypes | Foreach-object {$ContentType -match $_}) -contains $true ) {
            $requestParameters.Add('ContentType', $ContentType)
        }
    }

    $requestParameters | ConvertTo-Json -Depth 3 | Out-String | Write-Debug

    #$result = Get-RequestData -URI $CombinedURL -AuthString $UsersToken
    "$($MyInvocation.MyCommand). Calling Get-RequestData" | Write-Verbose
    "$($MyInvocation.MyCommand). Calling Get-RequestData" | Write-Debug
    $response = Get-RequestData @requestParameters
    if ( $response ) {
        if ( ($response.ResponseCode -match "(^0$)|(^20\d$)") -or ('OK' -eq $response.Status) )
        {
            $result = $true
            $ExtendedResult = $response
        }
    } else {
        $result = $true
        "$($MyInvocation.MyCommand). No response returned" | Write-Debug
        "$($MyInvocation.MyCommand). No response returned" | Write-Verbose
    }

    if ($ExtendedOutput) {
        return $ExtendedResult
    } else {
        return $result
    }
}
