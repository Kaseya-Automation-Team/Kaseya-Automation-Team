function New-VSAToken
{
$SecurePassword = Read-Host -AsSecureString  "Enter Personal Authentication Token" | convertfrom-securestring | out-file $PSScriptRoot\..\private\pat.txt
}
Export-ModuleMember -Function New-VSAToken