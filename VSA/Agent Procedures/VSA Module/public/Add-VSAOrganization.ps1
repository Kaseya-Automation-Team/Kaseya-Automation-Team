function Add-VSAOrganization {
    <#
    .Synopsis
       Creates a new organization.
    .DESCRIPTION
       Creates a new organization.
    .EXAMPLE
       Add-VSAOrganization
    .EXAMPLE
       Add-VSAOrganization
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
        [string] $OrgName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
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
        [ValidateNotNullOrEmpty()]
        [string] $OrgId,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $FieldName,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateSet("string", "number", "datetime", "date", "time")]
        [string]$FieldType = 'string'
        )

        # region generate OrgId if not provided
        if( [string]::IsNullOrEmpty($OrgId) ) {
            
            $orgs = Get-VSAOrganization
            [int]$Length = ($orgs | Select-Object -First 1 | Select-Object -ExpandProperty OrgId).Length

            do {
                do {
                    [string]$RandomId += $((10..99) | Get-Random).ToString()
    
                } while ($RandomId.length -lt $Length)

                $RandomId.Substring(0, $Length)
            } while ($RandomId -in $orgs.OrgId)
            $OrgId = $RandomId
        }
        # endregion generate OrgId if not provided
    
    [bool]$result = $false

    [hashtable]$BodyHT = @{
            OrgName                 = $OrgName
            OrgId                   = $OrgId
            OrgRef                  = $OrgRef
            DefaultDepartmentName   = $DefaultDepartmentName
            DefaultMachineGroupName = $DefaultMachineGroupName
        }
   
    $Body = $BodyHT | ConvertTo-Json

    $Body

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    $Params.Add('Method', 'POST')
    $Params.Add('Body', $Body)
    
    $result = Update-VSAItems @Params

    <#
    #[string[]]$ExistingFields = Get-VSACustomFields -Filter "FieldName eq `'$FieldName`'"
    [string[]]$ExistingFields = Get-VSACustomFields @Params | Select-Object -ExpandProperty FieldName 
    
    If ($FieldName -notin $ExistingFields) {
        
        $Params.Add('URISuffix', $URISuffix)
        $Params.Add('Method', 'POST')
        $Params.Add('Body', $Body)
        
        $result = Update-VSAItems @Params
    } else {
        $Message = "The custom field `'$FieldName`' already exists"
        Log-Event -Msg $Message -Id 4000 -Type "Error"
        throw $Message
    }
    #>

    return $result

    #Get-RequestData @requestParameters
}
Export-ModuleMember -Function Add-VSAOrganization