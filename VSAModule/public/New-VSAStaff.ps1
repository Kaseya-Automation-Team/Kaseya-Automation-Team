function New-VSAStaff
{
    <#
    .Synopsis
       Adds a single staff record to a single department.
    .DESCRIPTION
       Adds a single staff record to a single department of organization.
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
       New-VSAStaff -DepartmentId 10001 -OrgIdNumber 20002 -StaffFullName 'John Doe'
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
        [string] $URISuffix = 'api/v1.0/system/departments/{0}/staff',

        [Parameter(Mandatory = $true, 
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
        [string] $Function,

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

    [hashtable]$BodyHT = @{
            StaffFullName        = $StaffFullName
            OrgId                = $OrgIdNumber
            ViewAllTickets       = $ViewAllTickets
            ApproveAllTimeSheets = $ApproveAllTimeSheets
            SupervisorId         = $SupervisorId
            Title                = $Title
            Function             = $Function
            UserId               = $UserId
        }

    foreach ($key in $BodyHT.Keys.Clone()) {
        if ([string]::IsNullOrEmpty($BodyHT[$key])) {
            $BodyHT.Remove($key)
        }
    }

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

    foreach ($key in $ContactInfoHT.Keys.Clone()) {
        if ([string]::IsNullOrEmpty($ContactInfoHT[$key])) {
            $ContactInfoHT.Remove($key)
        }
    }

    if ( 0 -lt $ContactInfoHT.Count) {
        $BodyHT.Add('ContactInfo', $ContactInfoHT )
    }

    $Body = $BodyHT | ConvertTo-Json

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "New-VSAStaff. Body: $Body"
    }

    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $($URISuffix -f $DepartmentId)
        Method        = 'POST'
        Body          = $Body
    }

    foreach ($key in $Params.Keys.Clone()) {
        if ([string]::IsNullOrEmpty($Params[$key])) {
            $Params.Remove($key)
        }
    }

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "New-VSAStaff. $($Params | Out-String)"
    }

    return Invoke-VSARestMethod @Params
}
New-Alias -Name Add-VSAStaff -Value New-VSAStaff
Export-ModuleMember -Function New-VSAStaff -Alias Add-VSAStaff