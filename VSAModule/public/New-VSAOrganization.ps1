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
        Version 0.2
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
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
        [string] $ContactInfo,

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
        [string[]] $CustomFields = @(),

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $Attributes,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [switch] $ExtendedOutput
        )

    # Convert the string representation of the function arguments into a hashtable
    [hashtable]$BodyHT = ($(Get-PSCallStack)[0].Arguments).Trim('{}') -replace ',', "`n" | ConvertFrom-StringData

    [string[]]$OrganizationFields = @('OrgId', 'OrgName', 'OrgRef', 'DefaultDepartmentName', 'DefaultMachineGroupName', 'OrgType', 'ParentOrgId', 'Website', 'NoOfEmployees', 'AnnualRevenue', 'ContactInfo', 'FieldName', 'FieldValue', 'CustomFields', 'Attributes')
    [string[]]$ContactInfoFields = @('PreferredContactMethod', 'PrimaryPhone', 'PrimaryFax', 'PrimaryEmail', 'Country', 'Street', 'City', 'State', 'ZipCode', 'PrimaryTextMessagePhone')
    [string[]]$AllFields = $OrganizationFields + $ContactInfoFields 

    foreach ( $key in $BodyHT.Keys.Clone() ) {
        if ( $key -notin $AllFields )  { $BodyHT.Remove($key) }
    }

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

    # Process Contact Info
    [hashtable] $ContactInfoHT = @{}
    # Check if ContactInfo object is present
    if ( -not [string]::IsNullOrEmpty($ContactInfo) ) {
        $BodyHT.Remove('ContactInfo')
        # Convert string literal to hashtable
        $ContactInfo -match '{(.*?)\}' | Out-Null
        $ContactInfoHT = ConvertFrom-StringData -StringData $($Matches[1] -replace '= ','=' -replace '; ',';' -split ';' -join "`n")
    } else {
        # Process Contact Info fields
        foreach ($Field in $ContactInfoFields) {
            if ($BodyHT.ContainsKey($Field)) {
                $ContactInfoHT.Add( $Field, $($BodyHT.Get_Item($Field)) )
                $BodyHT.Remove($Field)
            } 
        }
    }
    #Remove empty keys
    foreach ( $key in $ContactInfoHT.Keys.Clone() ) {
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
            $CustomField -match '{(.*?)\}' | Out-Null
            [hashtable]$FieldHT = ConvertFrom-StringData -StringData $($Matches[1] -replace '= ','=' -replace '; ',';' -split ';' -join "`n")
            $CFArrayList.AddRange($FieldHT)
        }
    }
    if ( ( -not [string]::IsNullOrWhiteSpace($FieldName)) -and ( -not [string]::IsNullOrWhiteSpace($FieldValue)) )
    {
        [hashtable]$FieldHT = @{ FieldName = $FieldName; FieldValue = $FieldValue }
        $CFArrayList.Add($FieldHT)
    }
    $BodyHT.Remove('CustomFields')
    if ( 0 -lt $CFArrayList.Count )  {
        $BodyHT.Add('CustomFields', $($CFArrayList.ToArray()) )
    }
    #endregion Process Custom Fields

    #region Process Attributes
    if ( -not [string]::IsNullOrEmpty($Attributes) ) {
        $Attributes -match '{(.*?)\}' | Out-Null
        [hashtable] $AttributesHT = ConvertFrom-StringData -StringData $($Matches[1] -replace '= ','=' -replace '; ',';' -split ';' -join "`n")
        $BodyHT.Remove('Attributes')
        if ( 0 -lt $AttributesHT.Count )  {
            $BodyHT.Add('Attributes', $AttributesHT )
        }
    }
    #endregion Process Attributes

    #Check if the Parent Organization exists
    if ( -not [string]::IsNullOrEmpty($ParentOrgId) ) {

        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug "New-VSAOrganization. Check if the Parent Organization exists"
        }

        $ParentOrg = try { Get-VSAOrganization -VSAConnection $VSAConnection -OrgID $ParentOrgId } catch {$null}

        if ( [string]::IsNullOrEmpty($ParentOrg) ) {
            Write-Warning "Could not find the Parent Organization by the ParentOrgId provided '$ParentOrgId' for '$OrgName'."
        }
    } else {
        $BodyHT.Remove("ParentOrgId")
    }

    #Remove empty keys
    foreach ( $key in $BodyHT.Keys.Clone() ) {
        if ( -not $BodyHT[$key] )  { $BodyHT.Remove($key) }
    }

    # Convert Body hashtable to JSON
    [string]$Body = $BodyHT | ConvertTo-Json

    # Debug output for Body
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "New-VSAOrganization. Request Body: $Body" | Write-Debug
    }

    [hashtable]$Params = @{
        URISuffix      = $URISuffix
        Method         = 'POST'
        Body           = $( $BodyHT | ConvertTo-Json -Depth 5 -Compress )
        ExtendedOutput = $ExtendedOutput
    }

    if ($VSAConnection) { $Params.VSAConnection = $VSAConnection }


    # Debug output for Invoke-VSARestMethod parameters
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "New-VSAOrganization. $($Params | Out-String)" | Write-Debug
    }

    # Invoke the REST method and get the result
    $Result = Invoke-VSARestMethod @Params

    # If ExtendedOutput is specified, return the Result property, otherwise return the entire result
    if ($ExtendedOutput) { $Result = $Result | Select-Object -ExpandProperty Result }
    return $Result
}
New-Alias -Name Add-VSAOrganization -Value New-VSAOrganization
New-Alias -Name New-VSAOrg -Value New-VSAOrganization
Export-ModuleMember -Function New-VSAMachineGroup -Alias Add-VSAOrganization, New-VSAOrg