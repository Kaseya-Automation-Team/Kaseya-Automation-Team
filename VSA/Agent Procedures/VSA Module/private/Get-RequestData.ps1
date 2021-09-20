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
            ValueFromPipelineByPropertyName=$true
            )] 
        [ValidateNotNullOrEmpty()] 
        [string] $URI,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true
            )]
        [string] $AuthString,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
            )]
        [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH")]
        [string] $Method = "GET",

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
            )]
        [ValidateNotNullOrEmpty()]
		[string] $Body
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
        $requestParameters.Add('ContentType', "application/json")
    }
    
    $requestParameters | Out-String | Write-Verbose
    $requestParameters | Out-String | Write-Debug

    Log-Event -Msg "Executing call $Method : $URI" -Id 1000 -Type "Information"
   
    try {
            $response = Invoke-RestMethod @requestParameters -ErrorAction Stop
            if ($response) {
                $response | Out-String | Write-Debug
                if ( ($response.ResponseCode -in @(0, 200, 201, 202)) -or ('OK' -eq $response.Status) ) {
                    return $response
                } else {
                    Write-Host "$response.Error"
                    throw $response.Error
                }
            } else {
                "No response" | Write-Debug
                "No response" | Write-Verbose
            }
            
    } catch { throw $($_.Exception.Message) }
}
#endregion function Get-RequestData