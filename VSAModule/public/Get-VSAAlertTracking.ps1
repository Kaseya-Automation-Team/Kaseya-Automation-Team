function Get-VSAAlertTracking
{
    <#
    .Synopsis
       Retrieves alert tracking information.
    .DESCRIPTION
       Retrieves tracking information for a specified alert-tracking id. This endpoint is a POST that
       returns data (no request body), so the call is not gated by ShouldProcess.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AlertTrackingId
        Specifies the alert-tracking id.
    .EXAMPLE
       Get-VSAAlertTracking -AlertTrackingId 100
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       Alert tracking information.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/automation/getalerttracking/{0}',

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" } return $true })]
        [string] $AlertTrackingId
    )
    process {
        $URISuffix = $URISuffix -f $AlertTrackingId
        return Invoke-VSAWriteRequest -Method POST -URISuffix $URISuffix -VSAConnection $VSAConnection
    }
}
Export-ModuleMember -Function Get-VSAAlertTracking
