<#
.Synopsis
   Returns VSA users
.DESCRIPTION
   Returns existing VSA users.
   Takes either persistent or non-persistent connection information
.PARAMETER Name
    Specifies existing non-persistent VSAConnection.
.PARAMETER SystemUsersSuffix
.EXAMPLE
   Get-VSAUsers
.EXAMPLE
   Get-VSAUsers -VSAConnection $connection
.INPUTS
   Accepts piped non-persistent VSAConnection 
.OUTPUTS
   Array of custom objects that represent existing VSA users
#>
function Get-VSAUsers
{

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
        [string] $SystemUsersSuffix = 'api/v1.0/system/users',
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    if ([VSAConnection]::IsPersistent)
    {
        $CombinedURL = "$([VSAConnection]::GetPersistentURI())/$SystemUsersSuffix"
        $UsersToken = "Bearer $( [VSAConnection]::GetPersistentToken() )"
    }
    else
    {
        $ConnectionStatus = $VSAConnection.GetStatus()

        if ( 'Open' -eq $ConnectionStatus )
        {
            $CombinedURL = "$($VSAConnection.URI)/$SystemUsersSuffix"
            $UsersToken = "Bearer $($VSAConnection.GetToken())"
        }
        else
        {
            throw "Connection status: $ConnectionStatus"
        }
    }

    #region Filterin, Sorting, Paging
    if ($Filter) {
        $CombinedURL = -join ($CombinedURL, "`?`$filter=$Filter")
    }

    if ($Sort) {
        if ($Filter) {
            $CombinedURL = -join ($CombinedURL, "`&`$orderby=$Sort")
            } else {
            $CombinedURL = -join ($CombinedURL, "`?`$orderby=$Sort")
        }
    }

    if ($Paging) {
        if ($Filter -or $Sort) {
            $CombinedURL = -join ($CombinedURL, "`&`$$Paging")
        } else {
            $CombinedURL = -join ($CombinedURL, "`?`$$Paging")
        }
    }
    #endregion Filterin, Sorting, Paging

    $result = Get-RequestData -URI $CombinedURL -AuthString $UsersToken

    return $result
}
Export-ModuleMember -Function Get-VSAUsers