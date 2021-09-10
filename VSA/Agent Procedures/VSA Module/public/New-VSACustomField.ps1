function New-VSACustomField {
    $URISuffix = 'api/v1.0/assetmgmt/assets/customfields'
    [string]$FieldName = "TestField"
    [string]$FieldType = "string"

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
    $Body = @(@{"key"="FieldName";"value"=$FieldName },@{ "key"="FieldType";"value"=$FieldType }) | ConvertTo-Json

    $authHeader = @{
        Authorization = $UsersToken
    }

    $requestParameters = @{
        Uri = $CombinedURL
        Method = 'Post'
        Headers = $authHeader
        Body = $Body
        ContentType = "application/json"
        Verbose = $true
    }
    $requestParameters

    Invoke-WebRequest @requestParameters
}
Export-ModuleMember -Function New-VSACustomField