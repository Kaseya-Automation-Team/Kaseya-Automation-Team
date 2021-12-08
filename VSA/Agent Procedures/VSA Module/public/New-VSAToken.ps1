function New-VSAToken
{
<#
.Synopsis
   Generates authentication file
.DESCRIPTION
   Saves encoded API credentials into text file
.EXAMPLE
   New-VSAToken
.EXAMPLE
   New-VSAToken -Username "admin" -PAT "f6637be7-7e50-4b2d-a874-e4d0fcd55ec4"
.OUTPUTS
   Information messages indicating success/failure
#>


    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/scopes',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Username,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $PAT

    )

    if ($Username -and $PAT) {

            $Secure_PAT = ConvertTo-SecureString $PAT -AsPlainText -Force
            $Unsecure_PAT = $Secure_PAT | ConvertFrom-SecureString
            [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($Username):$Unsecure_PAT"))|Out-File "$PSScriptRoot\..\private\pat.txt"

    } else {

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
}

Export-ModuleMember -Function New-VSAToken