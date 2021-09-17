
function Get-VSACustomExtensionFSItems
{
    <#
    .Synopsis

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
        # regex (\.99){4}

    } else {
        $Message = "The asset with Agent ID `'$AgentId`' does not exist"
        Log-Event -Msg $Message -Id 4000 -Type "Error"
        throw $Message
    }

}
Export-ModuleMember -Function Get-VSACustomExtensionFSItems