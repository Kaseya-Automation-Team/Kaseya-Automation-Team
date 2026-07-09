function Publish-VSACustomExtensionFile
{
    <#
    .Synopsis
       Uploads a file to Custom Extension Folder.
    .DESCRIPTION
       Uploads a file to the agent's Custom Extension Folder.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER SourceFilePath
        Specifies file to upload to the agent's custom extension folder. The root custom extension folder by default.
    .PARAMETER $DestinationFolder
        Specifies agent's custom extension folder to upload the file.
    .EXAMPLE
       Publish-VSACustomExtensionFile -AgentId 10001 -SourceFilePath 'File.txt'
    .EXAMPLE
       Publish-VSACustomExtensionFile -AgentId 10001 -SourceFilePath 'File.txt' -DestinationFolder 'ExistingFolder'
    .EXAMPLE
       Publish-VSACustomExtensionFile -AgentId 10001 -SourceFilePath 'File.txt' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/customextensions/{0}/file/{1}',

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( -Not ($_ | Test-Path -PathType leaf ) ){
                throw "Source file `"$_`" not found"
            }
            return $true
        })]
        [System.IO.FileInfo]$SourceFilePath,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $DestinationFolder
    )

    [string]$FileName  = $($SourceFilePath.Name)
    if (-not [string]::IsNullOrEmpty($DestinationFolder) ) {
        $DestinationFolder = $DestinationFolder -replace '\\', '/'
    }
    $URISuffix = $URISuffix -f $AgentId, $DestinationFolder

    # Build the multipart body as raw bytes so binary files survive unmodified (F-37): converting
    # the file to a string and back (the previous approach) corrupts any byte sequence that isn't
    # valid UTF-8, since that round-trip is lossy.
    [Byte[]] $FileBytes = [System.IO.File]::ReadAllBytes($SourceFilePath)
    [string] $Boundary  = [System.Guid]::NewGuid().ToString()
    [string] $LF        = "`r`n"

    [string] $Header = "--$Boundary$LF" +
        "Content-Disposition: form-data; name=`"file`"; filename=`"$FileName`"$LF" +
        "Content-Type: application/octet-stream$LF$LF"
    [string] $Footer = "$LF--$Boundary--$LF"

    [Byte[]] $BodyBytes = [System.Text.Encoding]::UTF8.GetBytes($Header) + $FileBytes + [System.Text.Encoding]::UTF8.GetBytes($Footer)

    [hashtable]$Params = @{
        URISuffix   = $URISuffix
        Method      = 'PUT'
        ContentType = "multipart/form-data; boundary=`"$Boundary`""
        Body        = $BodyBytes
    }
    if ($VSAConnection) { $Params.Add('VSAConnection', $VSAConnection) }

            Write-Debug "Publish-VSACustomExtensionFile: $($Params | Out-String)"
    
            Write-Verbose "Publish-VSACustomExtensionFile: $($Params | Out-String)"
    

    return Invoke-VSARestMethod @Params
}
New-Alias -Name Add-VSACustomExtensionFile -Value Publish-VSACustomExtensionFile
Export-ModuleMember -Function Publish-VSACustomExtensionFile -Alias Add-VSACustomExtensionFile