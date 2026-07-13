function Remove-VSACustomExtensionFolder
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
       Remove-VSACustomExtensionFolder -AgentId '10001' -Folder 'NewFolder'
    .EXAMPLE
       Remove-VSACustomExtensionFolder -AgentId '10001' -Folder '/NewFolder1/NewFolder2/'
    .EXAMPLE
       Remove-VSACustomExtensionFolder -AgentId '10001' -Folder 'NewFolder3' -VSAConnection $connection
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
        [string] $URISuffix = 'api/v1.0/assetmgmt/customextensions/{0}/{1}',

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\w+"  ){
                throw "Enter folder name"
            }
            return $true
        })]
        [string] $Folder
    )
    process {

    # Build the normalized path into a new variable rather than reassigning $Folder: PowerShell
    # re-runs a parameter's [ValidateScript] on every assignment to that same variable, and the
    # normalized "//..." form fails the original ^\w+ check, so reassigning $Folder directly
    # made this cmdlet throw on every call regardless of input.
    $FolderPath = "//$Folder" -replace '\\', '/'

    # No collection-wide existence pre-check (F-38): a nonexistent AgentId now surfaces as the
    # API's own 4xx error (via the transport's improved error handling) instead of a second,
    # wasteful GET-the-whole-collection call before every removal.
    return Invoke-VSAWriteRequest -Method 'DELETE' -URISuffix ($($URISuffix -f $AgentId, $FolderPath)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Remove-VSACustomExtensionFolder