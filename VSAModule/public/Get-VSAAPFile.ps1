function Get-VSAAPFile
{
    <#
    .Synopsis
        Downloads a specified file or retrieves files' metadata from the Agent Procedures > Get File page.
    .DESCRIPTION
        This function retrieves information about files or downloads a specific file from the Agent Procedures > Get File page in a VSA environment.
        Supports both persistent and non-persistent VSA connections.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Path
        Specifies Relative path.
    .PARAMETER DownloadsFolder
        Specifies folder to dowload the file. By default, current profiles' default Downloads folder.
    .EXAMPLE
       Get-VSAAPFile 
    .EXAMPLE
       Get-VSAAPFile -AgentId 10001 -Path 'File.ext' -DownloadFile
    .EXAMPLE
       Get-VSAAPFile -AgentId 10001 -Path 'File.ext' -VSAConnection $connection -DownloadFile
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       File stored in the DownloadsFolder.
    #>
    [CmdletBinding(DefaultParameterSetName='Metadata')]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $DownloadsFolder,

        [parameter(ParameterSetName='Metadata')]
        [ValidateNotNull()]
        [string] $Filter,

        [parameter(ParameterSetName='Metadata')]
        [ValidateNotNull()]
        [string] $Sort,

        [switch] $DownloadFile
    )
    process {

    # F-04: 'Get-VSAGetFile'/'Get-VSAGetGetFiles' are not aliases this module ever creates, so
    # these InvocationName checks could never fire. The -DownloadFile switch is the only way to
    # opt into download mode.
    if ( [string]::IsNullOrEmpty($Path) -and (-not $DownloadFile) ) {$Path = '.'}
    
    if ( $DownloadFile ) {

        $URISuffix = 'api/v1.0/assetmgmt/getfiles/{0}/file/{1}' -f $AgentID, (Format-VSAPathSegment ($Path -replace '\\', '/'))

        if (-not $DownloadsFolder) {
                $DownloadsFolder = [System.IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), 'Downloads')
            }

        # F-32: route the download through the shared transport (Invoke-VSARestMethod -> Get-RequestData)
        # instead of a raw Invoke-RestMethod. The transport forwards -OutFile to write the body to disk
        # AND applies the module's cert-bypass strategy, token renewal, and retry. The previous raw call
        # built its own request and never applied the cert bypass, so it ignored -IgnoreCertificateErrors:
        # every GetFiles download against a self-signed / untrusted-cert server failed the TLS handshake
        # ("The SSL connection could not be established"). This mirrors how Get-VSAAuditDocument downloads.
        $Params = @{
            URISuffix = $URISuffix
            Method    = 'GET'
            OutFile   = Join-Path -Path $DownloadsFolder -ChildPath $(Split-Path $Path -leaf)
        }
        if ($VSAConnection) { $Params.Add('VSAConnection', $VSAConnection) }

        return Invoke-VSARestMethod @Params

    } else {

        $URISuffix = 'api/v1.0/assetmgmt/getfiles/{0}/folder/{1}' -f $AgentID, (Format-VSAPathSegment ($Path -replace '\\', '/'))

        $Params = @{
            VSAConnection = $VSAConnection
            URISuffix     = $URISuffix
            Filter        = $Filter
            Sort          = $Sort
        }
        #Remove empty keys
        foreach ( $key in @($Params.Keys) ) {
            if ( -not $Params[$key] )  { $Params.Remove($key) }
        }

        return Invoke-VSARestMethod @Params
    }
    }
}
Export-ModuleMember -Function Get-VSAAPFile
