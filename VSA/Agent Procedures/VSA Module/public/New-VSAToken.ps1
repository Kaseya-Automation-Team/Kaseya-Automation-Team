function New-VSAToken
{
    $creds = Get-Credential -Message "Enter your API username and Personal Authentication Token"
    
    [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($creds.UserName):$($creds.Password | Convertfrom-SecureString)")) | Out-File "$PSScriptRoot\..\private\pat.txt"
}

Export-ModuleMember -Function New-VSAToken