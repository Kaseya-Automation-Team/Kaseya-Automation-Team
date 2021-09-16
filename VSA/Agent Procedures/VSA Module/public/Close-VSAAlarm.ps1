function Close-VSAAlarm
{
    <#
    .Synopsis
       Closes VSA alarm
    .DESCRIPTION
       Switches status of specific VSA alarm from Open to Closed
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
    .PARAMETER Reason
        Optional parameter which specifies reason why alarm has been closed
    .EXAMPLE
       Close-VSAAlarm
    .EXAMPLE
       Close-VSAAlarm -VSAConnection $connection
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
        [string] $URISuffix = "api/v1.0/assetmgmt/alarms/{0}/close",
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $true, ValueFromPipelineByPropertyName=$true)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [int] $AlarmId,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Reason
    )


    $URISuffix = $URISuffix -f $AlarmId
       
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
    }

    if ($Reason) {

        $Body = ConvertTo-Json @(@{"key"="notes";"value"=$Reason })
        $Params.Add('Body', $Body)
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Close-VSAAlarm