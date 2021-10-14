function Remove-VSASessionTimer
{
    <#
    .Synopsis
       Deletes a SessionTimer.
    .DESCRIPTION
       Deletes a SessionTimer without committing the data to the database or with.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .EXAMPLE
       Remove-VSASessionTimer -Reference "VSA-5210-3" -Description "First New Admin Task" -EnabledFlag -TimeSheetFlag
    .EXAMPLE
       Remove-VSASessionTimer -VSAConnection $connection -Reference "VSA-5210-3" -Description "First New Admin Task"
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
        [string] $URISuffix = "api/v1.0/system/sessiontimers/{0}",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $TimerId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [switch] $Force
)
	
    $URISuffix = $URISuffix -f $TimerId

    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if ($Force) {
        $Params.Add('Method', 'PATCH')
    } else {
        $Params.Add('Method', 'DELETE')
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Remove-VSASessionTimer