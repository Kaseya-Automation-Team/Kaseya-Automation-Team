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
        Specifies full organization name.
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

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
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

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
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
        [string[]] $CustomFields = @(),

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Attributes
        )

    $URISuffix = $URISuffix -f $OrgId
    $URISuffix | Write-Verbose
    $URISuffix | Write-Debug

    [hashtable]$BodyHT = @{}
    if ( -not [string]::IsNullOrEmpty($OrganizationName) )        { $BodyHT.Add('OrgName', $OrganizationName) }
    if ( -not [string]::IsNullOrEmpty($OrgRef) )                  { $BodyHT.Add('OrgRef', $OrgRef) }
    if ( -not [string]::IsNullOrEmpty($DefaultDepartmentName) )   { $BodyHT.Add('DefaultDepartmentName', $DefaultDepartmentName) }
    if ( -not [string]::IsNullOrEmpty($DefaultMachineGroupName) ) { $BodyHT.Add('DefaultMachineGroupName', $DefaultMachineGroupName) }
    if ( -not [string]::IsNullOrEmpty($OrgType) )                 { $BodyHT.Add('OrgType', $OrgType) }
    if ( -not [string]::IsNullOrEmpty($ParentOrgId) )             { $BodyHT.Add('ParentOrgId', [decimal]$ParentOrgId) }
    if ( -not [string]::IsNullOrEmpty($Website) )                 { $BodyHT.Add('Website', $Website) }
    if ( -not [string]::IsNullOrEmpty($NoOfEmployees) )           { $BodyHT.Add('NoOfEmployees', [decimal]$NoOfEmployees) }
    if ( -not [string]::IsNullOrEmpty($AnnualRevenue) )           { $BodyHT.Add('AnnualRevenue', [decimal]$AnnualRevenue) }

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

    if ( -not [string]::IsNullOrEmpty($Attributes) ) {
        [hashtable] $AttributesHT = ConvertFrom-StringData -StringData $Attributes
        $BodyHT.Add('Attributes', $AttributesHT )
    }
   
    $Body = $BodyHT | ConvertTo-Json

    $Body | Out-String | Write-Debug
    $Body | Out-String | Write-Verbose

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    $Params.Add('Method', 'PUT')
    $Params.Add('Body', $Body)

    $Params | Out-String | Write-Debug

    if($PSCmdlet.ShouldProcess($OrgId)){
        return Update-VSAItems @Params
    }
}
Export-ModuleMember -Function Update-VSAOrganization