#region function Get-RequestData
function Get-RequestData
{
    <#
    .Synopsis
       Returns web request's response
    .DESCRIPTION
       Returns response fo formed web request.
    .PARAMETER URI
        Specifies URI for the web request.
    .PARAMETER AuthString
        Specifies authentication string.
    .PARAMETER Method
        Specifies REST API method.
    .PARAMETER Body
        Specifies the request's Body.
    .EXAMPLE
       Get-RequestData -URI $URI -AuthString $AuthString
    .EXAMPLE
       Get-RequestData -URI $URI -AuthString $AuthString
    .INPUTS
       None. You cannot pipe objects to Get-RequestData. 
    .OUTPUTS
       Array of custom objects returned by the remote server.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithOutBody'
            )]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithBody'
            )] 
        [ValidateNotNullOrEmpty()] 
        [string] $URI,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithOutBody'
            )]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithBody'
            )]
        [string] $AuthString,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithOutBody'
            )]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithBody'
            )]
        [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH")]
        [string] $Method = "GET",

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithBody'
            )]
        [ValidateNotNullOrEmpty()]
		[string] $Body,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithBody'
            )]
        [ValidateNotNullOrEmpty()]
		[string] $ContentType = "application/json"
    )

    $authHeader = @{
        Authorization = $AuthString
    }

    $requestParameters = @{
        Uri = $URI
        Method = $Method
        Headers = $authHeader
    }

    if( $Body ) {
        $requestParameters.Add('Body', $Body)
        $requestParameters.Add('ContentType', $ContentType)
    }
    
    $requestParameters | Out-String | Write-Verbose
    $requestParameters | Out-String | Write-Debug

    Log-Event -Msg "Executing call $Method : $URI" -Id 1000 -Type "Information"
   
    try {
            $response = Invoke-RestMethod @requestParameters -ErrorAction Stop
            if ($response) {
                Write-Debug "Response"
                $response | Out-String | Write-Debug
                if ( ($response.ResponseCode -in @(0, 200, 201, 202, 204)) -or ('OK' -eq $response.Status) ) {
                    return $response
                } else {
                    Write-Error "$response.Result"
                    Write-Error "$response.Error"
                    throw $($response.Error)
                }
            } else {
                "No response returned" | Write-Debug
                "No response returned" | Write-Verbose
            }
            
    }
    catch [System.Net.WebException] {
        Write-Error( "Executing call $Method failed for $URI.`nMessage : $($_.Exception.Message)" )
        throw $_
    }
}
#endregion function Get-RequestData