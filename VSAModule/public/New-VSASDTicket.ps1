function New-VSASDTicket
{
    <#
    .Synopsis
       Creates a new service desk ticket.
    .DESCRIPTION
       Creates a new ticket in the specified service desk.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ServiceDeskId
        Specifies the service desk id the ticket is created in.
    .PARAMETER Summary
        Specifies the ticket summary/title.
    .PARAMETER Description
        Specifies the ticket description.
    .PARAMETER Category
        Specifies the ticket category by name (resolved to its Id) or by Id.
    .PARAMETER Status
        Specifies the ticket status by name (resolved to its Id) or by Id.
    .PARAMETER Priority
        Specifies the ticket priority (required) by name (e.g. 'High', resolved to its Id) or by Id.
    .PARAMETER Severity
        Specifies the ticket severity.
    .PARAMETER Assignee
        Specifies the assignee.
    .PARAMETER Creator
        Specifies the creator.
    .PARAMETER SubmitterName
        Specifies the submitter name.
    .PARAMETER SubmitterEmail
        Specifies the submitter email.
    .PARAMETER Attributes
        Specifies additional attributes (hashtable/pscustomobject).
    .EXAMPLE
       New-VSASDTicket -ServiceDeskId 100 -Summary 'Printer down' -Description 'The 3rd-floor printer is offline' -Priority 'High'
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       The created ticket (or its id).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/automation/servicedesktickets/{0}/ticket',

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" } return $true })]
        [string] $ServiceDeskId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Summary,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Description,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Category,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Status,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Priority,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Severity,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Assignee,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Creator,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $SubmitterName,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $SubmitterEmail,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [object] $Attributes
    )
    process {
        $URISuffix = $URISuffix -f $ServiceDeskId
        $connSplat = @{}; if ($VSAConnection) { $connSplat['VSAConnection'] = $VSAConnection }

        # The create endpoint keys Priority/Category/Status by their numeric Id (it int-parses the
        # value, so a name yields an HTTP 500 'Input string was not in a correct format'). Names are
        # far friendlier, so resolve a supplied name to its Id at runtime via the matching Get-VSASD*
        # cmdlet -- reusing the module's established name->Id resolution pattern. A numeric value is
        # assumed to already be an Id and passes through untouched.
        # (The resolved Id is written back into $PSBoundParameters, which is what builds the body below.)
        if ($PSBoundParameters.ContainsKey('Priority') -and $Priority -notmatch '^\d+$') {
            $all = @(Get-VSASDPriority @connSplat -Id $ServiceDeskId)
            $m = $all | Where-Object { $_.PriorityName -eq $Priority } | Select-Object -First 1
            if (-not $m) { throw "No priority named '$Priority' in service desk $ServiceDeskId. Available: $(($all.PriorityName) -join ', ')" }
            $PSBoundParameters['Priority'] = $m.PriorityId
        }
        if ($PSBoundParameters.ContainsKey('Category') -and $Category -notmatch '^\d+$') {
            $all = @(Get-VSASDCategory @connSplat -Id $ServiceDeskId)
            $m = $all | Where-Object { $_.CategoryName -eq $Category } | Select-Object -First 1
            if (-not $m) { throw "No category named '$Category' in service desk $ServiceDeskId. Available: $(($all.CategoryName | Select-Object -Unique) -join ', ')" }
            $PSBoundParameters['Category'] = $m.CategoryId
        }
        if ($PSBoundParameters.ContainsKey('Status') -and $Status -notmatch '^\d+$') {
            $all = @(Get-VSASDTicketStatus @connSplat -Id $ServiceDeskId)
            $m = $all | Where-Object { $_.StatusName -eq $Status } | Select-Object -First 1
            if (-not $m) { throw "No status named '$Status' in service desk $ServiceDeskId. Available: $(($all.StatusName) -join ', ')" }
            $PSBoundParameters['Status'] = $m.StatusId
        }

        [hashtable] $BodyHT = ConvertTo-VSARequestBody -BoundParameters $PSBoundParameters `
            -Include @('Summary', 'Description', 'Category', 'Status', 'Priority', 'Severity', 'Assignee', 'Creator', 'SubmitterName', 'SubmitterEmail')
        if ($null -ne $Attributes) { $BodyHT['Attributes'] = ConvertTo-VSAHashtable $Attributes }
        return Invoke-VSAWriteRequest -Body $BodyHT -Method POST -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function New-VSASDTicket
