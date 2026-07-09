function Get-VSAAdminTask {
    <#
    .Synopsis
       Returns admin tasks.
    .DESCRIPTION
       Returns all possible admin tasks that can be created for WorkTypeId 0 or information about single task if specified.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TaskId
        Specifies task id if provided.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSAAdminTask
    .EXAMPLE
       Get-VSAAdminTask -TaskId 233434
    .EXAMPLE
       Get-VSAAdminTask -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of items that represent admin tasks or single task
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/sessiontimers/admintasks',

        [Alias('ID')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })] 
        [string] $TaskId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )
    process {

    if( -not [string]::IsNullOrWhiteSpace( $TaskId) ) { $URISuffix = "api/v1.0/system/sessiontimers/admintasks/$TaskId" }
    
    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Filter        = $Filter
        Sort          = $Sort
    }

    foreach ( $key in @($Params.Keys)  ) {
        if ( -not $Params[$key]) { $Params.Remove($key) }
    }

    return Invoke-VSARestMethod @Params
    }
}

Export-ModuleMember -Function Get-VSAAdminTask
