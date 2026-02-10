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
       True if successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
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

    if ($Source -eq $Destination) {
        return $false
    } else {

        [hashtable]$Params = @{
            VSAConnection = $VSAConnection
            URISuffix     = $($URISuffix -f $AgentId, $Source, $Destination)
            Method        = 'PUT'
        }
        #Remove empty keys
        foreach ( $key in $Params.Keys.Clone() ) {
            if ( -not $Params[$key] )  { $Params.Remove($key) }
        }

        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            $Result | Out-String | Write-Debug
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            $Result | Out-String | Write-Verbose
        }

        return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Move-VSADocument