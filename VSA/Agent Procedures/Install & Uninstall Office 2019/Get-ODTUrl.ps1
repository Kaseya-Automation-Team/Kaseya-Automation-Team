<#
.Synopsis
   Gets the URL of latest version of the ODT.
.NOTES
   Version 0.1
   Author: Proserv Team - VS
.EXAMPLE
   .\Get-ODTUrl.ps1
#>

param (
    [parameter(Mandatory=$false)]
    [string] $PageUri = 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117'
)

try {
    Set-Variable ProgressPreference SilentlyContinue
    $WebResponse = Invoke-WebRequest -Uri $PageUri -UseBasicParsing -ErrorAction Stop
} catch {
    "$PageUri response: [$($_.Exception.Response.StatusCode.Value__)]" | Write-Debug
}

if ($null -ne $WebResponse) { #URL responded
    #Look for actual download URL
    [string]$DownloadUri = $WebResponse.Links | Where-Object outerHTML -Match 'click here to download manually' | Select-Object -ExpandProperty href -Unique
    if ( [string]::IsNullOrEmpty($DownloadUri)) {
        $DownloadUri = 'Failed' 
    }
} else {
    $DownloadUri = 'Failed' 
}
$DownloadUri | Write-Output