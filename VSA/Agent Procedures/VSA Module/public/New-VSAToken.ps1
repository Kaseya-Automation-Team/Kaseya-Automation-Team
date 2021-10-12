function New-VSAToken
{
<#
.Synopsis
   Generates authentication file
.DESCRIPTION
   Saves encoded API credentials into text file
.EXAMPLE
   New-VSAToken
.OUTPUTS
   Information messages indicating success/failure
#>
    $creds = Get-Credential -Message "Enter your API username and Personal Authentication Token"
    
    try {
        [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($creds.UserName):$($creds.Password | Convertfrom-SecureString)")) | Out-File "$PSScriptRoot\..\private\pat.txt" -Force
        Log-Event -Msg "New authentication pair have been generated and saved in $PSScriptRoot\..\private\pat.txt" -Id 9999 -Type "Information"
    }
    catch {
        Write-Warning "Unable to generate authentication file"
        Write-Warning $Error[0] -ErrorAction Stop
    }
}

Export-ModuleMember -Function New-VSAToken