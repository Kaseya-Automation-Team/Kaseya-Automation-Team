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
    .EXAMPLE
       Update-VSAStaff -OrgStaffId 10001 -OrgIdNumber 20002 -StaffFullName 'John Doe'
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if addition was successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
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
        [ValidateNotNullOrEmpty()]
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

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ViewAllTickets = 'False',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ApproveAllTimeSheets = 'False'
    )

    [string] $ItemId

    $URISuffix = $URISuffix -f $OrgStaffId
    $URISuffix | Write-Verbose
    $URISuffix | Write-Debug

    [hashtable]$BodyHT = @{
            OrgId = $OrgIdNumber
            Function = $Function
        } # Function = $Function ---> workaround for backend bug

    if ($StaffFullName)        { $BodyHT.Add('StaffFullName', $StaffFullName) }
    if ($OrgId)                { $BodyHT.Add('OrgId', $OrgId) }
    if ($ViewAllTickets)       { $BodyHT.Add('ViewAllTickets', $ViewAllTickets) }
    if ($ApproveAllTimeSheets) { $BodyHT.Add('ApproveAllTimeSheets', $ApproveAllTimeSheets) }
    if ($DepartmentId)         { $BodyHT.Add('DeptId', $DepartmentId) }
    if ($SupervisorId)         { $BodyHT.Add('SupervisorId', $SupervisorId) }
    if ($Title)                { $BodyHT.Add('Title', $Title) }
    <#
    if ($Function)             { $BodyHT.Add('Function', $Function) }
    #>
    if ($UserId)               { $BodyHT.Add('UserId', $UserId) }

    [hashtable]$ContactInfoHT = @{}
    if ($PreferredContactMethod)  { $ContactInfoHT.Add('PreferredContactMethod', $PreferredContactMethod)}
    if ($PrimaryPhone)            { $ContactInfoHT.Add('PrimaryPhone', $PrimaryPhone)}
    if ($PrimaryFax)              { $ContactInfoHT.Add('PrimaryFax', $PrimaryFax)}
    if ($PrimaryEmail)            { $ContactInfoHT.Add('PrimaryEmail', $PrimaryEmail)}
    if ($Country)                 { $ContactInfoHT.Add('Country', $Country)}
    if ($Street)                  { $ContactInfoHT.Add('Street', $Street)}
    if ($City)                    { $ContactInfoHT.Add('City', $City)}
    if ($State)                   { $ContactInfoHT.Add('State', $State)}
    if ($ZipCode)                 { $ContactInfoHT.Add('ZipCode', $ZipCode)}
    if ($PrimaryTextMessagePhone) { $ContactInfoHT.Add('PrimaryTextMessagePhone', $PrimaryTextMessagePhone)}

    if ( 0 -lt $ContactInfoHT.Count) {
        $BodyHT.Add('ContactInfo', $ContactInfoHT )
    }

    $Body = $BodyHT | ConvertTo-Json

    $Body | Out-String | Write-Debug

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    $Params.Add('Method', 'PUT')
    $Params.Add('Body', $Body)

    $Params | Out-String | Write-Debug

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Update-VSAStaff