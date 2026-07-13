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
    [CmdletBinding(SupportsShouldProcess)]
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
    process {

    $Folder = $Folder -replace '\\', '/'

    return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($($URISuffix -f $AgentId, $Folder)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
New-Alias -Name Add-VSACustomExtensionFolder -Value New-VSACustomExtensionFolder
Export-ModuleMember -Function New-VSACustomExtensionFolder -Alias Add-VSACustomExtensionFolder