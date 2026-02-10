function Get-VSAAuditDocument
{
    <#
    .Synopsis
        Downloads a specified document or retrieves documents' metadata from the Audit > Documents page.
    .DESCRIPTION
        This function retrieves information about documents or downloads a specific document from the Audit > Documents page in a VSA environment.
        Supports both persistent and non-persistent VSA connections.
    .PARAMETER AgentID
        Specifies the ID of the agent.
    .PARAMETER VSAConnection
        Specifies an existing non-persistent VSAConnection.
    .PARAMETER Path
        Specifies the path to a specific document or folder.
    .PARAMETER DownloadsFolder
        Specifies the folder to download files. Defaults to the user's Downloads folder.
    .PARAMETER Filter
        Specifies a REST API filter for document retrieval.
    .PARAMETER Paging
        Specifies REST API paging parameters.
    .PARAMETER Sort
        Specifies REST API sorting criteria.
    .PARAMETER DownloadDocument
        Switch parameter. If present, specifies that a specific document should be downloaded.
    .EXAMPLE
       Get-VSAAuditDocument -AgentID 10001 -Path 'Folder/Document.doc' -DownloadDocument
    .EXAMPLE
       Get-VSAAuditDocument -AgentID 10001 -Path 'Folder/Document.doc' -VSAConnection $connection  -DownloadDocument
    .EXAMPLE
       Get-VSAAuditDocument -AgentID 10001 -Filter 'Category eq "Important"'
    .INPUTS
       Accepts piped non-persistent VSAConnection.
    .OUTPUTS
       Returns a single document or an array of documents based on the provided parameters.
    #>
    [CmdletBinding(DefaultParameterSetName='Metadata')]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") {
                throw "AgentID must be a numeric value."
            }
            return $true
        })]
        [string] $AgentID,

        [parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [parameter(Mandatory=$false)]
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

        [switch] $DownloadDocument
    )

    if ( $PSCmdlet.MyInvocation.InvocationName -eq 'Get-VSADocument' ) {
        $DownloadDocument = $true
    }
    if ( $PSCmdlet.MyInvocation.InvocationName -eq 'Get-VSADocuments' ) {
        $DownloadDocument = $false
    }

    if ( [string]::IsNullOrEmpty($Path) -and (-not $DownloadDocument) ) {$Path = '.'}

    [string] $URISuffix = $(if ( $DownloadDocument ) {
        'api/v1.0/assetmgmt/documents/{0}/file/{1}'
    } else {
        'api/v1.0/assetmgmt/documents/{0}/folder/{1}'
    })  -f $AgentID, ($Path -replace '\\', '/')

    $Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
    }

    if ($DownloadDocument) {
        if (-not $DownloadsFolder) {
            $DownloadsFolder = [System.IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), 'Downloads')
        }
        $Params['DownloadsFolder'] = $DownloadsFolder
    } else {
        $Params['Filter'] = $Filter
        $Params['Paging'] = $Paging
        $Params['Sort']   = $Sort
    }

    #Remove empty keys
    foreach ( $key in $Params.Keys.Clone() ) {
        if ( -not $Params[$key] )  { $Params.Remove($key) }
    }

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "Get-VSAAuditDocument: $($Params | Out-String)" | Write-Debug
    }
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        "Get-VSAAuditDocument: $($Params | Out-String)" | Write-Verbose
    }

    return Invoke-VSARestMethod @Params
}

# Define aliases
Set-Alias -Name Get-VSADocument -Value Get-VSAAuditDocument
Set-Alias -Name Get-VSADocuments -Value Get-VSAAuditDocument

Export-ModuleMember -Function Get-VSAAuditDocument -Alias Get-VSADocument
Export-ModuleMember -Function Get-VSAAuditDocument -Alias Get-VSADocuments