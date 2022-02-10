$i=3
while($True) {
    $error.clear()
    $MappedDrives = Get-SmbMapping | Where-Object {$_.Status -eq  'Unavailable'} | Select-Object LocalPath, RemotePath
    foreach( $MappedDrive in $MappedDrives) {
        try {
            New-SmbMapping -LocalPath $MappedDrive.LocalPath -RemotePath $MappedDrive.RemotePath -Persistent $True
        } catch {
            Write-Host "There was an error mapping $MappedDrive.RemotePath to $MappedDrive.LocalPath"
        }
    }
    $i--
    if($error.Count -eq 0 -Or $i -eq 0) {break}

    Start-Sleep -Seconds 30
}