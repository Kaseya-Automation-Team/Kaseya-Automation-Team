function Add-VSACustomExtensionFile
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
       Add-VSACustomExtensionFile -AgentId '10001' -SourceFilePath 'File.txt'
    .EXAMPLE
       Add-VSACustomExtensionFile -AgentId '10001' -SourceFilePath 'File.txt' -DestinationFolder 'ExistingFolder'
    .EXAMPLE
       Add-VSACustomExtensionFile -AgentId '10001' -SourceFilePath 'File.txt' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent Custom Extension Folders and Files.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/customextensions/{0}/file/{1}',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
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
    $DestinationFolder = $DestinationFolder -replace '\\', '/'
    $URISuffix         = $URISuffix -f $AgentId, $DestinationFolder

    [hashtable]$Params = @{}

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

    If ( $AgentId -in $(Get-VSAAgents @Params | Select-Object -ExpandProperty AgentID) ) {

        $Params.Add('URISuffix', $URISuffix)
        $Params.Add('Method', 'PUT')
        $Params.Add('ContentType', "multipart/form-data; boundary=`"$Boundary`"")
        $Params.Add('Body', $BodyLines)

        $Params | Out-String | Write-Verbose
        $Params | Out-String | Write-Debug

        $result = Update-VSAItems @Params
    } else {
        $Message = "The asset with Agent ID `'$AgentId`' does not exist"
        Log-Event -Msg $Message -Id 4000 -Type "Error"
        throw $Message
    }
    
    if ($result) {
        Log-Event -Msg "`"$SourceFilePath uploaded`" to `"$DestinationFolder`"" -Id 1000 -Type "Infomation"
    }

    return $result
}
Export-ModuleMember -Function Add-VSACustomExtensionFile