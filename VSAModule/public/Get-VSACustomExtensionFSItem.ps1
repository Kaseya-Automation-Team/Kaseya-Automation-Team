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
    .EXAMPLE
       Get-VSACustomExtensionFSItems
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
        [string] $Sort
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

    $result = Invoke-VSARestMethod @Params

    #Rest API erroneously adds the '.99.99.99.99' string to the file base name in the Name field
    $result = $result | Select-Object -Property *, `
                @{Name = 'FSObjectName'; Expression = { $_.Name -replace "(\.99){4}", "" }}

    return $result
    }
}
New-Alias -Name Get-VSACustomExtensionFSItems -Value Get-VSACustomExtensionFSItem
Export-ModuleMember -Function Get-VSACustomExtensionFSItem -Alias Get-VSACustomExtensionFSItems
