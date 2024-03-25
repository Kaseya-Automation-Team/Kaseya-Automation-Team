function New-VSACustomExtensionFolder
{
    <#
    .Synopsis
       Creates Custom Extension Folder.
    .DESCRIPTION
       Creates Custom Extension Folder.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Folder
        Specifies Relative agent's path.
    .EXAMPLE
       New-VSACustomExtensionFolder -AgentId '10001' -Folder 'NewFolder'
    .EXAMPLE
       New-VSACustomExtensionFolder -AgentId '10001' -Folder '/NewFolder1/NewFolder2/'
    .EXAMPLE
       New-VSACustomExtensionFolder -AgentId '10001' -Folder 'NewFolder3' -VSAConnection $connection
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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Folder
    )

    $Folder = $Folder -replace '\\', '/'

    $URISuffix = $URISuffix -f $AgentId, $Folder

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    If ( $AgentId -in $(Get-VSAAgent @Params | Select-Object -ExpandProperty AgentID) ) {
        
        $Params.Add('URISuffix', $URISuffix)
        $Params.Add('Method', 'PUT')

        #region messages to verbose and debug streams
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            $Params | Out-String | Write-Debug
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            $Params | Out-String | Write-Verbose
        }
        #endregion messages to verbose and debug streams

        $result = Invoke-VSARestMethod @Params

        #No response for REST API call

    } else {
        $Message = "The asset with Agent ID `'$AgentId`' does not exist"
        throw $Message
    }

    return $result
}
New-Alias -Name Add-VSACustomExtensionFolder -Value New-VSACustomExtensionFolder
Export-ModuleMember -Function New-VSACustomExtensionFolder -Alias Add-VSACustomExtensionFolder