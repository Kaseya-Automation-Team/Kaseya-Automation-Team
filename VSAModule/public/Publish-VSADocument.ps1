function Publish-VSADocument
{
    <#
    .Synopsis
       Uploads a file to Documents page.
    .DESCRIPTION
       Uploads a file from your local computer or network to the Audit > Documents page for a specified agent.
       Uploaded files are situated in C:\Kaseya\UserProfiles\<AgientId>\Docs.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER SourceFilePath
        Specifies file to upload.
    .PARAMETER $DestinationFolder
        Specifies a Document folder to upload the file
    .EXAMPLE
       Publish-VSADocument -AgentId 10001 -SourceFilePath 'File.txt'
    .EXAMPLE
       Publish-VSADocument -AgentId 10001 -SourceFilePath 'File.txt' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful.
    .NOTES
        Version 0.2
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/documents/{0}/file/{1}',

        [Alias("Id")]
        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

        [Alias("Src")]
        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( -Not ($_ | Test-Path -PathType leaf ) ){
                throw "Source file `"$_`" not found"
            }
            return $true
        })]
        [System.IO.FileInfo]$SourceFilePath,

        [Alias("Dest")]
        [Parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestinationFolder
    )

    [string]$FileName  = $($SourceFilePath.Name)
    if (-not [string]::IsNullOrEmpty($DestinationFolder) ) {
        $DestinationFolder = $DestinationFolder -replace '\\', '/'
    }
    $URISuffix = $URISuffix -f $AgentId, $DestinationFolder

    [hashtable]$Params = @{
        'URISuffix' = $URISuffix
        'Method'    = 'PUT'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    
    [Byte[]] $FileBytes    = [System.IO.File]::ReadAllBytes($SourceFilePath)
    [string] $FileEncoding = [System.Text.Encoding]::GetEncoding('UTF-8').GetString($FileBytes)
    [string] $Boundary     = [System.Guid]::NewGuid().ToString()
    [string] $LF           = "`r`n"

    $BodyLines = ( 
        "--$Boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$FileName`"",
        "Content-Type: application/octet-stream$LF",
        $FileEncoding,
        "--$Boundary--$LF" 
    ) -join $LF


    $Params.Add('ContentType', "multipart/form-data; boundary=`"$Boundary`"")
    $Params.Add('Body', $BodyLines)

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "Publish-VSADocument. $($Params | Out-String)"
    }

    return Invoke-VSARestMethod @Params
}
New-Alias -Name Add-VSADocument -Value Publish-VSADocument
Export-ModuleMember -Function Publish-VSADocument -Alias Add-VSADocument