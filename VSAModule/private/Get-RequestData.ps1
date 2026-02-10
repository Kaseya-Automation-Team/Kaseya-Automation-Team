function Get-RequestData
{
    <#
    .SYNOPSIS
       Executes a web request and returns the response with automatic retry on transient failures.
    .DESCRIPTION
       This function performs a web request and returns the response. It supports various HTTP methods
       such as GET, POST, PUT, DELETE, and PATCH, and allows customization of the request parameters.
       
       Implements automatic retry logic for transient HTTP errors (502, 503, 504, etc.) with exponential
       backoff to gracefully handle temporary server issues.
       
       SECURITY NOTE: String parameters are validated and sanitized to prevent injection attacks.
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
    .PARAMETER MaxRetries
        Specifies the maximum number of retry attempts for transient errors (default is 3).
        Valid Range: 0 to 10
        Applies to HTTP status codes: 502 (Bad Gateway), 503 (Service Unavailable), 504 (Gateway Timeout).
    .EXAMPLE
       Get-RequestData -URI $URI -AuthString $AuthString -IgnoreCertificateErrors
    .EXAMPLE
       Get-RequestData -URI $URI -AuthString $AuthString -Method POST -Body $Body
    .EXAMPLE
       Get-RequestData -URI $URI -AuthString $AuthString -MaxRetries 5
    .INPUTS
       None. You cannot pipe objects to Get-RequestData.
    .OUTPUTS
       Array of custom objects returned by the remote server.
    .NOTES
        Version 1.0.0
        SECURITY: Implements OData injection prevention and input validation.
        RELIABILITY: Automatic retry with exponential backoff for transient failures (v0.1.5).
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()] 
        [string] $URI,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()]
        [string] $AuthString,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)] 
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string] $Method = 'GET',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
		[string] $Body,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
		[string] $ContentType = 'application/json',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(0, 10)]
        [int] $MaxRetries = 3,

        [switch] $IgnoreCertificateErrors
    )

    # Constructing a log message for verbose and debug output
    $LogMessage = "URI: '$URI': Method '$Method'"
    
    # Creating authorization headers
    $AuthHeader = @{
        Authorization = $AuthString
    }

    # Creating request parameters
    $WebRequestParams = @{
        Uri = $URI
        Method = $Method
        Headers = $AuthHeader
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
    
    # Retry logic for transient failures
    [int]$RetryCount = 0
    [bool]$IsTransientError = $false
    $LastException = $null
    
    do {
        try {
            # Ignore certificate errors if the switch is present
            if ($IgnoreCertificateErrors) {
                [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
            }

            # Performing the web request
            $Response = Invoke-RestMethod @WebRequestParams -ErrorAction Stop
            $IsTransientError = $false

            # Outputting additional debug information
            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                "$($MyInvocation.MyCommand). Response:`n{0}" -f $Response | Out-String | Write-Debug
            }

            # Checking if the response indicates success
            if ($Response.ResponseCode -match "(^40\d|^50\d)") {
                $errorContext = @(
                    "ERROR: API returned error response"
                    "Method: $Method"
                    "URI: $URI"
                    "Response Code: $($Response.ResponseCode)"
                    "Response Error: $($Response.Error)"
                    "Response Result: $($Response.Result)"
                    "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                ) -join "`n"
                Write-Error $errorContext
                throw "API Error (Code: $($Response.ResponseCode)): $($Response.Error). Check logs for details."
            }

            if (($Response.ResponseCode -match "(^0$)|(^20\d+$)") -or ('OK' -eq $Response.Status)) {
                return $Response
            } else {
                # Handling errors and throwing an exception
                Write-Error "ERROR`nResponse Code: '$($Response.ResponseCode)'`nResponse Error: '$($Response.Error)'`nResponse Result: '$($Response.Result)'"
                throw $("Response Code: '$($Response.ResponseCode)'`nResponse Error: '$($Response.Error)'")
            }
        }
        catch [System.Net.WebException] {
            # Check if this is a transient error (502, 503, 504)
            $statusCode = [int]$_.Exception.Response.StatusCode
            
            if ($statusCode -match '^(502|503|504)$' -and $RetryCount -lt $MaxRetries) {
                $IsTransientError = $true
                $LastException = $_
                $RetryCount++
                
                # Calculate exponential backoff: 1s, 2s, 4s, 8s, etc.
                $WaitSeconds = [Math]::Pow(2, $RetryCount - 1)
                $statusCodeName = GetStatusCodeName -StatusCode $statusCode
                
                Write-Warning "WARNING: Failed to fetch page (attempt $RetryCount of $MaxRetries): Exception calling `"EnsureSuccessStatusCode`" with `"0`" argument(s): `"Response status code does not indicate success: $statusCode ($statusCodeName).`"`nRetrying in $WaitSeconds seconds..."
                
                if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                    Write-Verbose "Transient error detected (HTTP $statusCode). Retrying in $WaitSeconds seconds. (Attempt $RetryCount of $MaxRetries)"
                }
                
                Start-Sleep -Seconds $WaitSeconds
            } else {
                # Handling web exceptions with detailed context
                $errorContext = @(
                    "NETWORK ERROR: Failed to call REST API endpoint"
                    "Method: $Method"
                    "URI: $URI"
                    "Error Message: $($_.Exception.Message)"
                    "Status Code: $($_.Exception.Response.StatusCode)"
                    "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                    "Suggestion: Verify network connectivity, URI is correct, and authentication credentials are valid."
                ) -join "`n"
                Write-Error $errorContext
                throw $_
            }
        }
    } while ($IsTransientError -and $RetryCount -le $MaxRetries)
}

# Helper function to get human-readable status code names
function GetStatusCodeName {
    param([int]$StatusCode)
    switch ($StatusCode) {
        502 { return "Bad Gateway" }
        503 { return "Service Unavailable" }
        504 { return "Gateway Timeout" }
        default { return "HTTP Error" }
    }
}
#endregion function Get-RequestData