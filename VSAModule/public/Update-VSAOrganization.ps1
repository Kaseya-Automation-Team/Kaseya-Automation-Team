function Update-VSAOrganization {
    <#
    .Synopsis
       Updates an existing organization.
    .DESCRIPTION
       Updates an existing organization.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER OrganizationName
        Specifies full organization name. Aliased as -OrgName, which is both the name
        New-VSAOrganization uses and the API's own field name, so the create/update pair can be
        driven with one spelling.
    .PARAMETER OrgRef
        Specifies string to reference the organization.
    .PARAMETER DefaultDepartmentName
        Specifies Default Department Name.
    .PARAMETER DefaultMachineGroupName
        Specifies Default Machine Group Name.
    .PARAMETER OrgType
        Specifies Organization Type.
    .PARAMETER ParentOrgId
        Specifies Numeric Id of existing organization that is set as the parent for the modofied one.
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
    .PARAMETER Attributes
        Specifies additional attributes to send in the request body.
    .PARAMETER OrgId
        Specifies the Id of the organization to update.
    .PARAMETER Website
        Specifies the organization's website.
    .PARAMETER NoOfEmployees
        Specifies the number of employees. Aliased as -NumberOfEmployees.
    .PARAMETER AnnualRevenue
        Specifies the organization's annual revenue.
    .PARAMETER FieldName
        Specifies the name of a custom field to set on the organization.
    .PARAMETER FieldValue
        Specifies the value for the custom field named by -FieldName.
    .EXAMPLE
       Update-VSAOrganization -OrgId 10001 -NumberOfEmployees 12
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if creation was successful
    #>
   [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/system/orgs/{0}',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $OrgId,

        # -OrgName is the spelling New-VSAOrganization uses and the API's own body field name (see
        # the OrgName key built below); the create/update pair otherwise disagreed on what to call
        # the same value.
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage = "Unique string to reference the organization. Usually shorten name or acronim.")]
        [string] $OrgRef,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $DefaultDepartmentName,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $DefaultMachineGroupName,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $OrgType,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $ParentOrgId,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $Website,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [Alias('NumberOfEmployees')]
        [string] $NoOfEmployees,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric value: $_"
            }
            return $true
        })]
        [string] $AnnualRevenue,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $PreferredContactMethod,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $PrimaryPhone,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $PrimaryFax,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $PrimaryEmail,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $Country,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Street,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $City,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $State,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $ZipCode,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $PrimaryTextMessagePhone,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $FieldName,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $FieldValue,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        # Accepts a [hashtable]/[pscustomobject] (preferred) or the legacy "Key=value" string.
        [object] $Attributes
        )
    process {

    [hashtable]$BodyHT = @{}
    if ( -not [string]::IsNullOrEmpty($OrganizationName) )        { $BodyHT.Add('OrgName', $OrganizationName) }
    if ( -not [string]::IsNullOrEmpty($OrgRef) )                  { $BodyHT.Add('OrgRef', $OrgRef) }
    if ( -not [string]::IsNullOrEmpty($DefaultDepartmentName) )   { $BodyHT.Add('DefaultDepartmentName', $DefaultDepartmentName) }
    if ( -not [string]::IsNullOrEmpty($DefaultMachineGroupName) ) { $BodyHT.Add('DefaultMachineGroupName', $DefaultMachineGroupName) }
    if ( -not [string]::IsNullOrEmpty($OrgType) )                 { $BodyHT.Add('OrgType', $OrgType) }
    # Send these as the string value the caller supplied, exactly as New-VSAOrganization does. A
    # [decimal] cast serialises an integer as "N.0" (e.g. 7 -> 7.0), and the server's org-update model
    # rejects that for ParentOrgId and NoOfEmployees with HTTP 400 (live-verified: string and integer
    # are accepted, "N.0" is not). ParentOrgId is a 26-digit id that also overflows every integer type,
    # so it must travel as a string regardless.
    if ( -not [string]::IsNullOrEmpty($ParentOrgId) )             { $BodyHT.Add('ParentOrgId', $ParentOrgId) }
    if ( -not [string]::IsNullOrEmpty($Website) )                 { $BodyHT.Add('Website', $Website) }
    if ( -not [string]::IsNullOrEmpty($NoOfEmployees) )           { $BodyHT.Add('NoOfEmployees', $NoOfEmployees) }
    if ( -not [string]::IsNullOrEmpty($AnnualRevenue) )           { $BodyHT.Add('AnnualRevenue', $AnnualRevenue) }

    [hashtable]$ContactInfoHT = @{}
    if ( -not [string]::IsNullOrEmpty($PreferredContactMethod) )  { $ContactInfoHT.Add('PreferredContactMethod', $PreferredContactMethod)}
    if ( -not [string]::IsNullOrEmpty($PrimaryPhone) )            { $ContactInfoHT.Add('PrimaryPhone', $PrimaryPhone)}
    if ( -not [string]::IsNullOrEmpty($PrimaryFax) )              { $ContactInfoHT.Add('PrimaryFax', $PrimaryFax)}
    if ( -not [string]::IsNullOrEmpty($PrimaryEmail) )            { $ContactInfoHT.Add('PrimaryEmail', $PrimaryEmail)}
    if ( -not [string]::IsNullOrEmpty($Country) )                 { $ContactInfoHT.Add('Country', $Country)}
    if ( -not [string]::IsNullOrEmpty($Street) )                  { $ContactInfoHT.Add('Street', $Street)}
    if ( -not [string]::IsNullOrEmpty($City) )                    { $ContactInfoHT.Add('City', $City)}
    if ( -not [string]::IsNullOrEmpty($State) )                   { $ContactInfoHT.Add('State', $State)}
    if ( -not [string]::IsNullOrEmpty($ZipCode) )                 { $ContactInfoHT.Add('ZipCode', $ZipCode)}
    if ( -not [string]::IsNullOrEmpty($PrimaryTextMessagePhone) ) { $ContactInfoHT.Add('PrimaryTextMessagePhone', $PrimaryTextMessagePhone)}

    if ( 0 -lt $ContactInfoHT.Count)
    {
        $BodyHT.Add('ContactInfo', $ContactInfoHT )
    }

    if ( ( -not [string]::IsNullOrWhiteSpace($FieldName)) -and ( -not [string]::IsNullOrWhiteSpace($FieldValue)) )
    {
        $BodyHT.Add('CustomFields', @(@{ FieldName  = $FieldName; FieldValue = $FieldValue }) )
    }

    if ( $null -ne $Attributes ) {
        [hashtable] $AttributesHT = ConvertTo-VSAHashtable $Attributes
        if ( 0 -lt $AttributesHT.Count ) { $BodyHT.Add('Attributes', $AttributesHT ) }
    }

    if ( 0 -eq $BodyHT.Count ) {
        throw "No changes specified!"
    }

    if($PSCmdlet.ShouldProcess($OrgId)){
        return Invoke-VSAWriteRequest -Body $BodyHT -Method PUT -URISuffix ($URISuffix -f $OrgId) -VSAConnection $VSAConnection
    }
    }
}
Export-ModuleMember -Function Update-VSAOrganization