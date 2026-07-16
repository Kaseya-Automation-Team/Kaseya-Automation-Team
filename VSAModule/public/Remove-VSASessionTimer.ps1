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
    .PARAMETER TimerId
        Specifies the Id of the session timer to delete.
    .PARAMETER Force
        Issues the request as PATCH instead of DELETE, which is how this endpoint distinguishes
        removing the timer with its data committed to the database from removing it without.
        NOTE: despite the name, this is NOT a confirmation bypass -- it selects a different API
        operation. To suppress the confirmation prompt use -Confirm:$false.
    .EXAMPLE
       Remove-VSASessionTimer -TimerId 123
    .EXAMPLE
       Remove-VSASessionTimer -TimerId 123 -VSAConnection $connection -Force
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
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
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
    process {
    $Method = if ($Force) { 'PATCH' } else { 'DELETE' }

    return Invoke-VSAWriteRequest -Method $Method -URISuffix ($URISuffix -f $TimerId) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}

Export-ModuleMember -Function Remove-VSASessionTimer