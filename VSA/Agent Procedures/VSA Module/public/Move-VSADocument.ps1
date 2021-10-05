function Move-VSADocument
{
    <#
    .Synopsis
       Moves a document.
    .DESCRIPTION
       Moves a document from one folder to another folder on the Audit > Documents page.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Source
        Specifies source file name
    .PARAMETER Destination
        Specifies destination file name
    .EXAMPLE
       Move-VSADocument -AgentId 10001 -Source "OldName.txt" -Destination "NewName.txt"
    .EXAMPLE
       Move-VSADocument -AgentId 10001 -Source "OldName.txt" -Destination "NewName.txt" -VSAConnection $connection
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
        [string] $URISuffix = 'api/v1.0/assetmgmt/documents/{0}/file/Move/{1}/{2}',

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
        [string] $Source,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Destination
    )

    $Source      = $Source -replace '\\', '/'
    $Destination = $Destination -replace '\\', '/'

    if ($Source -ne $Destination) {

        $URISuffix   = $URISuffix -f $AgentId, $Source, $Destination

        [hashtable]$Params = @{
                                'URISuffix' = $URISuffix
                                'Method'    = 'PUT'
                              }

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

        $Params | Out-String | Write-Debug

        return Update-VSAItems @Params
    } else {
        return $false
    }
}
Export-ModuleMember -Function Move-VSADocument