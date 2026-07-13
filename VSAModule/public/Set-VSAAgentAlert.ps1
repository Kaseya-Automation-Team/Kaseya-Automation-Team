function Set-VSAAgentAlert
{
    <#
    .Synopsis
       Configures an agent alert.
    .DESCRIPTION
       Sets the actions (create alarm/ticket, send email, notify users, run script) for an agent
       alert identified by its alert id.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AlertId
        Specifies the alert id.
    .PARAMETER AgentGuid
        Specifies the agent guid the alert applies to.
    .PARAMETER CreateAlarm
        Creates an alarm when the alert triggers.
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
       Set-VSAAgentAlert -AlertId 100 -AgentGuid 123456789 -CreateTicket $true -SendEmail $true -UsersToEmail 'ops@example.com'
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the configuration was successful.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/automation/agentalerts/{0}',

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" } return $true })]
        [string] $AlertId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" } return $true })]
        [string] $AgentGuid,

        [Parameter(Mandatory = $false)] [bool] $CreateAlarm,
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
            -Include @('AgentGuid', 'CreateAlarm', 'CreateTicket', 'SendEmail', 'NotificationBarUsers', 'InfoCenterUsers', 'UsersToEmail', 'ScriptId')
        if ($null -ne $RuntimeData) { $BodyHT['RuntimeData'] = ConvertTo-VSAHashtable $RuntimeData }
        if ($null -ne $Attributes)  { $BodyHT['Attributes']  = ConvertTo-VSAHashtable $Attributes }
        return Invoke-VSAWriteRequest -Body $BodyHT -Method POST -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Set-VSAAgentAlert
