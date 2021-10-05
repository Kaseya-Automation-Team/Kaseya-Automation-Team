function Add-VSADocumentFolder
{
    <#
    .Synopsis
       Adds documents folder on the Audit > Documents page.
    .DESCRIPTION
       Adds documents folder on the Audit > Documents page.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Folder
        Specifies new folder relative path.
    .EXAMPLE
       Add-VSADocumentFolder -AgentId 10001 -Folder 'NewFolder'
    .EXAMPLE
       Add-VSADocumentFolder -AgentId 10001 -Folder 'NewFolder' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/documents/{0}/folder/{1}',

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

    [string]$FileName  = $($SourceFilePath.Name)
    $Folder            = $Folder -replace '\\', '/'
    $URISuffix         = $URISuffix -f $AgentId, $Folder

    [hashtable]$Params = @{
                            'URISuffix' = $URISuffix
                            'Method'    = 'PUT'
                          }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params | Out-String | Write-Debug

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Add-VSADocumentFolder