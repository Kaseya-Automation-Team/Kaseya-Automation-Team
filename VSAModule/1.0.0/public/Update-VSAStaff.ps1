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

        [parameter(DontShow, Mandatory=$false,
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

    [hashtable]$BodyHT = @{
        OrgId         = $OrgIdNumber
        Function      = $Function
        StaffFullName = $StaffFullName
        DeptId        = $DepartmentId
        SupervisorId  = $SupervisorId
        Title         = $Title
        UserId        = $UserId
    } # Function = $Function ---> workaround for backend bug
    foreach ( $key in $BodyHT.Keys.Clone()  ) {
        if ( -not $BodyHT[$key]) { $BodyHT.Remove($key) }
    }
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
    foreach ( $key in $ContactInfoHT.Keys.Clone()  ) {
        if ( -not $ContactInfoHT[$key]) { $ContactInfoHT.Remove($key) }
    }

    if ( 0 -lt $ContactInfoHT.Count) {
        $BodyHT.Add('ContactInfo', $ContactInfoHT )
    }

    [hashtable]$Params = @{
        URISuffix = $($URISuffix -f $OrgStaffId)
        Method    = 'PUT'
        Body      = $($BodyHT | ConvertTo-Json -Depth 5 -Compress)
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}
Export-ModuleMember -Function Update-VSAStaff