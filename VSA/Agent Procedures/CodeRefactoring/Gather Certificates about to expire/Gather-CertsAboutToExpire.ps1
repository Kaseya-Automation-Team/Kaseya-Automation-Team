$ExpireWithInDays = 30
$Destination = "$Env:Temp\certs.csv"

Set-Location Cert: ; Get-ChildItem -Recurse | Where-Object { ($_.Thumbprint)  -and ( $_.notafter -ge (Get-Date) ) -and ( $_.notafter -le (Get-Date).AddDays($ExpireWithInDays) ) } | Select-Object Thumbprint, Subject, NotAfter | Export-Csv -Encoding UTF8 -Force -NoTypeInformation -Path $Destination

eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "Certificates that are about to Expire are uploaded to a csv file at the location $Destination" | Out-Null