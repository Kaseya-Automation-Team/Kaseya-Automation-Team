function New-VSAAdminTask
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
       New-VSAAdminTask -Reference "VSA-5210-3" -Description "First New Admin Task" -EnabledFlag -TimeSheetFlag
    .EXAMPLE
       New-VSAAdminTask -VSAConnection $connection -Reference "VSA-5210-3" -Description "First New Admin Task"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Success or failure
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/system/sessiontimers/admintasks",

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Reference,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Description,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [switch] $EnabledFlag,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [switch] $TimeSheetFlag
)
	
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
    }

    $Body = ConvertTo-Json @{"Reference"=$Reference; "Description"=$Description; "EnabledFlag"=$EnabledFlag.ToBool(); "TimeSheetFlag"=$TimeSheetFlag.ToBool()} -Compress

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}
New-Alias -Name Add-VSAAdminTask -Value New-VSAAdminTask
Export-ModuleMember -Function New-VSAAdminTask -Alias Add-VSAAdminTask