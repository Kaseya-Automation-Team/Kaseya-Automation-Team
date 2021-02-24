## Kaseya Automation Team
## Used by the "Internet Speed test" Agent Procedure

param (
    [parameter(Mandatory=$true)]
	[string]$Path = "",
    [parameter(Mandatory=$false)]
    [int]$LogIt = 0
)

[string]$Pref = "Continue"
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $LogFile = "$Path\Test-InternetSpeed.log"
    Start-Transcript -Path $LogFile
}

Write-Debug "Script execution started"

$Output = & $Path\ndt-test.exe -quiet -timeout 30s -format=json

Write-Debug ($Output|Out-String)

try {
	$Output = $Output | ConvertFrom-Json
} catch {
	Write-Host "Unable to run speed test executables"
}

$Download = [math]::Round($Output.Download.Value, 2),$Output.Download.Unit | Out-String
$Download.Replace("`r`n", " ") | Out-File -FilePath $Path\download_speedtest.txt

$Upload = [math]::Round($Output.Upload.Value, 2),$Output.Upload.unit | Out-String
$Upload.Replace("`r`n", " ") | Out-File -FilePath $Path\upload_speedtest.txt

$Latency = $Output.MinRTT.Value,$Output.MinRTT.unit | Out-String
$Latency.Replace("`r`n", " ") | Out-File -FilePath $Path\latency_speedtest.txt

if (1 -eq $LogIt)
{
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}