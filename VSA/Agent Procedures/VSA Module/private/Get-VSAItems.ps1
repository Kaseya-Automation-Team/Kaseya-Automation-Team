function Get-VSAItems
{
<#
.Synopsis
   Returns VSA items using Get  REST API method
.DESCRIPTION
   Returns existing VSA objects.
   Takes either persistent or non-persistent connection information.
.PARAMETER VSAConnection
    Specifies existing non-persistent VSAConnection.
.PARAMETER URISuffix
    Specifies URI suffix if it differs from the default.
.PARAMETER RecordsPerPage
    Specifies number of objects returned by reques. 100 by default.
.PARAMETER Filter
    Specifies REST API Filter.
.PARAMETER Paging
    Specifies REST API Paging.
.PARAMETER Sort
    Specifies REST API Sorting.
.EXAMPLE
   Get-VSAItems
.EXAMPLE
   Get-VSAItems -VSAConnection $connection
.INPUTS
   Accepts piped non-persistent VSAConnection 
.OUTPUTS
   Array of custom objects that represent VSA objects.
#>
    [CmdletBinding()]
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
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateRange(1,1000)]
        [int]$RecordsPerPage = 100,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )
    if ( $null -eq $VSAConnection )
    {
        if ( [VSAConnection]::GetPersistent() )
        {
            $CombinedURL = "$([VSAConnection]::GetPersistentURI())/$URISuffix"
            $UsersToken = "Bearer $( [VSAConnection]::GetPersistentToken() )"
        }
    }
    else
    {
        $ConnectionStatus = $VSAConnection.GetStatus()

        if ( 'Open' -eq $ConnectionStatus )
        {
            $CombinedURL = "$($VSAConnection.URI)/$URISuffix"
            $UsersToken = "Bearer $( $VSAConnection.GetToken() )"
        }
        else
        {
            throw "Connection status: $ConnectionStatus`n"
        }
    }
    #region Filterin, Sorting, Paging
    [string]$JoinWith = '?'

    if ( $Filter ) {
        $CombinedURL += "$JoinWith`$filter=$Filter"
        $JoinWith = '&'
    }
    if ( $Sort ) {
        $CombinedURL += "$JoinWith`$orderby=$Sort"
        $JoinWith = '&'
    }
    if ($Paging) {
        $CombinedURL += "$JoinWith`$$Paging"
    }
    
    $URI = $CombinedURL

    #endregion Filterin, Sorting, Paging
    $requestParameters = @{
        Uri = $URI
        Method = 'GET'
        AuthString = $UsersToken
    }
    
    "Request" | Write-Debug 
    $requestParameters | ConvertTo-Json -Depth 3 | Out-String | Write-Debug
    "Calling Get-RequestData" | Write-Verbose
    "Calling Get-RequestData" | Write-Debug
    $response = Get-RequestData @requestParameters
    "Response" | Write-Debug 
    $response | Out-String | Write-Debug 
    $result = $response | Select-Object -ExpandProperty Result
    if( $response.TotalRecords ) #if request returns field TotalRecords
    {
        [int]$TotalRecords = $response | Select-Object -ExpandProperty TotalRecords
        "Records: $TotalRecords" | Write-Verbose
        "Records: $TotalRecords" | Write-Debug
    
        $Pages = [int][Math]::Ceiling($TotalRecords / $RecordsPerPage)

        if ( $Pages -gt 1 )
        {
            [int]$PageProcessed = 1
            while ($PageProcessed -lt $Pages)
            {
                $Paging = "skip=$($RecordsPerPage * $PageProcessed)"
        
                $URI = "$CombinedURL$JoinWith`$$Paging"
                $requestParameters.Uri = $URI
                $result += Get-RequestData @requestParameters | Select-Object -ExpandProperty Result
                $PageProcessed++
            }
        }
    }
    "Result"  | Write-Debug
    $result | Out-String | Write-Debug
    return $result
}
