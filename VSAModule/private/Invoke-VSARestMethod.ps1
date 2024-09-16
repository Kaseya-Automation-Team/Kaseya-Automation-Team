function Invoke-VSARestMethod {
    <#
    .SYNOPSIS
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
    .PARAMETER Skip
        Specifies the number of records to skip for paging.
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
        Version 0.1.5
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

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1, 100)]
        [int] $RecordsPerPage = 100,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()] 
        [string] $Skip,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string] $Sort,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [int] $MaxRecordsPerSession = 25000
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
        Write-Verbose "Invoke-VSARestMethod. Calling Get-RequestData."
    }
    
    $response = Get-RequestData @WebRequestParams

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