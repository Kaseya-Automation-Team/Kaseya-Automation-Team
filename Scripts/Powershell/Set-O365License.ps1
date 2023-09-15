param (
    [parameter(Mandatory=$true)]
    [ValidateSet('O365_BUSINESS','SMB_BUSINESS','OFFICESUBSCRIPTION','O365_BUSINESS_ESSENTIALS','SMB_BUSINESS_ESSENTIALS','O365_BUSINESS_PREMIUM','SMB_BUSINESS_PREMIUM','SPB','SPE_E3','SPE_E5','SPE_E3_USGOV_DOD','SPE_E3_USGOV_GCCHIGH','INFORMATION_PROTECTION_COMPLIANCE','IDENTITY_THREAT_PROTECTION','IDENTITY_THREAT_PROTECTION_FOR_EMS_E5','M365_F1','SPE_F1','FLOW_FREE','MCOEV','MCOEV_DOD','MCOEV_FACULTY','MCOEV_GOV','MCOEV_GCCHIGH','MCOEVSMB_1','MCOEV_STUDENT','MCOEV_TELSTRA','MCOEV_USGOV_DOD','MCOEV_USGOV_GCCHIGH','WIN_DEF_ATP','CRMPLAN2','CRMSTANDARD','IT_ACADEMY_AD','TEAMS_FREE','ENTERPRISEPREMIUM_FACULTY','ENTERPRISEPREMIUM_STUDENT','EQUIVIO_ANALYTICS','ATP_ENTERPRISE','STANDARDPACK','STANDARDWOFFPACK','ENTERPRISEPACK','DEVELOPERPACK','ENTERPRISEPACK_USGOV_DOD','ENTERPRISEPACK_USGOV_GCCHIGH','ENTERPRISEWITHSCAL','ENTERPRISEPREMIUM','ENTERPRISEPREMIUM_NOPSTNCONF','DESKLESSPACK','DESKLESSPACK','MIDSIZEPACK','LITEPACK','LITEPACK_P2','WACONEDRIVESTANDARD','WACONEDRIVEENTERPRISE','POWERAPPS_PER_USER','POWER_BI_STANDARD','POWER_BI_ADDON','POWER_BI_PRO','PROJECTCLIENT')]
        [string] $LicensePlan,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
        [string] $UserName,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
        [string] $Password,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
        [string] $AzureEnvironmentName,

    [switch]$RemoveLicense
)

#region Checking & installing MSOnline Module
[string] $ModuleName = 'MSOnline'
[string] $PkgProvider = 'NuGet'

if ( -not ((Get-Module -ListAvailable | Select-Object -ExpandProperty Name) -contains $ModuleName) ) {
    Write-Debug "Please wait for the necessary modules to install."
    if ( -not ((Get-PackageProvider -ListAvailable | Select-Object -ExpandProperty Name) -contains $PkgProvider) ) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Install-PackageProvider -Name $PkgProvider -Force -Confirm:$false
    }
    Install-Module -Name $ModuleName -Force -Confirm:$false
}
Import-Module $ModuleName
if ( -Not (Get-Module -ListAvailable -Name $ModuleName) ) {
    throw "ERROR: the PowerShell module <$ModuleName> is not available"
}  else {
    Write-Debug "INFO: The Module <$ModuleName> imported successfully."
}
#endregion Checking & installing MSOnline Module

$SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword
Connect-MsolService -Credential $credential -AzureEnvironmentName $AzureEnvironmentName

foreach ($user in (Get-MsolUser -All)) {
    if ($RemoveLicense -and $user.IsLicensed ) {
        Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName -RemoveLicenses $LicensePlan
    } elseif ( (-not $RemoveLicense) -and (-not $user.IsLicensed) ) {
        Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName -AddLicenses $LicensePlan
    }
}
Disconnect-MsolService