function Get-VSACustomExtensionFSItem
{
    <#
    .Synopsis
       Returns Custom Extension Folders and Files.
    .DESCRIPTION
       Returns Custom Extension Folders and Files.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Path
        Specifies Relative agent's path. By default it is equal '/' to show the files and folders starting with the top level.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .PARAMETER Parallel
        Fetches the remaining pages of a large collection concurrently instead of one after another.
        Opt-in: without it, behaviour is unchanged. Results are identical either way (same records,
        merged in $skip order). Only engages once the collection is large enough to be worth it
        (see -ParallelThreshold).
    .PARAMETER ThrottleLimit
        Maximum number of concurrent requests when -Parallel is used (default 8). On shared SaaS you
        are one tenant among many, so a modest value is a good citizen; the engine also reduces
        concurrency automatically if the server returns HTTP 429, then recovers.
    .PARAMETER ParallelThreshold
        Minimum total record count before -Parallel actually engages. 0 (default) means automatic:
        two full throttle windows, i.e. 2 * ThrottleLimit * 100 records. Below that the sequential
        path is used, because it is faster than paying to set up extra connections.    .EXAMPLE
       Get-VSACustomExtensionFSItems
    .PARAMETER AgentId
        Specifies the agent whose custom-extension file system is listed.
    .EXAMPLE
       Get-VSACustomExtensionFSItems -AgentId '10001' -Path '/NestedFolderLevel1/NestedFolderLevel2/'
    .EXAMPLE
       Get-VSACustomExtensionFSItems -AgentId '10001' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       Array of objects that represent Custom Extension Folders and Files.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/customextensions/{0}/folder/{1}',

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

        [Parameter(Mandatory = $false,
        HelpMessage = "Please enter relative path to the custom extensions' folder using '/' as delimiter")]
        [ValidateNotNullOrEmpty()]
        [string] $Path = '/',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Sort,

        # Opt-in parallel paging for large collections (see Invoke-VSARestMethod). No effect on small
        # ones: below -ParallelThreshold the sequential path is used.
        [parameter(Mandatory = $false)]
        [switch] $Parallel,

        [parameter(Mandatory = $false)]
        [ValidateRange(1, 64)]
        [int] $ThrottleLimit = 8,

        [parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $ParallelThreshold = 0
    )
    process {

    $Path = $Path -replace '\\', '/'
    if ($Path -notmatch '^\/') { $Path = "/$Path"}
    if ($Path -notmatch '\/$') { $Path = "$Path/"}

    # No collection-wide existence pre-check (F-38): a nonexistent AgentId now surfaces as the
    # API's own 4xx error (via the transport's improved error handling) instead of a second,
    # wasteful GET-the-whole-collection call before every lookup.
    [hashtable]$Params = @{
        URISuffix = $($URISuffix -f $AgentId, $Path)
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    # Forward the opt-in parallel controls to the shared read path, which owns the paging engine.
    if ($Parallel) {
        $Params['Parallel']      = $true
        $Params['ThrottleLimit'] = $ThrottleLimit
        if ($ParallelThreshold -gt 0) { $Params['ParallelThreshold'] = $ParallelThreshold }
    }
    $result = Invoke-VSARestMethod @Params

    #Rest API erroneously adds the '.99.99.99.99' string to the file base name in the Name field
    $result = $result | Select-Object -Property *, `
                @{Name = 'FSObjectName'; Expression = { $_.Name -replace "(\.99){4}", "" }}

    return $result
    }
}
New-Alias -Name Get-VSACustomExtensionFSItems -Value Get-VSACustomExtensionFSItem
Export-ModuleMember -Function Get-VSACustomExtensionFSItem -Alias Get-VSACustomExtensionFSItems
