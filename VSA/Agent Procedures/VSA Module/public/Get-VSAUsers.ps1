function Get-VSAUsers
{

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [VSAConnection] $VSAConnection,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $SystemUsersSuffix = 'api/v1.0/system/users',
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    if ([VSAConnection]::IsPersistent)
    {
        $UsersURI = "$([VSAConnection]::GetPersistentURI())/$SystemUsersSuffix"
        $UsersToken = "Bearer $( [VSAConnection]::GetPersistentToken() )"
    }
    else
    {
        $ConnectionStatus = $VSAConnection.GetStatus()

        if ( 'Open' -eq $ConnectionStatus )
        {
            $CombinedURL = "$($VSAConnection.URI)/$SystemUsersSuffix"
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

    $result = Get-RequestData -URI "$CombinedURL" -AuthString "Bearer $($VSAConnection.GetToken())"

    return $result
}
Export-ModuleMember -Function Get-VSAUsers