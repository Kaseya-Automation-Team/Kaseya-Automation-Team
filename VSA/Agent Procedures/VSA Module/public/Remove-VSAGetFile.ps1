function Remove-VSAGetFile
{
    <#
    .Synopsis
       Deletes a file on the Agent Procedures > Get File page.
    .DESCRIPTION
       Deletes a file on the Agent Procedures > Get File page.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Path
        Specifies Relative path to the file.
    .EXAMPLE
       Remove-VSAGetFile -AgentId 10001 -Path 'File.ext'
    .EXAMPLE
       Remove-VSAGetFile -AgentId 10001 -Path 'File.ext' -VSAConnection $connection
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
        [string] $URISuffix = 'api/v1.0/assetmgmt/getfiles/{0}/{1}',

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
        [string] $Path
    )
    
    if (-not [string]::IsNullOrEmpty($Path) ) {
        $Path = $Path -replace '\\', '/'
        #if ($Path -notmatch '^\/') { $Path = "/$Path"}
        #if ($Path -notmatch '\/$') { $Path = "$Path/"}
    }

    $URISuffix = $URISuffix -f $AgentId, $Path

    [hashtable]$Params = @{
                            'URISuffix' = $URISuffix
                            'Method'    = 'DELETE'
                            }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params | Out-String | Write-Debug

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Remove-VSAGetFile