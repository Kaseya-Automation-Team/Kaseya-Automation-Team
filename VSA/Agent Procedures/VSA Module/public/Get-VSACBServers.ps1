function Get-VSACBServers {
    <#
    .Synopsis
       Returns the backup status of each physical server installed with Cloud Backup.
    .DESCRIPTION
       Returns the backup status of each physical server installed with Cloud Backup.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .EXAMPLE
       Get-VSACBServers
    .EXAMPLE
       Get-VSACBServers -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Returns true or false, based on whether the specified module ID is activated.
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/kcb/servers'
    )

    if ([VSAConnection]::IsPersistent)
    {
        $CombinedURL = "$([VSAConnection]::GetPersistentURI())/$URISuffix"
        $UsersToken = "Bearer $( [VSAConnection]::GetPersistentToken() )"
    }
    else
    {
        $ConnectionStatus = $VSAConnection.GetStatus()

        if ( 'Open' -eq $ConnectionStatus )
        {
            $CombinedURL = "$($VSAConnection.URI)/$URISuffix"
            $UsersToken = "Bearer $($VSAConnection.GetToken())"
        }
        else
        {
            throw "Connection status: $ConnectionStatus"
        }
    }

    $authHeader = @{
        Authorization = $UsersToken
    }
    $AuthString
    $requestParameters = @{
        Uri = $CombinedURL
        Method = 'GET'
        Headers = $authHeader
    }
    $requestParameters | Out-String | Write-Debug

    Log-Event -Msg "Executing call GET : $CombinedURL" -Id 1000 -Type "Information"
   
    try {
            $response = Invoke-RestMethod @requestParameters -ErrorAction Stop
            if ($response) {
                Write-Debug "Response"
                $response | Out-String | Write-Debug
            } else {
                "No response returned" | Write-Debug
                "No response returned" | Write-Verbose
            }
            
    }
    catch [System.Net.WebException] {
        Write-Error( "Executing call $Method failed for $URI.`nMessage : $($_.Exception.Message)" )
        throw $_
    }
    return $response
}

Export-ModuleMember -Function Get-VSACBServers