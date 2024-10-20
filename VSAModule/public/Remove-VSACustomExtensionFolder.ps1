﻿function Remove-VSACustomExtensionFolder
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
    [CmdletBinding()]
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

    $Folder = "//$Folder"
    $Folder = $Folder -replace '\\', '/'

    [hashtable]$Params = @{}

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    If ( $AgentId -notin $(Get-VSAAgent @Params | Select-Object -ExpandProperty AgentID) ) {
        #No response for REST API call
        $Message = "The asset with Agent ID `'$AgentId`' does not exist"
        throw $Message
    } else {
        $Params.Add('URISuffix', $($URISuffix -f $AgentId, $Folder))
        $Params.Add('Method', 'DELETE')

        return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Remove-VSACustomExtensionFolder