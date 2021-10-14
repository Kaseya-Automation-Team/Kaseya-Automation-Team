function Add-VSAAdminTask
{
    <#
    .Synopsis
       Creates a new AdminTaskType.
    .DESCRIPTION
       Creates a new AdminTaskType.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Reference
        Specifies reference value of task
    .PARAMETER Description
        Specifies description of new task
    .PARAMETER EnabledFlag
        Specifies if task type is enabled
    .PARAMETER TimeSheetFlag
        Specifies time sheet flag
    .EXAMPLE
       Add-VSAAdminTask -Reference "VSA-5210-3" -Description "First New Admin Task" -EnabledFlag -TimeSheetFlag
    .EXAMPLE
       Add-VSAAdminTask -VSAConnection $connection -Reference "VSA-5210-3" -Description "First New Admin Task"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Success or failure
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
        [string] $URISuffix = "api/v1.0/system/sessiontimers/admintasks",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Reference,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Description,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [switch] $EnabledFlag,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [switch] $TimeSheetFlag
)
	
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
    }

    $Body = ConvertTo-Json @{"Reference"=$Reference; "Description"=$Description; "EnabledFlag"=$EnabledFlag.ToBool(); "TimeSheetFlag"=$TimeSheetFlag.ToBool()}

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Add-VSAAdminTask