function Get-VSAGetFile
{
    <#
    .Synopsis
       Downloads a file from Get File page.
    .DESCRIPTION
       Returns a file from the Agent Procedures > Get File page.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Path
        Specifies Relative path.
    .PARAMETER DownloadsFolder
        Specifies folder to dowload the file. By default, current profiles' default Downloads folder.
    .EXAMPLE
       Get-VSAGetFile 
    .EXAMPLE
       Get-VSAGetFile -AgentId 10001 -Path 'File.ext'
    .EXAMPLE
       Get-VSAGetFile -AgentId 10001 -Path 'File.ext' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       File stored in the DownloadsFolder.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/getfiles/{0}/file/{1}',

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $DownloadsFolder
    )
    
    if (-not [string]::IsNullOrEmpty($Path) ) {
        $Path = $Path -replace '\\', '/'
        #if ($Path -notmatch '^\/') { $Path = "/$Path"}
        #if ($Path -notmatch '\/$') { $Path = "$Path/"}
    }

    if ( [string]::IsNullOrEmpty($DownloadsFolder) ) {
        $DownloadsFolder = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
    }
    $OutFile         = Join-Path -Path $DownloadsFolder -ChildPath $(Split-Path $Path -leaf)
    $URISuffix = $URISuffix -f $AgentId, $Path

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
Export-ModuleMember -Function Get-VSAGetFile