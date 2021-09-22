function Add-VSAOrganization {
    <#
    .Synopsis
       Creates a new organization.
    .DESCRIPTION
       Creates a new organization.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER OrganizationName
        Specifies full organization name.
    .PARAMETER OrganizationId
        Specifies string to reference the organization. Must be unique. Usually shorten name or acronim.
    .PARAMETER DefaultDepartmentName
        Specifies Default Department Name. root by default.
    .PARAMETER DefaultMachineGroupName
        Specifies Default Machine Group Name. root by default.
    .PARAMETER OrgType
        Specifies Organization Type.
    .PARAMETER ParentOrgId
        Specifies Numeric Id of existing organization that is set as the parent for the new one.
    .EXAMPLE
       Add-VSAOrganization -OrganizationName 'My Organization' -OrganizationId 'myorg'
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if creation was successful
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/system/orgs',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage = "Unique string to reference the organization. Usually shorten name or acronim.")]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationId,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DefaultDepartmentName = 'root',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DefaultMachineGroupName = 'root',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $OrgType,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $ParentOrgId,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Website,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $NumberOfEmployees,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $AnnualRevenue,

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
        [string] $FieldName,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $FieldValue
        )

    [string]$OrgIdNumber = $((100..999) | Get-Random).ToString()

    [hashtable]$BodyHT = @{
            OrgName                 = $OrganizationName
            OrgRef                  = $OrganizationId
            OrgId                   = $OrgIdNumber
            DefaultDepartmentName   = $DefaultDepartmentName
            DefaultMachineGroupName = $DefaultMachineGroupName
        }

    if ($OrgType)           { $BodyHT.Add('OrgType', $OrgType) }
    if ($ParentOrgId)       { $BodyHT.Add('ParentOrgId', $ParentOrgId) }
    if ($Website)           { $BodyHT.Add('Website', $Website) }
    if ($NumberOfEmployees) { $BodyHT.Add('NoOfEmployees', $NumberOfEmployees) }
    if ($AnnualRevenue) { $BodyHT.Add('AnnualRevenue', $AnnualRevenue) }

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
    
    if ( 0 -lt $ContactInfoHT.Count)
    {
        $BodyHT.Add('ContactInfo', $ContactInfoHT )
    }

    if (  ( -not [string]::IsNullOrWhiteSpace($FieldName)) -and ( -not [string]::IsNullOrWhiteSpace($FieldValue)) )
    {
        $BodyHT.Add('CustomFields', @(@{ FieldName  = $FieldName; FieldValue = $FieldValue }) )
    }
   
    $Body = $BodyHT | ConvertTo-Json

    $Body | Out-String | Write-Debug

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    $Params.Add('Method', 'POST')
    $Params.Add('Body', $Body)

    $Params | Out-String | Write-Debug

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Add-VSAOrganization