function Set-VSASystemAlert
{
    <#
    .Synopsis
       Configures a system alert.
    .DESCRIPTION
       Sets the actions (create ticket, send email, notify users, run script) for a system alert
       identified by its alert id.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AlertId
        Specifies the alert id.
    .PARAMETER CreateTicket
        Creates a ticket when the alert triggers.
    .PARAMETER SendEmail
        Sends an email when the alert triggers.
    .PARAMETER NotificationBarUsers
        Users to notify in the notification bar.
    .PARAMETER InfoCenterUsers
        Users to notify in the Info Center.
    .PARAMETER UsersToEmail
        Recipients of the alert email.
    .PARAMETER ScriptId
        Specifies an agent procedure to run when the alert triggers.
    .PARAMETER RuntimeData
        Specifies runtime data (hashtable/pscustomobject) for the alert.
    .PARAMETER Attributes
        Specifies additional attributes (hashtable/pscustomobject).
    .EXAMPLE
       Set-VSASystemAlert -AlertId 100 -CreateTicket $true -SendEmail $true -UsersToEmail 'ops@example.com'
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the configuration was successful.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/automation/systemalerts/{0}',

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" } return $true })]
        [string] $AlertId,

        [Parameter(Mandatory = $false)] [bool] $CreateTicket,
        [Parameter(Mandatory = $false)] [bool] $SendEmail,
        [Parameter(Mandatory = $false)] [string] $NotificationBarUsers,
        [Parameter(Mandatory = $false)] [string] $InfoCenterUsers,
        [Parameter(Mandatory = $false)] [string] $UsersToEmail,
        [Parameter(Mandatory = $false)] [int] $ScriptId,
        [Parameter(Mandatory = $false)] [object] $RuntimeData,
        [Parameter(Mandatory = $false)] [object] $Attributes
    )
    process {
        $URISuffix = $URISuffix -f $AlertId
        [hashtable] $BodyHT = ConvertTo-VSARequestBody -BoundParameters $PSBoundParameters `
            -Include @('CreateTicket', 'SendEmail', 'NotificationBarUsers', 'InfoCenterUsers', 'UsersToEmail', 'ScriptId')
        if ($null -ne $RuntimeData) { $BodyHT['RuntimeData'] = ConvertTo-VSAHashtable $RuntimeData }
        if ($null -ne $Attributes)  { $BodyHT['Attributes']  = ConvertTo-VSAHashtable $Attributes }
        return Invoke-VSAWriteRequest -Body $BodyHT -Method POST -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Set-VSASystemAlert
