[int]$CurrentPage = 1
[bool]$GoNextPage = $true
[string] $ModuleName = 'ImportExcel'
$OutputFile = 'c:\temp\AutomationExchange'
[array] $Collected = @()

Set-Variable ProgressPreference SilentlyContinue
[string] $Regex = '(?<=\<a title\=\").+?(?=\")'

function Get-RequestData ($URL) {
    try {
            $response = Invoke-WebRequest -Uri $URL -ErrorAction Stop
            if ( $response ) {
                "$($MyInvocation.MyCommand). Response:`n$response" | Out-String | Write-Debug
                if ( 200 -eq $response.StatusCode ) {
                    return $response
                } else {
                    Write-Error "$response.Result"
                    Write-Error "$response.Error"
                    throw $($response.Error)
                }
            } else {
                "$($MyInvocation.MyCommand). No response returned" | Write-Debug
                "$($MyInvocation.MyCommand). No response returned" | Write-Verbose
            }
            
    }
    catch [System.Net.WebException] {
        $null
    }
}

while ($GoNextPage) {
    [string] $URL = 'https://www.community.connectit.com/automation-exchange/categories/product'

    if ( 1 -lt $CurrentPage ) {
        $URL += "/p$CurrentPage"
    }

    $PageResponse = Get-RequestData $URL
    if ($null -ne $PageResponse){

        Write-Host "Processing $URL - Page number <" -NoNewline
        Write-Host "$CurrentPage" -ForegroundColor Green  -NoNewline
        Write-Host '>'

        [array] $PageItems = $PageResponse.Links | Where-Object {$_.class -eq 'title'} | Select-Object -Property innerHTML, href

        [int]$TotalItems = $PageItems.count
        [int]$CurrentItem = 1
        if ( 0 -lt $TotalItems ) {
            
            foreach( $item in $PageItems ) {
                Write-Host "Item $CurrentItem of $TotalItems"

                $ItemRespose = Get-RequestData $($item.href)
                $item | Add-Member -NotePropertyName Details -NotePropertyValue $null
                $item | Add-Member -NotePropertyName Author -NotePropertyValue $null

                if ( $null -ne $ItemRespose) {
                    $HTMLBodyElements = $ItemRespose.ParsedHtml.body.getElementsByTagName('div') 
                    [array] $UserContent = $HTMLBodyElements | Where-Object { $_.getAttributeNode('class').Value -eq 'Message userContent' }
                    if (0 -lt $UserContent.Count) {
                        $item.Details = $UserContent[0] | Select-Object -ExpandProperty innerText
                    }
                }
                
                $item.Author = [regex]::Matches( $($HTMLBodyElements | Where-Object { $_.getAttributeNode('class').Value -eq 'Item-Header DiscussionHeader' } | Select-Object -ExpandProperty innerHtML), $Regex ).Value
                $Collected += $item
                $CurrentItem++
                Remove-Variable item
            }
        } else {
            Write-Host "No items on Page <$URL>" -ForegroundColor Yellow
        }
        
        $CurrentPage++
    } else {
        $GoNextPage = $false
        Write-Host "Can't get URL $URL" -ForegroundColor Red -BackgroundColor White
        Write-Host 'Stop now'
    }
}

if ( 0 -gt $Collected.Count ) {
    if ( (Get-Module -ListAvailable | Select-Object -ExpandProperty Name) -contains $ModuleName ) {
        Import-Module -Name $ModuleName
        $OutputFile += '.xlsx'
        $Collected | Export-Excel -Path $OutputFile -TableName AutomationExchange
    } else {
        $OutputFile += '.csv'
        $Collected | Export-Csv -Path $OutputFile -Encoding UTF8 -NoTypeInformation -Force
    }
}