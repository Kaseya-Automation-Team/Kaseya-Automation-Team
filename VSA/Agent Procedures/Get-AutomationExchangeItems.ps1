$ProgressPreference = 'SilentlyContinue'

[int]$CurrentPage = 1
[bool]$GoNextPage = $true
[string] $ModuleName = 'ImportExcel'
$OutputFile = 'c:\temp\AutomationExchange'
[array]$Collected=@()

while ($GoNextPage) {

    Write-Host "Working on the page number $CurrentPage"

    if ($CurrentPage -eq 1) {
        $URL = "https://www.community.connectit.com/automation-exchange/categories/product"
    } else {
        $URL = "https://www.community.connectit.com/automation-exchange/categories/product/p$CurrentPage"
    }

    $ResponseCode = try {
        (Invoke-WebRequest -Uri $DownloadUrl -OutFile $SaveTo -UseBasicParsing -TimeoutSec 600 -PassThru -ErrorAction Stop).StatusCode
    } catch {
        $_.Exception.Response.StatusCode.value__
    }

    $Request = try {
        Invoke-WebRequest -Uri $URL -ErrorAction Stop
    } catch {
        $_.Exception.Response.StatusCode.value__
    }

    if ( 200 -eq $Request.StatusCode) {
        Write-Host "Processing $URL" -ForegroundColor Green
        $Collected += $Request.Links | Where-Object {$_.class -eq "title"} | Select-Object -Property innerHTML,href
        $CurrentPage++
    } else {
        $GoNextPage = $false
        Write-Host "Can't get URL $URL" -ForegroundColor Red -BackgroundColor White
        Write-Host 'Stop now'
    }
}
if (0 -gt $Collected.Count) {
    if ( $null -ne $(try {Get-Module -Name $ModuleName -ErrorAction Stop} catch {$null}) ) {
        Import-Module -Name $ModuleName
        $OutputFile += '.xlsx'
        $Collected | Export-Excel -Path $OutputFile -TableName AutomationExchange
    } else {
        $OutputFile += '.csv'
        $Collected | Export-Csv -Path $OutputFile -Encoding UTF8 -NoTypeInformation -Force
    }

}