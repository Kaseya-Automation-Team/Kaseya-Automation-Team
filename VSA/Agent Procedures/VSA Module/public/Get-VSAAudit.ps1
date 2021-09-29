function Get-VSAAudit
{
    <#
    .Synopsis
       Returns VSA audit summary.
    .DESCRIPTION
       Returns VSA audit summary.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSAAudit
    .EXAMPLE
       Get-VSAAudit -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent VSA audit summary.
    #>
    [CmdletBinding(DefaultParameterSetName = 'AllSummaries')]
    param ( 
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'AllSummaries')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Credentials')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Groups')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'DiskVolumes')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'PCIAndDisk')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Printers')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'PurchaseAndWarrantyExpire')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'LocalGroupMembers')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ProgamList')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'InstalledApps')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Licenses')]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'AllSummaries')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Credentials')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Groups')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'DiskVolumes')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'PCIAndDisk')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Printers')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'PurchaseAndWarrantyExpire')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'LocalGroupMembers')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ProgamList')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'InstalledApps')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Licenses')]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/audit/{0}',

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'AllSummaries')]
        [switch] $AllSummaries,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Credentials')]
        [switch] $Credentials,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Groups')]
        [switch] $Groups,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'DiskVolumes')]
        [switch] $DiskVolumes,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'PCIAndDisk')]
        [switch] $PCIAndDisk,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Printers')]
        [switch] $Printers,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'PurchaseAndWarrantyExpire')]
        [switch] $PurchaseAndWarrantyExpire,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'LocalGroupMembers')]
        [switch] $LocalGroupMembers,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ProgamList')]
        [switch] $AddRemoveProgramsList,
        
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'InstalledApps')]
        [switch] $InstalledApps,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Licenses')]
        [switch] $Licenses,

        [Parameter(Mandatory = $false, 
            ParameterSetName = 'AllSummaries')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'Credentials')]
        [parameter(Mandatory = $false, 
            ParameterSetName = 'Groups')]
        [parameter(Mandatory = $false, 
            ParameterSetName = 'DiskVolumes')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'PCIAndDisk')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'Printers')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'PurchaseAndWarrantyExpire')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'LocalGroupMembers')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'ProgamList')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'InstalledApps')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'Licenses')]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [Parameter(Mandatory = $false, 
            ParameterSetName = 'AllSummaries')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'Credentials')]
        [parameter(Mandatory = $false, 
            ParameterSetName = 'Groups')]
        [parameter(Mandatory = $false, 
            ParameterSetName = 'DiskVolumes')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'PCIAndDisk')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'Printers')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'PurchaseAndWarrantyExpire')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'LocalGroupMembers')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'ProgamList')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'InstalledApps')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'Licenses')]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [Parameter(Mandatory = $false, 
            ParameterSetName = 'AllSummaries')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'Credentials')]
        [parameter(Mandatory = $false, 
            ParameterSetName = 'Groups')]
        [parameter(Mandatory = $false, 
            ParameterSetName = 'DiskVolumes')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'PCIAndDisk')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'Printers')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'PurchaseAndWarrantyExpire')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'LocalGroupMembers')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'ProgamList')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'InstalledApps')]
        [Parameter(Mandatory = $false, 
            ParameterSetName = 'Licenses')]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )
     DynamicParam {
            if ( $($PSCmdlet.ParameterSetName) -notmatch 'AllSummaries' ) {
                $attribute = New-Object System.Management.Automation.ParameterAttribute 
                $attribute.ParameterSetName = "__AllParameterSets" 
                $attribute.Mandatory = $true 
 
                $collection = New-Object System.Collections.ObjectModel.Collection[System.Attribute] 
                $collection.Add($attribute) 
 
                $param = New-Object System.Management.Automation.RuntimeDefinedParameter('AgentID', [string], $collection) 
                $dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary 
                $dictionary.Add('AgentID', $param) 
                return $dictionary
            }
        }
    Begin {
        if ( $($PSBoundParameters.AgentID) -and ($($PSBoundParameters.AgentID)  -notmatch "^\d+$")) {
            Write-Error "AgentID must be a numeric value!" -ErrorAction Stop
        }
    }

    Process {

        [string] $AgentID = $PSBoundParameters.AgentID

        if ( [string]::IsNullOrEmpty($AgentID) ) {$AgentID = ''}
        $URISuffix = $URISuffix -f $AgentID

        if ($Credentials)               {$URISuffix = "$URISuffix/credentials"}
        if ($Groups)                    {$URISuffix = "$URISuffix/groups"}
        if ($DiskVolumes)               {$URISuffix = "$URISuffix/hardware/diskvolumes"}
        if ($PCIAndDisk)                {$URISuffix = "$URISuffix/hardware/pcianddisk"}
        if ($Printers)                  {$URISuffix = "$URISuffix/hardware/printers"}
        if ($PurchaseAndWarrantyExpire) {$URISuffix = "$URISuffix/hardware/purchaseandwarrantyexpire"}
        if ($LocalGroupMembers)         {$URISuffix = "$URISuffix/members"}
        if ($LocalGroupMembers)         {$URISuffix = "$URISuffix/members"}
        if ($AddRemoveProgramsList)     {$URISuffix = "$URISuffix/software/addremoveprograms"}
        if ($InstalledApps)             {$URISuffix = "$URISuffix/software/installedapplications"}
        if ($Licenses)                  {$URISuffix = "$URISuffix/software/licenses"}

        [hashtable]$Params = @{
            URISuffix = $($URISuffix -f $AgentID)
        }

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
        if($Filter)        {$Params.Add('Filter', $Filter)}
        if($Paging)        {$Params.Add('Paging', $Paging)}
        if($Sort)          {$Params.Add('Sort', $Sort)}

        return Get-VSAItems @Params
    }
}
Export-ModuleMember -Function Get-VSAAudit