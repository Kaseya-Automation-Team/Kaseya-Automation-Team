function Remove-VSADocument
{
    <#
    .Synopsis
       Delete a document.
    .DESCRIPTION
       Deletes a single document on the Audit > Documents page.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Path
        Specifies relative path to a file.
    .EXAMPLE
       Remove-VSADocument -AgentId 10001 -Path "Folder\File.ext"
    .EXAMPLE
       Remove-VSADocument -AgentId 10001 -Path "Folder\File.ext" -VSAConnection $connection
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
        [string] $URISuffix = 'api/v1.0/assetmgmt/documents/{0}/{1}',

        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentID,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    $Path = $Path -replace '\\', '/'

    $URISuffix   = $URISuffix -f $AgentId, $Path

    [hashtable]$Params = @{
                            'URISuffix' = $URISuffix
                            'Method'    = 'DELETE'
                            }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params | Out-String | Write-Debug

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Remove-VSADocument