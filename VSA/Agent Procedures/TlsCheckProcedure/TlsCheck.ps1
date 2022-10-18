$key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client\'
if (Test-Path $key) {
    $TLS = Get-ItemProperty $key
    if ($TLS.DisabledByDefault -ne 0 -or $TLS.Enabled -eq 0) {
        Write-Host "TLS 1.0 is NOT Enabled"
        }
    else {
    Write-Host "TLS 1.0 is Enabled"
    }
 }
else {
    write-Host "TLS 1.0 is Enabled"
}