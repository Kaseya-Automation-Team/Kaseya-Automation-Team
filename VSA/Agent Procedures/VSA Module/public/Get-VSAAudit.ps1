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
    [CmdletBinding(DefaultParameterSetName = 'Summaries')]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Summaries')]
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
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true, 
            ParameterSetName = 'Summaries')]
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
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/audit/{0}',

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Summaries')]
        [switch] $Summaries,

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

        [Parameter(Mandatory = $false, 
            ParameterSetName = 'Summaries')]
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
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [Parameter(Mandatory = $false, 
            ParameterSetName = 'Summaries')]
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
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [Parameter(Mandatory = $false, 
            ParameterSetName = 'Summaries')]
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
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )
    DynamicParam { 
            if ( -not $Summaries) {
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

        if ($Credentials) {$URISuffix = "$URISuffix/credentials"}
        if ($Groups)      {$URISuffix = "$URISuffix/groups"}
        if ($DiskVolumes) {$URISuffix = "$URISuffix/diskvolumes"}
        if ($PCIAndDisk)  {$URISuffix = "$URISuffix/pcianddisk"}
        if ($Printers)    {$URISuffix = "$URISuffix/printers"}

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