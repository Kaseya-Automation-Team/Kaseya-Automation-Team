<#
.Synopsis
    Exchange 365 add/remove users from distribution list.
.PARAMETER Path
    The file system path to manage permission.
.PARAMETER LicensePlan
    The license plan. Valid values are: 'O365_BUSINESS','SMB_BUSINESS','OFFICESUBSCRIPTION','O365_BUSINESS_ESSENTIALS','SMB_BUSINESS_ESSENTIALS','O365_BUSINESS_PREMIUM','SMB_BUSINESS_PREMIUM','SPB','SPE_E3','SPE_E5','SPE_E3_USGOV_DOD','SPE_E3_USGOV_GCCHIGH','INFORMATION_PROTECTION_COMPLIANCE','IDENTITY_THREAT_PROTECTION','IDENTITY_THREAT_PROTECTION_FOR_EMS_E5','M365_F1','SPE_F1','FLOW_FREE','MCOEV','MCOEV_DOD','MCOEV_FACULTY','MCOEV_GOV','MCOEV_GCCHIGH','MCOEVSMB_1','MCOEV_STUDENT','MCOEV_TELSTRA','MCOEV_USGOV_DOD','MCOEV_USGOV_GCCHIGH','WIN_DEF_ATP','CRMPLAN2','CRMSTANDARD','IT_ACADEMY_AD','TEAMS_FREE','ENTERPRISEPREMIUM_FACULTY','ENTERPRISEPREMIUM_STUDENT','EQUIVIO_ANALYTICS','ATP_ENTERPRISE','STANDARDPACK','STANDARDWOFFPACK','ENTERPRISEPACK','DEVELOPERPACK','ENTERPRISEPACK_USGOV_DOD','ENTERPRISEPACK_USGOV_GCCHIGH','ENTERPRISEWITHSCAL','ENTERPRISEPREMIUM','ENTERPRISEPREMIUM_NOPSTNCONF','DESKLESSPACK','DESKLESSPACK','MIDSIZEPACK','LITEPACK','LITEPACK_P2','WACONEDRIVESTANDARD','WACONEDRIVEENTERPRISE','POWERAPPS_PER_USER','POWER_BI_STANDARD','POWER_BI_ADDON','POWER_BI_PRO' and 'PROJECTCLIENT'
.PARAMETER UserPrincipalName
    Azure user principal name.
.PARAMETER Password
    Azure user password.
.PARAMETER DistributionListName
    Mail Distribution List Name
.PARAMETER MailAddressList
    Mail Address List
.PARAMETER RemoveFromList
    (Optional) Remove maill addresses from the list.
.EXAMPLE
    .\Set-Exchange365DistributionList.ps1 -UserPrincipalName YourAzureUserName -Password YourAzureUserPassword -DistributionListName YourDistributionListName -MailAddressList mail1@domain.mail, mail2@domain.mail
.NOTES
    Version 0.1   
     Requires:
        Proper permissions to install PowerShell modules and manage Exchange 365.
    Author: Proserv Team - VS
#>
param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
        [string] $UserPrincipalName,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
        [string] $Password,
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
        [string] $DistributionListName,

    [parameter(Mandatory=$true)]
        [string[]] $MailAddressList,

    [switch]$RemoveFromList
)

#region Checking & installing ExchangeOnlineManagement Module
[string] $ModuleName = 'ExchangeOnlineManagement'
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
#endregion Checking & installing ExchangeOnlineManagement Module


$SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($UserPrincipalName, $SecurePassword)
Connect-ExchangeOnline -Credential $Credential

$CurrentMembers = Get-DistributionGroupMember -Identity $DistributionListName | Select-Object -ExpandProperty PrimarySmtpAddress

foreach ($Address in $MailAddressList) {
    if ( $RemoveFromList -and ($CurrentMembers -contains $Address)) 
    {
        Remove-DistributionGroupMember -Identity $DistributionListName -Member $Address -Confirm:$false
    }
    elseif ( (-not $RemoveFromList) -and ($CurrentMembers -notcontains $Address) )
    {
        Add-DistributionGroupMember -Identity $DistributionListName -Member $Address
    }
}
# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
