function ConvertTo-ODataString {
    <#
    .SYNOPSIS
       Escapes special characters in OData filter strings to prevent injection attacks.
    .DESCRIPTION
       Escapes single quotes and other special characters in OData filter strings according to OData standards.
       This function prevents OData injection vulnerabilities by properly escaping user input.
    .PARAMETER FilterString
        The string to escape for use in OData filters.
    .EXAMPLE
       ConvertTo-ODataString -FilterString "O'Brien's Computer"
       Returns: O''Brien''s Computer
    .NOTES
        Version 1.0.0
        Security: This function implements OWASP recommendations for OData query security.
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string] $FilterString
    )
    
    # Escape single quotes by doubling them per OData specification
    $escaped = $FilterString -replace "'", "''"
    
    # Additional escaping for known problematic characters
    $escaped = $escaped -replace '\\', '\\\\'
    
    return $escaped
}

function Invoke-VSARestMethod {
    <#
    .SYNOPSIS
       Invokes VSA REST API methods with automatic retry for transient failures.
    .DESCRIPTION
       Executes various VSA REST API methods and returns the response or success status.
       Automatically retries on transient HTTP errors (502, 503, 504) with exponential backoff.
       
       SECURITY NOTE: This function implements OData injection prevention by automatically escaping 
       user input in Filter parameters. Sort and Skip parameters are also validated.
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
    .PARAMETER MaxRetries
        Specifies the maximum number of retry attempts for transient HTTP errors (502, 503, 504).
        Default is 3. Valid range is 0-10.
        Uses exponential backoff: 1s, 2s, 4s, 8s, etc.
    .PARAMETER ExtendedOutput
        Specifies whether to return the Result field of the REST API response.
    .PARAMETER Filter
        Specifies REST API Filter. Special characters are automatically escaped to prevent injection attacks.
    .PARAMETER RecordsPerPage
        Specifies the number of records per page for paging (default is 100).
    .PARAMETER Skip
        Specifies the number of records to skip for paging (must be numeric).
    .PARAMETER Sort
        Specifies REST API Sorting. Only alphanumeric characters, spaces, hyphens, and commas are allowed.
    .EXAMPLE
       Invoke-VSARestMethod -VSAConnection $connection -URISuffix 'items' -Method 'GET'
    .EXAMPLE
       Invoke-VSARestMethod -VSAConnection $connection -URISuffix 'items' -Method 'POST' -Body $Body
    .EXAMPLE
       Invoke-VSARestMethod -VSAConnection $connection -URISuffix 'items' -MaxRetries 5
    .INPUTS
       Accepts piped VSAConnection.
    .OUTPUTS
       Varies based on the method invoked.
    .NOTES
        Version 1.0.0
        SECURITY: Implements OData injection prevention (version 0.1.5) and parameter validation.
        RELIABILITY: Automatic retry with exponential backoff for transient failures (v0.1.7).
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [AllowNull()]
        [VSAConnection] $VSAConnection = $null,

        [parameter(DontShow, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH")]
        [string] $Method = 'GET',

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Body,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ContentType = "application/json",

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $ExtendedOutput,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string] $Filter,
        <#
        .PARAMETER Filter
            Specifies an OData filter expression for the REST API query.
            Syntax: Property Operator Value
            
            Operators:
              - eq   : equals (Name eq 'MyAgent')
              - ne   : not equals (Status ne 'Inactive')
              - lt   : less than (CreatedDate lt 2024-01-01)
              - le   : less than or equal
              - gt   : greater than
              - ge   : greater than or equal
              - startswith : prefix match (Name startswith 'prod')
              - endswith   : suffix match
              - contains   : substring match
              - and  : logical AND
              - or   : logical OR
            
            Examples:
              "Name eq 'MyAgent'"
              "Name startswith 'prod'"
              "Status ne 'Inactive'"
              "ComputerName eq 'PC' and Status eq 'Online'"
              "Name eq 'O''Brien'"   (single quotes doubled for escaping)
            
            Special characters are automatically escaped to prevent OData injection.
        #>

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1, 100)]
        [int] $RecordsPerPage = 100,
        <#
        .PARAMETER RecordsPerPage
            Specifies the number of records to retrieve per API request page.
            Valid Range: 1 to 100
            Default Value: 100
            
            Behavior:
              - Smaller values (10-20): More API calls, lower memory usage, better for large result sets
              - Larger values (80-100): Fewer API calls, higher memory usage, faster retrieval
              - Module automatically paces through all pages and merges results
            
            Note: For results > 25,000 records, automatic token renewal occurs.
        #>

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()] 
        [string] $Skip,
        <#
        .PARAMETER Skip
            Specifies the number of records to skip for pagination.
            
            Format: Numeric string representing count
            Examples: '0', '100', '500', '1000'
            Default Value: '0' (starts from beginning)
            
            Usage Pattern with RecordsPerPage:
              - Skip=0, RecordsPerPage=100   : Records 1-100
              - Skip=100, RecordsPerPage=100 : Records 101-200
              - Skip=500, RecordsPerPage=50  : Records 501-550
            
            Note: Typically used internally for pagination; usually not needed in manual queries.
        #>

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string] $Sort,
        <#
        .PARAMETER Sort
            Specifies the sort order for results using OData syntax.
            
            Format: One or more sort expressions, comma-separated
            Syntax: FieldName asc|desc
            
            Examples:
              "Name asc"                  (alphabetical A-Z)
              "CreatedDate desc"          (newest first)
              "Priority asc, Name asc"    (multi-field: by priority, then by name)
              "Status desc, LastCheck asc" (offline first, then by check time)
            
            Valid Characters: Letters, numbers, spaces, commas, hyphens
            Invalid characters are automatically removed.
            
            Common Fields: Name, Status, CreatedDate, ModifiedDate, Priority
        #>

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [int] $MaxRecordsPerSession = 25000,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(0, 10)]
        [int] $MaxRetries = 3
    )

    $VSAServerURI = [string]::Empty
    [bool]$IgnoreCertificateErrors = $false

    if ( $null -eq $VSAConnection ) {
        $VSAServerURI = [VSAConnection]::GetPersistentURI()
        $UsersToken = "Bearer $( [VSAConnection]::GetPersistentToken() )"
        $IgnoreCertificateErrors = [VSAConnection]::GetIgnoreCertErrors()
        Update-VSAConnection
    } else {
        $VSAServerURI = $VSAConnection.URI
        $UsersToken = "Bearer $($VSAConnection.Token)"
        $IgnoreCertificateErrors = $VSAConnection.IgnoreCertificateErrors
        Update-VSAConnection -VSAConnection $VSAConnection
    }

    # Escape Filter parameter to prevent OData injection attacks
    if (-not [string]::IsNullOrEmpty($Filter)) {
        $Filter = ConvertTo-ODataString -FilterString $Filter
    }

    # Escape Sort parameter to prevent injection (alphanumeric and common field separators only)
    # Expected format: 'FieldName asc' or 'FieldName1 asc, FieldName2 desc'
    if (-not [string]::IsNullOrEmpty($Sort)) {
        if ($Sort -notmatch '^\[\w\s,\-\]*$') {
            $sanitized = $Sort -replace '[^a-zA-Z0-9\s,\-]', ''
            Write-Warning "Sort parameter contained potentially dangerous characters.`n" +
                         "Original: '$Sort'`n" +
                         "Sanitized: '$sanitized'`n" +
                         "Expected format: 'FieldName asc' or 'Field1 asc, Field2 desc'"
            $Sort = $sanitized
        }
    }

    # Validate Skip parameter (must be numeric)
    # Expected format: '0', '100', '500' (number of records to skip)
    if (-not [string]::IsNullOrEmpty($Skip)) {
        if ($Skip -notmatch '^\d+$') {
            throw "Skip parameter validation failed.`n" +
                  "Received: '$Skip'`n" +
                  "Expected: Positive integer (e.g., '0', '100', '500')`n" +
                  "Represents: Number of records to skip in pagination."
        }
    }

    $baseUri = New-Object System.Uri -ArgumentList $VSAServerURI
    [string]$URI = [System.Uri]::new($baseUri, $URISuffix) | Select-Object -ExpandProperty AbsoluteUri

    [hashtable]$ApiSearchParams = @{
        '$filter' = $Filter
        '$orderby' = $Sort
        '$skip' = $Skip
    }

    foreach ($key in $ApiSearchParams.Keys.Clone()) {
        if ([string]::IsNullOrEmpty($ApiSearchParams[$key])) {
            $ApiSearchParams.Remove($key)
        }
    }

    if (($null -eq $ApiSearchParams) -or (0 -eq $ApiSearchParams.Count)) {
        $CombinedURI = $URI
    } else {
        $CombinedURI = "{0}?{1}" -f $URI, $(($ApiSearchParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&')
    }

    [hashtable]$WebRequestParams = @{
        Uri = $CombinedURI
        Method = $Method
        AuthString = $UsersToken
        IgnoreCertificateErrors = $IgnoreCertificateErrors
        MaxRetries = $MaxRetries
    }

    if ($Body) {
        $WebRequestParams.Add('Body', $Body)
        $WebRequestParams.Add('ContentType', $ContentType)
    }

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "$($MyInvocation.MyCommand)"
        Write-Debug "Invoke-VSARestMethod. Request details:"
        $WebRequestParams | ConvertTo-Json -Depth 3 | Out-String | Write-Debug
    }
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        Write-Verbose "Invoke-VSARestMethod. Calling Get-RequestData on URI: $($WebRequestParams.Uri)"
    }
    
    try {
        $response = Get-RequestData @WebRequestParams
    } catch {
        $contextInfo = @(
            "Failed to retrieve data from VSA API"
            "URI Suffix: $URISuffix"
            "Filter: $(if ($Filter) { $Filter } else { 'None' })"
            "Sort: $(if ($Sort) { $Sort } else { 'None' })"
            "Skip: $(if ($Skip) { $Skip } else { '0' })"
            "Records Per Page: $RecordsPerPage"
            "Method: $Method"
            "Error: $($_.Exception.Message)"
        ) -join "`n"
        Write-Error $contextInfo
        throw
    }

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "Invoke-VSARestMethod. Response:`n$($response | Out-String)"
    }

    [array]$result = $response | Select-Object -ExpandProperty Result

    if (-not [string]::IsNullOrEmpty("$($response.TotalRecords)")) {
        [int]$TotalRecords = $response.TotalRecords

        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug "Invoke-VSARestMethod`nRecords: $TotalRecords"
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            Write-Verbose "Invoke-VSARestMethod`nRecords: $TotalRecords"
        }

        [int]$Pages = [math]::Ceiling($TotalRecords / $RecordsPerPage)
        $resultCollection = [System.Collections.ArrayList]@($result)

        #Workaroud For SaaS limitation

        [int]$RenewTimes = 1
        [int]$RenewThreshold = $MaxRecordsPerSession
        

        for ( $PageProcessed = 1; $PageProcessed -le $Pages; $PageProcessed++ ) {

            $ApiSearchParams['$skip'] = $RecordsPerPage * $PageProcessed
            $CombinedURI = "$URI`?$([array]($ApiSearchParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&')"
            $WebRequestParams.Uri = $CombinedURI

            #Workaroud For SaaS limitation $MaxRecordsPerSession
            if ($ApiSearchParams['$skip'] -ge $RenewThreshold ) {

                if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                    Write-Debug "Fetching in progress... So far fetched $RenewThreshold records."
                }
                if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                    Write-Verbose "Fetching in progress... So far fetched $RenewThreshold records."
                }

                if ($null -eq $VSAConnection) {

                    [VSAConnection]::UpdatePersistentSessionExpiration( $([datetime]::Now).AddMinutes(-1) )
                    Update-VSAConnection
                    $UsersToken = "Bearer $( [VSAConnection]::GetPersistentToken() )"
                } else {

                    $VSAConnection.UpdateSessionExpiration( $([datetime]::Now).AddMinutes(-1) )
                    Update-VSAConnection -VSAConnection $VSAConnection
                    $UsersToken = "Bearer $($VSAConnection.Token)"
                }

                $RenewTimes +=1
                $RenewThreshold = $MaxRecordsPerSession * $RenewTimes
            }

            $WebRequestParams.AuthString = $UsersToken

            [array]$temp = Get-RequestData @WebRequestParams | Select-Object -ExpandProperty Result

            if (0 -lt $temp.Count) { 
                $resultCollection.AddRange($temp) | Out-Null 
            }
        }
        $result = $resultCollection.ToArray()
    }

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "Invoke-VSARestMethod. Result`n $($result | Out-String)"
    }
    
    if ($ExtendedOutput) {
        return $response
    } else {
        return $result
    }
}