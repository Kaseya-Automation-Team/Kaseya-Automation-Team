function Update-VSAStaff
{
    <#
    .Synopsis
       Updates a staff record.
    .DESCRIPTION
       Updates a staff record.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER DepartmentId
        Specifies the Department Id to which a staff item is added.
    .PARAMETER OrgIdNumber
        Specifies the Organization Id to which a staff item is added.
    .PARAMETER StaffFullName
        Specifies Staff Full Name.
    .PARAMETER SupervisorId
        Specifies Staff Id of Supervisor.
    .PARAMETER Title
        Specifies Job title.
    .PARAMETER Function
        Specifies Job Function.
    .PARAMETER UserId
        Specifies the User Id.
    .PARAMETER ViewAllTickets
        Specifies ability to view all tickets.
    .PARAMETER ApproveAllTimeSheets
        Specifies ability to approve all time sheets.
    .PARAMETER PreferredContactMethod
        Specifies the preferred contact method.
    .PARAMETER PrimaryPhone
        Specifies the primary phone number.
    .PARAMETER PrimaryFax
        Specifies the primary fax number.
    .PARAMETER PrimaryEmail
        Specifies the primary email address.
    .PARAMETER Country
        Specifies the country of the postal address.
    .PARAMETER Street
        Specifies the street of the postal address.
    .PARAMETER City
        Specifies the city of the postal address.
    .PARAMETER State
        Specifies the state or region of the postal address.
    .PARAMETER ZipCode
        Specifies the postal code of the postal address.
    .PARAMETER PrimaryTextMessagePhone
        Specifies the phone number used for text messages.
    .PARAMETER OrgStaffId
        Specifies the Id of the staff record to update.
    .EXAMPLE
       Update-VSAStaff -OrgStaffId 10001 -OrgIdNumber 20002 -StaffFullName 'John Doe'
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if addition was successful.
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
        [string] $URISuffix = 'api/v1.0/system/staff/{0}',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $OrgStaffId,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $DepartmentId,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $OrgIdNumber,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $StaffFullName,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $SupervisorId,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Title,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Function = '',

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $UserId,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $PreferredContactMethod,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $PrimaryPhone,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $PrimaryFax,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $PrimaryEmail,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Country,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Street,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $City,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $State,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ZipCode,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $PrimaryTextMessagePhone,

        [switch] $ViewAllTickets,

        [switch] $ApproveAllTimeSheets
    )
    process {

    # Build from bound parameters directly (F-52): a truthiness prune would silently drop
    # legitimate values like 0 or '' that a caller explicitly asked to send. The BodyHT keys
    # here don't all match the source parameter names (OrgId<-OrgIdNumber, DeptId<-DepartmentId),
    # so each field is keyed off its own source parameter's bound state.
    [hashtable]$BodyHT = @{}
    if ($PSBoundParameters.ContainsKey('OrgIdNumber'))   { $BodyHT['OrgId'] = $OrgIdNumber }

    # -Function must ALWAYS be on the wire, even when the caller did not supply it (F-69).
    # The backend stored procedure behind this endpoint (sp_EditOrgDeptStaff) takes this field as its
    # '@purpose' argument and rejects the entire update with HTTP 500 -- "expects parameter
    # '@purpose', which was not supplied" -- if the key is absent. The field was historically sent
    # unconditionally for exactly this reason; making it conditional (F-52, prune by bound state)
    # silently reintroduced the failure for every caller that did not pass -Function.
    # Sending an empty value instead would satisfy the server but WIPE the staff member's real job
    # function, so when the caller omits it the current value is read back and re-sent unchanged.
    if ($PSBoundParameters.ContainsKey('Function')) {
        $BodyHT['Function'] = $Function
    } else {
        [hashtable]$LookupParams = @{}
        if ($VSAConnection) { $LookupParams['VSAConnection'] = $VSAConnection }
        $CurrentFunction = Get-VSAStaff @LookupParams |
            Where-Object { "$($_.OrgStaffId)" -eq "$OrgStaffId" } |
            Select-Object -First 1 -ExpandProperty Function
        $BodyHT['Function'] = [string]$CurrentFunction
    }
    if ($PSBoundParameters.ContainsKey('StaffFullName')) { $BodyHT['StaffFullName'] = $StaffFullName }
    if ($PSBoundParameters.ContainsKey('DepartmentId'))  { $BodyHT['DeptId'] = $DepartmentId }
    if ($PSBoundParameters.ContainsKey('SupervisorId'))  { $BodyHT['SupervisorId'] = $SupervisorId }
    if ($PSBoundParameters.ContainsKey('Title'))         { $BodyHT['Title'] = $Title }
    if ($PSBoundParameters.ContainsKey('UserId'))        { $BodyHT['UserId'] = $UserId }
    if ($ViewAllTickets.IsPresent)       { $BodyHT.Add('ViewAllTickets', $ViewAllTickets.ToString().ToLower()) }
    if ($ApproveAllTimeSheets.IsPresent) { $BodyHT.Add('ApproveAllTimeSheets', $ApproveAllTimeSheets.ToString().ToLower() ) }

    [hashtable]$ContactInfoHT = @{
        PreferredContactMethod  = $PreferredContactMethod
        PrimaryPhone            = $PrimaryPhone
        PrimaryFax              = $PrimaryFax
        PrimaryEmail            = $PrimaryEmail
        Country                 = $Country
        Street                  = $Street
        City                    = $City
        State                   = $State
        ZipCode                 = $ZipCode
        PrimaryTextMessagePhone = $PrimaryTextMessagePhone
    }
    foreach ( $key in @($ContactInfoHT.Keys)  ) {
        if ( -not $PSBoundParameters.ContainsKey($key)) { $ContactInfoHT.Remove($key) }
    }

    if ( 0 -lt $ContactInfoHT.Count) {
        $BodyHT.Add('ContactInfo', $ContactInfoHT )
    }

    return Invoke-VSAWriteRequest -Body ($($BodyHT | ConvertTo-Json -Depth 5 -Compress)) -Method 'PUT' -URISuffix ($($URISuffix -f $OrgStaffId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Update-VSAStaff