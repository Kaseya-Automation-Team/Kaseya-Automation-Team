function Get-VSAStorageContent {
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
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/storage/file/{0}/contents',

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $FileId,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
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

    if ( $null -eq $VSAConnection ) {
        $VSAServerURI = "$([VSAConnection]::GetPersistentURI())/$URISuffix"
        $UsersToken = "Bearer $( [VSAConnection]::GetPersistentToken() )"
    } else {
        $VSAServerURI = "$VSAConnection.URI/$URISuffix"
        $UsersToken = "Bearer $($VSAConnection.Token)"
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

    #region messages to verbose and debug streams
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "Get-VSAStorageContent: $($requestParameters | Out-String)" | Write-Debug
    }
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        "Get-VSAStorageContent: $($requestParameters | Out-String)" | Write-Verbose
    }
    #endregion messages to verbose and debug streams
    
    try {
        Invoke-RestMethod @requestParameters -ErrorAction Stop
    }
    catch [System.Net.WebException] {
        Write-Error( "Executing call GET failed for $URI.`nMessage : $($_.Exception.Message)" )
        throw $_
    }

}
New-Alias -Name Get-VSAStorageContents -Value Get-VSAStorageContent
Export-ModuleMember -Function Get-VSAStorageContent -Alias Get-VSAStorageContents