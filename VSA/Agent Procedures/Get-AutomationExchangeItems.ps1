$CurrentPage = 1
While ($CurrentPage -le 23){

    Write-Host "Working on the page number $CurrentPage"

    if ($CurrentPage -eq 1) {
        $URL = "https://www.community.connectit.com/automation-exchange/categories/product"
    } else {
        $URL = "https://www.community.connectit.com/automation-exchange/categories/product/p$CurrentPage"
    }

    $Request = Invoke-WebRequest -Uri $URL
    Write-Host $URL
    $Request.Links|Where-Object {$_.class -eq "title"}|Select-Object -Property innerHTML,href|Export-Excel -Path c:\temp\test.xlsx -TableName AutomationExchange -Append

    $CurrentPage++
}