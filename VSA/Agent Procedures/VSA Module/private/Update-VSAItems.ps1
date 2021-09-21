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
.EXAMPLE
   Update-VSAItems
.EXAMPLE
   Update-VSAItems -VSAConnection $connection
.INPUTS
   Accepts piped non-persistent VSAConnection 
.OUTPUTS
   True if method call was successful or False elsewhere.
#>
    [CmdletBinding()]
    [OutputType([bool])]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NonPersistent')]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateSet("POST", "PUT", "DELETE", "PATCH")]
        [string] $Method,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$false,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()]
        [string] $Body,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$false,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()]
        [string] $ContentType
    )

    [bool]$result = $false #by default

    if ([VSAConnection]::IsPersistent)
    {
        $CombinedURL = "$([VSAConnection]::GetPersistentURI())/$URISuffix"
        $UsersToken = "Bearer $( [VSAConnection]::GetPersistentToken() )"
    }
    else
    {
        $ConnectionStatus = $VSAConnection.GetStatus()

        if ( 'Open' -eq $ConnectionStatus )
        {
            $CombinedURL = "$($VSAConnection.URI)/$URISuffix"
            $UsersToken = "Bearer $($VSAConnection.GetToken())"
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

    $requestParameters | Out-String | Write-Debug

    #$result = Get-RequestData -URI $CombinedURL -AuthString $UsersToken
    "Calling Get-RequestData" | Write-Verbose
    "Calling Get-RequestData" | Write-Debug
    $response = Get-RequestData @requestParameters
    if ($response) {
        if ( ($response.ResponseCode -in @(0, 200, 201, 202, 204)) -or ('OK' -eq $response.Status) )
        {
            $result = $true
        }
    } else {
        $result = $true
        "No response returned" | Write-Debug
        "No response returned" | Write-Verbose
    }
    return $result
}
