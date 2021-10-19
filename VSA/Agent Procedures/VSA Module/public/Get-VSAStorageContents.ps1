function Get-VSAStorageContents {
    <#
    .Synopsis
       Downloads remote control recorded sessions.
    .DESCRIPTION
       Returns the file contents of a remote control recording in the body of the response.
       The {fileId} is specified using the GUID in the AgentFileId column of the Storage.Agent table.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER FileId
        Specifies AgentFileId from the SQL table.
    .PARAMETER DownloadsFolder
        Specifies folder to dowload the file. By default, current profiles' default Downloads folder.
    .EXAMPLE
       Get-VSAStorageContent -FileId 233434543543543
    .EXAMPLE
       Get-VSAStorageContent -FileId 233434543543543 -FileName "test.webm" -DownloadsFolder "c:\temp"
    .EXAMPLE
       Get-VSAStorageContent -VSAConnection $connection -FileId 233434543543543
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       File to downloads folder
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
        [string] $URISuffix = 'api/v1.0/storage/file/{0}/contents',
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $FileId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $FileName,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $DownloadsFolder
    )

    if ( [string]::IsNullOrEmpty($DownloadsFolder) ) {
        $DownloadsFolder = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
    }

    if ( [string]::IsNullOrEmpty($FileName) ) {
        $FileName = "$FileId.webm"
    }

    $OutFile = "$DownloadsFolder\$FileName"

    $URISuffix = $URISuffix -f $FileId

    if ([VSAConnection]::IsPersistent)
    {
        $URI = "$([VSAConnection]::GetPersistentURI())/$URISuffix"
        $UsersToken = "Bearer $( [VSAConnection]::GetPersistentToken() )"
    }
    else
    {
        $ConnectionStatus = $VSAConnection.GetStatus()

        if ( 'Open' -eq $ConnectionStatus )
        {
            $URI = "$($VSAConnection.URI)/$URISuffix"
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

    $requestParameters = @{
        Uri = $URI
        Method = 'GET'
        Headers = $authHeader
        OutFile = $OutFile
    }

    $requestParameters | Out-String | Write-Debug
    $requestParameters | Out-String | Write-Output
    
    try {
        Invoke-RestMethod @requestParameters -ErrorAction Stop
    }
    catch [System.Net.WebException] {
        Write-Error( "Executing call GET failed for $URI.`nMessage : $($_.Exception.Message)" )
        throw $_
    }

}

Export-ModuleMember -Function Get-VSAStorageContents