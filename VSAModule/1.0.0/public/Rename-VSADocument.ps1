function Rename-VSADocument
{
    <#
    .Synopsis
       Renames a document.
    .DESCRIPTION
       Rename a single document on the Audit > Documents page. Enter the existing name of the document in the Source parameter and the new name in the Destination parameter.
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
       Rename-VSADocument -AgentId 10001 -Source "OldName.txt" -Destination "NewName.txt"
    .EXAMPLE
       Rename-VSADocument -AgentId 10001 -Source "OldName.txt" -Destination "NewName.txt" -VSAConnection $connection
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
        [string] $URISuffix = 'api/v1.0/assetmgmt/documents/{0}/Rename/{1}/{2}',

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

    if ($Source -eq $Destination) {
        [string]$Msg = "The source ($Source) and the destination ($Destination) are the same"
        throw $Msg 
    } else {
            [hashtable]$Params = @{
            'URISuffix' = $($URISuffix -f $AgentId, $Source, $Destination)
            'Method'    = 'DELETE'
        }
        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

        return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Rename-VSADocument