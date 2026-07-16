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
    .PARAMETER AgentID
        Specifies the agent whose document is moved.
    .EXAMPLE
       Move-VSADocument -AgentId 10001 -Source "OldName.txt" -Destination "NewName.txt"
    .EXAMPLE
       Move-VSADocument -AgentId 10001 -Source "OldName.txt" -Destination "NewName.txt" -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if successful.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
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

        return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($URISuffix -f $AgentId, (Format-VSAPathSegment $Source), (Format-VSAPathSegment $Destination)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Move-VSADocument