function New-VSAAgentInstallPkg
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
       New-VSAAgentInstallPkg -MachineGroupId 23434 -CopySettingsFromAgentId 342432324 -AgentType null -PackageName "New package" -PackageDescription "Package for linux computers" 
    .EXAMPLE
       New-VSAAgentInstallPkg -VSAConnection $VSAConnection -MachineGroupId 23434 -CopySettingsFromAgentId 342432324 -AgentType null -PackageName "New package" -PackageDescription "Package for linux computers" 
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
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
        [string] $URISuffix = "api/v1.0/assetmgmt/assets/packages",

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $PackageId,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $MachineGroupId,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $CopySettingsFromAgentId,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [ValidateSet("auto", "windows", "mac", "null")]
        [string] $AgentType,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $CommandLineSwitches = "/e",

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $PackageName,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $PackageDescription
)
	
$Params = @{
    URISuffix = $URISuffix
    Method = 'POST'
    Body = $null
}

# Initialize the body hashtable
$BodyHT = @{
    MachineGroupId = $MachineGroupId
    AgentType = $AgentType
    PackageName = $PackageName
    PackageDescription = $PackageDescription
}

# Add optional parameters only if they are not null or empty
$optionalParams = @{
    PackageId = $PackageId
    CopySettingsFromAgentId = $CopySettingsFromAgentId
    CommandLineSwitches = $CommandLineSwitches
}

foreach ($key in $optionalParams.Keys) {
    if (-not [string]::IsNullOrEmpty($optionalParams[$key])) {
        $BodyHT[$key] = $optionalParams[$key]
    }
}

# Convert the body hashtable to JSON and add to parameters
$Params.Body = $BodyHT | ConvertTo-Json

    return Invoke-VSARestMethod @Params
}
New-Alias -Name Add-VSAAgentInstallPkg -Value New-VSAAgentInstallPkg
Export-ModuleMember -Function New-VSAAgentInstallPkg -Alias Add-VSAAgentInstallPkg