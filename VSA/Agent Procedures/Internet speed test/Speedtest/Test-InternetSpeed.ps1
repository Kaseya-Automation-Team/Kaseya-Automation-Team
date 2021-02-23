## Kaseya Automation Team
## Used by the "Internet Speed test" Agent Procedure

param (
    [parameter(Mandatory=$true)]
	[string]$Path = "",
    [parameter(Mandatory=$false)]
    [int]$LogIt = 0
)

$Output = & $Path\ndt-test.exe -quiet -timeout 30s -format=json

$Output = $Output | ConvertFrom-Json

$Download = [math]::Round($Output.Download.Value, 2),$Output.Download.Unit | Out-String
$Download.Replace("`r`n", " ") | Out-File -FilePath $Path\download_speedtest.txt

$Upload = [math]::Round($Output.Upload.Value, 2),$Output.Upload.unit | Out-String
$Upload.Replace("`r`n", " ") | Out-File -FilePath $Path\upload_speedtest.txt

$Latency = $Output.MinRTT.Value,$Output.MinRTT.unit | Out-String
$Latency.Replace("`r`n", " ") | Out-File -FilePath $Path\latency_speedtest.txt