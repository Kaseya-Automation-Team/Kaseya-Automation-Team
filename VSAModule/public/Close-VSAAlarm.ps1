function Close-VSAAlarm
{
    <#
    .Synopsis
       Closes VSA alarm
    .DESCRIPTION
       Switches status of specific VSA alarm from Open to Closed
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.\
    .PARAMETER AlarmId
        Specifies id of alarm
    .PARAMETER Reason
        Optional parameter which specifies reason why alarm has been closed
    .EXAMPLE
       Close-VSAAlarm -AlarmId 5 -Reason "Planned restart"
    .EXAMPLE
       Close-VSAAlarm -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       No output
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = "api/v1.0/assetmgmt/alarms/{0}/close",

        [Alias('ID')]
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AlarmId,

        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Reason
    )

    $URISuffix = $URISuffix -f $AlarmId

    if ($Reason) {
        $Body = ConvertTo-Json @(@{"key"="notes";"value"=$Reason }) -Compress
    }

    return Invoke-VSAWriteRequest -Body $Body -Method 'PUT' -URISuffix ($URISuffix -f $AlarmId) -VSAConnection $VSAConnection -Caller $PSCmdlet
}

Export-ModuleMember -Function Close-VSAAlarm