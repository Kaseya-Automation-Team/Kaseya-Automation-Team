function Add-VSAAgentInstallPkg
{
    <#
    .Synopsis
       Add agents install package
    .DESCRIPTION
       Adds an agent install package record.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER PackageId
        Specifies numeric id of package (not required)
    .PARAMETER MachineGroupId
        Specifies machine group which install package belongs to
    .PARAMETER CopySettingsFromAgentId
        Specifies id of agent machine to copy settings from
    .PARAMETER AgentType
        Specifies OS type for install package
    .PARAMETER CommandLineSwitches
        Specifies command line switches for install package
    .PARAMETER PackageName
        Specifies name of package
    .PARAMETER PackageDescription
        Specifies description of package
    .EXAMPLE
       Add-VSAAgentInstallPkg -MachineGroupId 23434 -CopySettingsFromAgentId 342432324 -AgentType null -PackageName "New package" -PackageDescription "Package for linux computers" 
    .EXAMPLE
       Add-VSAAgentInstallPkg -VSAConnection $VSAConnection -MachineGroupId 23434 -CopySettingsFromAgentId 342432324 -AgentType null -PackageName "New package" -PackageDescription "Package for linux computers" 
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NonPersistent')]
        [VSAConnection] $VSAConnection,
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/assetmgmt/assets/packages",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $PackageId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $MachineGroupId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $CopySettingsFromAgentId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [ValidateSet("auto", "windows", "mac", "null")]
        [string] $AgentType,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $CommandLineSwitches = "/e",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $PackageName,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $PackageDescription
)
	
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
    }

    $BodyHT = @{"MachineGroupId"="$MachineGroupId"; "AgentType"="$AgentType"; "PackageName"="$PackageName"; "PackageDescription"="$PackageDescription"}

    if ( -not [string]::IsNullOrEmpty($PackageId) )                 { $BodyHT.Add('PackageId', $PackageId) }
    if ( -not [string]::IsNullOrEmpty($CopySettingsFromAgentId) )   { $BodyHT.Add('CopySettingsFromAgentId', $CopySettingsFromAgentId) }
    if ( -not [string]::IsNullOrEmpty($CommandLineSwitches) )       { $BodyHT.Add('CommandLineSwitches', $CommandLineSwitches) }

    $Body = $BodyHT | ConvertTo-Json
	
    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Add-VSAAgentInstallPkg