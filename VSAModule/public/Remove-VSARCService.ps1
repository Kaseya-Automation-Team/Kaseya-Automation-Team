function Remove-VSARCService
{
    <#
    .Synopsis
       Deletes a custom remote-control service.
    .DESCRIPTION
       Deletes a custom remote-control service identified by its service id.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ServiceId
        Specifies the id of the remote-control service to delete.
    .PARAMETER Force
        Forces deletion even when the service is in use.
    .EXAMPLE
       Remove-VSARCService -ServiceId 'a1b2...'
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the deletion was successful.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/assets/deletercservice',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ServiceId,

        [Parameter(Mandatory = $false)]
        [switch] $Force
    )
    process {
        $query = "?serviceId={0}&force={1}" -f [uri]::EscapeDataString($ServiceId), $Force.IsPresent.ToString().ToLower()
        $URISuffix = $URISuffix + $query
        return Invoke-VSAWriteRequest -Method DELETE -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Remove-VSARCService
