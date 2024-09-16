function Remove-VSASessionTimer
{
    <#
    .Synopsis
       Deletes a SessionTimer.
    .DESCRIPTION
       Deletes a SessionTimer without committing the data to the database or with.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .EXAMPLE
       Remove-VSASessionTimer -TimerId 123
    .EXAMPLE
       Remove-VSASessionTimer -TimerId 123 -VSAConnection $connection -Force
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful.
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/system/sessiontimers/{0}",

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $TimerId,

        [switch] $Force
)
    [hashtable]$Params =@{
        URISuffix = $($URISuffix -f $TimerId)
    }

    if ($Force) {
        $Params.Add('Method', 'PATCH')
    } else {
        $Params.Add('Method', 'DELETE')
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Remove-VSASessionTimer