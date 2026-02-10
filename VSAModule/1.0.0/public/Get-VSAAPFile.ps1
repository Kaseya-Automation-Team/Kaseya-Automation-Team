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
        [string] $Paging,

        [parameter(ParameterSetName='Metadata')]
        [ValidateNotNull()]
        [string] $Sort,

        [switch] $DownloadFile
    )

    if ( $PSCmdlet.MyInvocation.InvocationName -eq 'Get-VSAGetFile' ) {
        $DownloadFile = $true
    }
    if ( $PSCmdlet.MyInvocation.InvocationName -eq 'Get-VSAGetGetFiles' ) {
        $DownloadFile = $false
    }
    if ( [string]::IsNullOrEmpty($Path) -and (-not $DownloadFile) ) {$Path = '.'}
    
    if ( $DownloadFile ) {
        
        $URISuffix = 'api/v1.0/assetmgmt/getfiles/{0}/file/{1}' -f $AgentID, ($Path -replace '\\', '/')
        
        if (-not $DownloadsFolder) {
                $DownloadsFolder = [System.IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), 'Downloads')
            }
        $OutFile = Join-Path -Path $DownloadsFolder -ChildPath $(Split-Path $Path -leaf)

        if ($PSCmdlet.MyInvocation.BoundParameters['VSAConnection']) {
            $baseUri = New-Object System.Uri -ArgumentList $VSAConnection.URI
            $UserToken = $VSAConnection.Token
        } else {
            $baseUri = New-Object System.Uri -ArgumentList $([VSAConnection]::GetPersistentURI())
            $UserToken = [VSAConnection]::GetPersistentToken()
        }
        [string]$URI = [System.Uri]::new($baseUri, $URISuffix) | Select-Object -ExpandProperty AbsoluteUri

        $authHeader = @{
            Authorization = "Bearer $UserToken"
        }

        $requestParameters = @{
            Uri = $URI
            Method = 'GET'
            Headers = $authHeader
            OutFile = $OutFile
        }

        try {
            Invoke-RestMethod @requestParameters -ErrorAction Stop
            return $true
        }
        catch [System.Net.WebException] {
            Write-Error( "Executing call GET failed for $URI.`nMessage : $($_.Exception.Message)" )
            throw $_
        }
    } else {

        $URISuffix = 'api/v1.0/assetmgmt/getfiles/{0}/folder/{1}' -f $AgentID, ($Path -replace '\\', '/')

        $Params = @{
            VSAConnection = $VSAConnection
            URISuffix     = $URISuffix
            Filter        = $Filter
            Paging        = $Paging
            Sort          = $Sort
        }
        #Remove empty keys
        foreach ( $key in $Params.Keys.Clone() ) {
            if ( -not $Params[$key] )  { $Params.Remove($key) }
        }

        return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Get-VSAAPFile