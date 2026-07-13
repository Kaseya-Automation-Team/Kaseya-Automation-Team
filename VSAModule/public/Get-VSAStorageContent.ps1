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

        [parameter(DontShow, Mandatory=$false)]
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
    process {

    if ( [string]::IsNullOrEmpty($DownloadsFolder) ) {
        $DownloadsFolder = Join-Path -Path ([Environment]::GetFolderPath('UserProfile')) -ChildPath 'Downloads'
    }

    if ( [string]::IsNullOrEmpty($FileName) ) {
        $FileName = "$FileId.webm"
    }

    $OutFile = Join-Path -Path $DownloadsFolder -ChildPath $FileName

    # Route the download through the transport so token renewal, retry and certificate handling
    # all apply. Get-RequestData writes the response body to -OutFile.
    [hashtable]$Params = @{
        URISuffix = ($URISuffix -f $FileId)
        Method    = 'GET'
        OutFile   = $OutFile
    }
    if ($VSAConnection) { $Params['VSAConnection'] = $VSAConnection }

    #region messages to verbose and debug streams
    "Get-VSAStorageContent: $($Params | Out-String)" | Write-Debug

    "Get-VSAStorageContent: downloading FileId '$FileId' to '$OutFile'" | Write-Verbose

    #endregion messages to verbose and debug streams

    return Invoke-VSARestMethod @Params
    }
}
New-Alias -Name Get-VSAStorageContents -Value Get-VSAStorageContent
Export-ModuleMember -Function Get-VSAStorageContent -Alias Get-VSAStorageContents