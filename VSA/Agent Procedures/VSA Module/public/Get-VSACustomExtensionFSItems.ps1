function Get-VSACustomExtensionFSItems
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
    .PARAMETER Paging
        Specifies REST API Paging.
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

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/customextensions/{0}/folder/{1}',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
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
        [string] $Paging,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    $Path = $Path -replace '\\', '/'
    if ($Path -notmatch '^\/') { $Path = "/$Path"}
    if ($Path -notmatch '\/$') { $Path = "$Path/"}

    $URISuffix = $URISuffix -f $AgentId, $Path

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    If ( $AgentId -in $(Get-VSAAgents @Params | Select-Object -ExpandProperty AgentID) ) {

        $Params.Add('URISuffix', $URISuffix)
        if($Filter)        {$Params.Add('Filter', $Filter)}
        if($Paging)        {$Params.Add('Paging', $Paging)}
        if($Sort)          {$Params.Add('Sort', $Sort)}

        $Params | Out-String | Write-Verbose
        $Params | Out-String | Write-Debug

        $result = Get-VSAItems @Params

    } else {
        $Message = "The asset with Agent ID `'$AgentId`' does not exist"
        Log-Event -Msg $Message -Id 4000 -Type "Error"
        throw $Message
    }

    #Rest API erroneously adds the '.99.99.99.99' string to the file base name in the Name field
    $result = $result | Select-Object -Property *, `
                @{Name = 'FSObjectName'; Expression = { $_.Name -replace "(\.99){4}", "" }}

    return $result
}
Export-ModuleMember -Function Get-VSACustomExtensionFSItems