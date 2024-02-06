#region function Get-RequestData
function Get-RequestData
{
    <#
    .SYNOPSIS
       Executes a web request and returns the response.
    .DESCRIPTION
       This function performs a web request and returns the response. It supports various HTTP methods
       such as GET, POST, PUT, DELETE, and PATCH, and allows customization of the request parameters.
    .PARAMETER URI
        Specifies the URI for the web request.
    .PARAMETER AuthString
        Specifies the authentication string.
    .PARAMETER Method
        Specifies the REST API method (GET, POST, PUT, DELETE, PATCH).
    .PARAMETER Body
        Specifies the request's body.
    .PARAMETER ContentType
        Specifies the content type of the request (default is "application/json").
    .PARAMETER IgnoreCertificateErrors
        Ignores certificate errors if this switch is present.
    .EXAMPLE
       Get-RequestData -URI $URI -AuthString $AuthString -IgnoreCertificateErrors
    .EXAMPLE
       Get-RequestData -URI $URI -AuthString $AuthString -Method POST -Body $Body
    .INPUTS
       None. You cannot pipe objects to Get-RequestData.
    .OUTPUTS
       Array of custom objects returned by the remote server.
    .NOTES
        Version 0.1.1
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithoutRequestBody'
            )]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithRequestBody'
            )] 
        [ValidateNotNullOrEmpty()] 
        [string] $URI,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithoutRequestBody'
            )]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithRequestBody'
            )]
        [string] $AuthString,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithoutRequestBody'
            )]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithRequestBody'
            )]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string] $Method = 'GET',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithRequestBody')]
        [ValidateNotNullOrEmpty()]
		[string] $Body,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'WithRequestBody')]
        [ValidateNotNullOrEmpty()]
		[string] $ContentType = 'application/json',

        [switch] $IgnoreCertificateErrors
    )

    # Constructing a log message for verbose and debug output
    $LogMessage = "URI: '$URI': Method '$Method'"
    
    # Creating authorization headers
    $authHeader = @{
        Authorization = $AuthString
    }

    # Creating request parameters
    $WebRequestParams = @{
        Uri = $URI
        Method = $Method
        Headers = $authHeader
    }

    # Adding body and content type if the Body parameter is specified
    if ($Body) {
        $WebRequestParams.Add('Body', $Body)
        $WebRequestParams.Add('ContentType', $ContentType)
    }

    # Outputting log messages to verbose and debug streams
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "Get-RequestData. $LogMessage" | Write-Debug
        "$_ `nJSON:$($WebRequestParams | ConvertTo-Json -Depth 3 | Out-String)" | Write-Debug
    }

    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        Write-Verbose "Get-RequestData. $LogMessage"
    }
    
    try {
        # Ignore certificate errors if the switch is present
        if ($IgnoreCertificateErrors) {
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }

        # Performing the web request
        $response = Invoke-RestMethod @WebRequestParams -ErrorAction Stop

        # Outputting additional debug information
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            "$($MyInvocation.MyCommand). Response:`n{0}" -f $response | Out-String | Write-Debug
        }

        # Checking if the response indicates success
        if (($response.ResponseCode -match "(^0$)|(^20\d$)") -or ('OK' -eq $response.Status)) {
            return $response
        } else {
            # Handling errors and throwing an exception
            Write-Error "$($response.Result)`n$($response.Error)"
            throw $($response.Error)
        }
    }
    catch [System.Net.WebException] {
        # Handling web exceptions and throwing an exception
        Write-Error("Executing call $Method failed for $URI.`nMessage : $($_.Exception.Message)")
        throw $_
    }
}
#endregion function Get-RequestData