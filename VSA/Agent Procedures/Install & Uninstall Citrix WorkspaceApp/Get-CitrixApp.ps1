<#
.Synopsis
   Downloads the Latest Version Of the Citrix Workspace App
.DESCRIPTION
   Parses Citrix's Apd Download page, finds the Download Uri and downloads the Latest Version Of the Citrix Workspace App  
.NOTES
   Version 0.1
   Author: Proserv Team - VS
.PARAMETERS
    [string] OutputFilePath
        - Output file name
    [string] PageUri
        - Citrix's Apd Download page
    [string] AppName
        - Setup file name for the application
    [switch] LogIt
        - Enables execution transcript	
.EXAMPLE
   .\Get-CitrixApp -LogIt
#>

param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputFilePath,
    [parameter(Mandatory=$false)]
    [string] $PageUri = 'https://www.citrix.com/downloads/workspace-app/windows/workspace-app-for-windows-latest.html',
    [parameter(Mandatory=$false)]
    [string] $AppName = 'CitrixWorkspaceApp.exe',
    [parameter(Mandatory=$false)]
    [switch] $LogIt
)

#region check/start transcript
[string]$Pref = 'Continue'
if ( $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
    $LogFile = "$ScriptPath\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

try
{
    $WebResponse = Invoke-WebRequest -Uri $PageUri -UseBasicParsing -ErrorAction Stop
}
catch
{
    "$PageUri response: [$($_.Exception.Response.StatusCode.Value__)]" | Write-Output
}

if ($null -ne $WebResponse) #URL responded
{
    #Look for actual download URL
    [string]$DownloadUri = $WebResponse.Links | Where-Object outerHTML -Match 'Download File' | Where-Object rel -Match $AppName | Select-Object -ExpandProperty rel
    if ( -Not [string]::IsNullOrEmpty($DownloadUri))
    {
        try
        {
            $DownloadResult = Invoke-WebRequest -Uri "https:$DownloadUri" -OutFile $OutputFilePath -TimeoutSec 600
            #Status is 200 for SUCCESS
            $DownloadResult.StatusCode | Write-Output
        }
        catch
        {
            "$DownloadUri response: [$($_.Exception.Response.StatusCode.Value__)]" | Write-Output
        }
    }
    else
    {
        "Didn't get download Uri for $AppName" | Write-Output
    }
}
#region check/stop transcript
if ( $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript