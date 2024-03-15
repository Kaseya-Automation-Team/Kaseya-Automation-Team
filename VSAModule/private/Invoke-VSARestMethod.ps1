function Invoke-VSARestMethod
{
    <#
    .Synopsis
       Invokes VSA REST API methods.
    .DESCRIPTION
       Executes various VSA REST API methods and returns the response or success status.
    .PARAMETER VSAConnection
        Specifies the established VSAConnection.
    .PARAMETER URISuffix
        Specifies the URI suffix if it differs from the default.
    .PARAMETER Method
        Specifies the REST API Method (default is "GET").
    .PARAMETER Body
        Specifies the request body for methods that require it.
    .PARAMETER ContentType
        Specifies the content type of the request (default is "application/json").
    .PARAMETER ExtendedOutput
        Specifies whether to return the Result field of the REST API response.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER RecordsPerPage
        Specifies the number of records per page for paging (default is 100).
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Invoke-VSARestMethod -VSAConnection $connection -URISuffix 'items' -Method 'GET'
    .EXAMPLE
       Invoke-VSARestMethod -VSAConnection $connection -URISuffix 'items' -Method 'POST' -Body $Body
    .INPUTS
       Accepts piped VSAConnection.
    .OUTPUTS
       Varies based on the method invoked.
    .NOTES
        Version 0.1
    #>
    [alias("Get-VSAItems", "Update-VSAItems")]
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH")]
        [string] $Method = 'GET',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Body,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ContentType = "application/json",

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [switch] $ExtendedOutput,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1,100)]
        [int] $RecordsPerPage = 100,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    $VSAServerURI = [string]::Empty
    [bool]$IgnoreCertificateErrors = $false

    if ( $null -eq $VSAConnection )
    {
        if ( [VSAConnection]::GetPersistent() )
        {
            $VSAServerURI = [VSAConnection]::GetPersistentURI()
            $UsersToken = "Bearer $( [VSAConnection]::GetPersistentToken() )"
            $IgnoreCertificateErrors = [VSAConnection]::GetIgnoreCertErrors()
        }
    } else {
        $VSAServerURI = $VSAConnection.URI
        $UsersToken = "Bearer {0}" -f $($VSAConnection.Token)
        $IgnoreCertificateErrors = $VSAConnection.IgnoreCertificateErrors
    }

    # Convert the base URI and URISuffix into a full URI
    $baseUri = New-Object System.Uri -ArgumentList $VSAServerURI
    [string]$URI = [System.Uri]::new($baseUri, $URISuffix) | Select-Object -ExpandProperty AbsoluteUri

    #region Filtering, Sorting, Paging
    # Hashtable to store filtering, sorting, and paging parameters
    [hashtable]$ApiSearchParams = @{
        '$filter'   = $Filter
        '$orderby'  = $Sort
        '$Paging'   = $Paging
    }

    # Filter out & remove null or empty Remove empty keys
    foreach ( $key in $ApiSearchParams.Keys.Clone() ) {
        if ( [string]::IsNullOrEmpty( $ApiSearchParams[$key] ) )  { $ApiSearchParams.Remove($key) }
    }

    # If Filtering, Sorting and Paging values are null or empty, set $CombinedURI to just $URI
    if ( ($null -eq $ApiSearchParams) -or (0 -eq $ApiSearchParams.Count) ) {
        $CombinedURI = $URI        
    } else {
        # Add Filtering, Sorting and Paging to the initial URI
        $CombinedURI = "{0}?{1}" -f $URI, $(($ApiSearchParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&')
    }
    #endregion Filtering, Sorting, Paging

    # Hashtable to store API request details
    $WebRequestParams = @{
        Uri = $CombinedURI
        Method = $Method
        AuthString = $UsersToken
        IgnoreCertificateErrors = $IgnoreCertificateErrors
    }

    # Add Body and ContentType to the API request details if specified
    if ($Body) {
        $WebRequestParams.Add('Body', $Body)
        $WebRequestParams.Add('ContentType', $ContentType)
    }

    # Output the API request details for debugging
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "$($MyInvocation.MyCommand)"
        Write-Debug "Invoke-VSARestMethod. Request details:"
        $WebRequestParams | ConvertTo-Json -Depth 3 | Out-String | Write-Debug
        "Calling Get-RequestData"
    }
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        "Invoke-VSARestMethod. Calling Get-RequestData."
    }
    
    # Call the Get-RequestData function with the API request details
    $response = Get-RequestData @WebRequestParams

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "Invoke-VSARestMethod. Response:`n$($response | Out-String)" | Write-Debug 
    }

    # Extract the 'Result' field from the response
    [array]$result = $response | Select-Object -ExpandProperty Result

    # Process paging if TotalRecords is specified in the response
    if ( -not [string]::IsNullOrEmpty("$($response.TotalRecords)")  ) {
        [int]$TotalRecords = $response.TotalRecords

        #region messages to verbose and debug streams
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            "Invoke-VSARestMethod`nRecords: $TotalRecords" | Write-Debug
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            "Invoke-VSARestMethod`nRecords: $TotalRecords"  | Write-Verbose
        }
        #endregion messages to verbose and debug streams

        [int]$Pages = [math]::Ceiling($TotalRecords / $RecordsPerPage)

        if ($null -eq $ApiSearchParams) {
            $ApiSearchParams = @{}
        }

        #region processing multiple pages
        if ( $Pages -gt 1 ) {

            $resultCollection = [System.Collections.ArrayList]@($result)

            for ($PageProcessed = 1; $PageProcessed -le $Pages; $PageProcessed++) {
                if ($ApiSearchParams.ContainsKey('$skip')) {
                    $ApiSearchParams['$skip'] = $RecordsPerPage * $PageProcessed
                } else {
                    $ApiSearchParams.Add('$skip', $RecordsPerPage * $PageProcessed)
                }

                $CombinedURI = "$URI`?$([array]($ApiSearchParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&')"
                $WebRequestParams.Uri = $CombinedURI
                [array]$temp = Get-RequestData @WebRequestParams | Select-Object -ExpandProperty Result

                if ( 0 -lt $temp.Count) { $resultCollection.AddRange( $temp ) | Out-Null }
            }
            $result = $resultCollection.ToArray()
        }
        #endregion processing multiple pages
    }

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "Invoke-VSARestMethod. Result`n $($result | Out-String)" | Write-Debug
    }
    
    if ($ExtendedOutput) {
        return $response
    } else {
        return $result
    }
}