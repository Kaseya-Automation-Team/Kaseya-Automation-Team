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
    
    [string]$LogMessage = "Executing call $Method : $URI"
    Log-Event -Msg "$LogMessage" -Id 1000 -Type "Information"

    [string]$Json = $requestParameters  | ConvertTo-Json -Depth 3 | Out-String

    "$($MyInvocation.MyCommand). `n$LogMessage" | Write-Verbose
    "$($MyInvocation.MyCommand). `n$LogMessage `n$Json"| Write-Debug    
   
    try {
            $response = Invoke-RestMethod @requestParameters -ErrorAction Stop
            if ($response) {
                "$($MyInvocation.MyCommand). Response:`n$response" | Out-String | Write-Debug
                if ( ($response.ResponseCode -match "(^0$)|(^20\d$)" ) -or ('OK' -eq $response.Status) ) {
                    return $response
                } else {
                    Write-Error "$response.Result"
                    Write-Error "$response.Error"
                    throw $($response.Error)
                }
            } else {
                "$($MyInvocation.MyCommand). No response returned" | Write-Debug
                "$($MyInvocation.MyCommand). No response returned" | Write-Verbose
            }
            
    }
    catch [System.Net.WebException] {
        Write-Error( "Executing call $Method failed for $URI.`nMessage : $($_.Exception.Message)" )
        throw $_
    }
}
#endregion function Get-RequestData