@('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*') `
    | Get-ItemProperty -ErrorAction SilentlyContinue `
    | Where-Object {$_.DisplayName -like 'Intel® Driver & Support Assistant'} `
    | Select-Object -ExpandProperty QuietUninstallString `
    | ForEach-Object { [regex]::Matches($_, '(?<=\").+?(?=\")').Value | Write-Output} `
    | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } `
    | ForEach-Object { Start-Process -FilePath $_ -ArgumentList '/uninstall /quiet' -Wait}