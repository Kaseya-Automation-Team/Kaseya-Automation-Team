function Get-VSAScopes
{

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [VSAConnection] $VSAConnection,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $SystemUsersSuffix = 'system/scopes',
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

    if ( $($VSAConnection.GetStatus()) -eq "Open") #if token is valid
    {
        $CombinedURL = "$($VSAConnection.URI)/$SystemUsersSuffix"
        
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

        $result = Get-RequestData -URI "$CombinedURL" -AuthString "Bearer $($VSAConnection.GetToken())"

        return $result
    }
    else
    { throw "Connection status: $ConnectionStatus" }
}
Export-ModuleMember -Function Get-VSAScopes