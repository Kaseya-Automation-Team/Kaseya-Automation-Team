param (
    [parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
    [string] $IndicatorFile,
    [parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=1)]
    [string] $ProductName,
    [parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=2)]
    [string] $MinVersion
)

#region check/start transcript
[string]$Pref = 'Continue'
$DebugPreference = $Pref
$VerbosePreference = $Pref
$InformationPreference = $Pref
$ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
$ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
$LogFile = "$ScriptPath\$ScriptName.log"
Start-Transcript -Path $LogFile
#endregion check/start transcript

[string] $InstalledSoftware = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
if ([System.Environment]::Is64BitOperatingSystem)
{    
    $InstalledSoftware = 'HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
}

$KLCUninstallParams = Get-ItemProperty -Path Registry::$InstalledSoftware | `
                    Select-Object   @{name="DisplayName";expression={$_.DisplayName}}, 
                    @{name="Version";expression={$_.DisplayVersion}}, 
                    @{name="UninstallString";expression={$_.UninstallString}},
                    @{name="BundleCachePath";expression={$_.BundleCachePath}} | `
                    Where-Object { ($_.DisplayName -match $ProductName) -and ($_.Version -lt $MinVersion)}

#Uninstall using parameters found for older KLC version
if ( -not ([string]::IsNullOrEmpty( $KLCUninstallParams.UninstallString )) )
{
    if (Test-Path -Path $KLCUninstallParams.BundleCachePath)
    {
        Write-Debug "Invoke-Expression -Command & `"$($KLCUninstallParams.UninstallString) /quiet`""
        Invoke-Expression -Command "& $($KLCUninstallParams.UninstallString) /quiet"
        $KLCUninstallParams.Version | Out-File -FilePath "$ScriptPath\$IndicatorFile" -Force
    }
}

#region check/stop transcript
$Pref = 'SilentlyContinue'
$DebugPreference = $Pref
$VerbosePreference = $Pref
$InformationPreference = $Pref
Stop-Transcript
#endregion check/stop transcript