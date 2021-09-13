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
            ParameterSetName = 'PutPostPatch')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'GetDelete')] 
        [ValidateNotNullOrEmpty()] 
        [string] $URI,
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'PutPostPatch')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'GetDelete')]
        [ValidateNotNullOrEmpty()]
        [string] $AuthString,
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'PutPostPatch')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'GetDelete')]
        [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH")]
        [string] $Method = "GET",
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'PutPostPatch')]
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
    
    Log-Event -Msg "Executing call $Method : $URI" -Id 1000 -Type "Information"
   
    try {
            $response = Invoke-RestMethod @requestParameters -ErrorAction Stop
            
            if (0 -eq $response.ResponseCode) {
                return $response
            } else {
                Log-Event -Msg "$response.Error" -Id 4000 -Type "Error"
                throw $response.Error
            }
    } catch { throw $($_.Exception.Message) }
}
#endregion function Get-RequestData