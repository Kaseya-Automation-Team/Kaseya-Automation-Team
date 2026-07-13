function New-VSAOrganization {
    <#
    .Synopsis
       Creates a new organization.
    .DESCRIPTION
       Creates a new organization.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies the URI suffix if it differs from the default.
    .PARAMETER OrgId
        Specifies the numeric ID of the organization. A random ID is generated if not provided.
    .PARAMETER OrgName
        Specifies the full organization name.
    .PARAMETER OrgRef
        Specifies a unique string to reference the organization. Must be unique, usually a shortened name or acronym.
    .PARAMETER DefaultDepartmentName
        Specifies the Default Department Name. Default is 'root'.
    .PARAMETER DefaultMachineGroupName
        Specifies the Default Machine Group Name. Default is 'root'.
    .PARAMETER OrgType
        Specifies the Organization Type.
    .PARAMETER ParentOrgId
        Specifies the Numeric ID of an existing organization that is set as the parent for the new one.
    .PARAMETER Website
        Specifies the organization's website.
    .PARAMETER NoOfEmployees
        Specifies the number of employees.
    .PARAMETER AnnualRevenue
        Specifies the annual revenue.
    .PARAMETER ContactInfo
        Specifies a string representation of contact information object. If provided, individual contact fields are extracted.
    .PARAMETER PreferredContactMethod
        Specifies the preferred contact method.
    .PARAMETER PrimaryPhone
        Specifies the primary phone number.
    .PARAMETER PrimaryFax
        Specifies the primary fax number.
    .PARAMETER PrimaryEmail
        Specifies the primary email address.
    .PARAMETER Country
        Specifies the country.
    .PARAMETER Street
        Specifies the street address.
    .PARAMETER City
        Specifies the city.
    .PARAMETER State
        Specifies the state.
    .PARAMETER ZipCode
        Specifies the ZIP code.
    .PARAMETER PrimaryTextMessagePhone
        Specifies the primary phone number for text messages.
    .PARAMETER FieldName
        Specifies the name of a custom field.
    .PARAMETER FieldValue
        Specifies the value of a custom field.
    .PARAMETER CustomFields
        Specifies an array of custom fields as string representations. If provided, individual fields are extracted.
    .PARAMETER Attributes
        Specifies additional attributes in a string representation. Converted to a hashtable for processing.
    .PARAMETER ExtendedOutput
        Indicates whether to return extended output. If specified, returns the OrgId property of the newly created organization; otherwise, returns a boolean result if the operation was successful.
    .EXAMPLE
        New-VSAOrganization -VSAConnection $VSAConnection -OrgName 'My Organization' -OrgRef 'myorg'
    .INPUTS
        Accepts a piped Organization object.
    .OUTPUTS
        Returns True if the creation was successful; returns the OrgId property of the new Organization if the ExtendedOutput switch is specified.
    .NOTES
        Version 1.0.0
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/system/orgs',

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $OrgId,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage = "Specify name of the organization.")]
        [ValidateNotNullOrEmpty()]
        [string] $OrgName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage = "Unique string to reference the organization. Usually shorten name or acronim.")]
        [ValidateNotNullOrEmpty()]
        [string] $OrgRef,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $DefaultDepartmentName = 'root',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $DefaultMachineGroupName = 'root',

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
        [Alias('numEmployees', 'NumberOfEmployees')]
        [string] $NoOfEmployees,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d*\.?\d*$") ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $AnnualRevenue,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        # Accepts a [hashtable]/[pscustomobject] (preferred) or the legacy "{ Key= value; ... }"
        # string. When supplied, it takes precedence over the discrete contact parameters below.
        [object] $ContactInfo,

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
        [string] $PrimaryEmail,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $Country,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $Street,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $City,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $State,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $ZipCode,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $PrimaryTextMessagePhone,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $FieldName,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $FieldValue,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        # Each element accepts a [hashtable]/[pscustomobject] (preferred) or the legacy
        # "{ FieldName= ..; FieldValue= .. }" string.
        [object[]] $CustomFields = @(),

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        # Accepts a [hashtable]/[pscustomobject] (preferred) or the legacy "{ Key= value; ... }" string.
        [object] $Attributes,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [switch] $ExtendedOutput
        )
    process {

    # ContactInfo, CustomFields and Attributes are nested structures handled explicitly below via
    # ConvertTo-VSAHashtable, so they are intentionally NOT populated into the body from the raw
    # bound parameter here (F-39 kept them out of the naive copy for the same reason).
    [string[]]$OrganizationFields = @('OrgId', 'OrgName', 'OrgRef', 'DefaultDepartmentName', 'DefaultMachineGroupName', 'OrgType', 'ParentOrgId', 'Website', 'NoOfEmployees', 'AnnualRevenue', 'FieldName', 'FieldValue')
    [string[]]$ContactInfoFields = @('PreferredContactMethod', 'PrimaryPhone', 'PrimaryFax', 'PrimaryEmail', 'Country', 'Street', 'City', 'State', 'ZipCode', 'PrimaryTextMessagePhone')
    [string[]]$AllFields = $OrganizationFields + $ContactInfoFields

    # Build the request body from bound parameters. Values (including those containing commas,
    # ampersands, quotes, etc.) are preserved exactly, unlike the previous Get-PSCallStack string parsing (F-39).
    [hashtable]$BodyHT = ConvertTo-VSARequestBody -BoundParameters $PSBoundParameters -Include $AllFields

    # Add a random OrgId if it doesn't exist
    $OrgId = $((100..999) | Get-Random).ToString()
    if ( $BodyHT.ContainsKey('OrgId') ) {
        $BodyHT['OrgId'] = $OrgId
    } else {
        $BodyHT.Add('OrgId', $OrgId)
    }

    # Set default values for DefaultDepartmentName and DefaultMachineGroupName if not provided
    if ($BodyHT.ContainsKey('DefaultDepartmentName')) {
        if([string]::IsNullOrEmpty($DefaultDepartmentName)) {
            $BodyHT.DefaultDepartmentName = 'root'
        }
    } else {
        $BodyHT.Add('DefaultDepartmentName', 'root')
    }

    if ($BodyHT.ContainsKey('DefaultMachineGroupName')) {
        if([string]::IsNullOrEmpty($DefaultMachineGroupName)) {
            $BodyHT.DefaultMachineGroupName = 'root'
        }
    } else {
        $BodyHT.Add('DefaultMachineGroupName', 'root')
    }

    # Process Contact Info: a supplied -ContactInfo object (hashtable/pscustomobject/legacy string)
    # takes precedence; otherwise assemble it from the discrete contact parameters.
    [hashtable] $ContactInfoHT = @{}
    if ( $null -ne $ContactInfo ) {
        $ContactInfoHT = ConvertTo-VSAHashtable $ContactInfo
    }
    if ( 0 -eq $ContactInfoHT.Count ) {
        foreach ($Field in $ContactInfoFields) {
            if ($BodyHT.ContainsKey($Field)) {
                $ContactInfoHT[$Field] = $BodyHT[$Field]
            }
        }
    }
    # The discrete contact fields (and any raw ContactInfo) must never remain at the body top level.
    $BodyHT.Remove('ContactInfo')
    foreach ($Field in $ContactInfoFields) { $BodyHT.Remove($Field) }
    #Remove empty keys
    foreach ( $key in @($ContactInfoHT.Keys) ) {
        if ( -not $ContactInfoHT[$key] )  { $ContactInfoHT.Remove($key) }
    }

    # Add Contact Info hashtable to Body if it's not empty
    if (0 -lt $ContactInfoHT.Count) {
        $BodyHT.Add('ContactInfo', $ContactInfoHT)
    }

    #region Process Custom Fields
    $CFArrayList = New-Object System.Collections.ArrayList
    if ( 0 -lt $CustomFields.Count )
    {
        Foreach ( $CustomField in $CustomFields )
        {
            [hashtable]$FieldHT = ConvertTo-VSAHashtable $CustomField
            if ( 0 -lt $FieldHT.Count ) { [void]$CFArrayList.Add($FieldHT) }
        }
    }
    if ( ( -not [string]::IsNullOrWhiteSpace($FieldName)) -and ( -not [string]::IsNullOrWhiteSpace($FieldValue)) )
    {
        [hashtable]$FieldHT = @{ FieldName = $FieldName; FieldValue = $FieldValue }
        [void]$CFArrayList.Add($FieldHT)
    }
    $BodyHT.Remove('CustomFields')
    if ( 0 -lt $CFArrayList.Count )  {
        # Do NOT wrap ToArray() in a $(...) subexpression here: PowerShell unwraps a single-element
        # array to its bare scalar element when a subexpression's output is consumed as a single
        # argument value, so a lone custom field would serialize CustomFields as a bare {..} object
        # instead of a [{..}] array -- the VSA API then rejects the POST with a 400 (live-confirmed
        # against the sandbox: -CustomFields with exactly one field 400'd; two fields worked).
        $BodyHT.Add('CustomFields', $CFArrayList.ToArray())
    }
    #endregion Process Custom Fields

    #region Process Attributes
    $BodyHT.Remove('Attributes')
    if ( $null -ne $Attributes ) {
        [hashtable] $AttributesHT = ConvertTo-VSAHashtable $Attributes
        if ( 0 -lt $AttributesHT.Count )  {
            $BodyHT.Add('Attributes', $AttributesHT )
        }
    }
    #endregion Process Attributes

    #Check if the Parent Organization exists
    if ( -not [string]::IsNullOrEmpty($ParentOrgId) ) {

        Write-Debug "New-VSAOrganization. Check if the Parent Organization exists"

        $ParentOrg = try { Get-VSAOrganization -VSAConnection $VSAConnection -OrgID $ParentOrgId } catch {$null}

        if ( [string]::IsNullOrEmpty($ParentOrg) ) {
            Write-Warning "Could not find the Parent Organization by the ParentOrgId provided '$ParentOrgId' for '$OrgName'."
        }
    } else {
        $BodyHT.Remove("ParentOrgId")
    }

    return Invoke-VSAWriteRequest -Body $BodyHT -Method POST -URISuffix $URISuffix `
        -VSAConnection $VSAConnection -ExtendedOutput:$ExtendedOutput -Caller $PSCmdlet
    }
}
New-Alias -Name Add-VSAOrganization -Value New-VSAOrganization
New-Alias -Name New-VSAOrg -Value New-VSAOrganization
Export-ModuleMember -Function New-VSAOrganization -Alias Add-VSAOrganization, New-VSAOrg
