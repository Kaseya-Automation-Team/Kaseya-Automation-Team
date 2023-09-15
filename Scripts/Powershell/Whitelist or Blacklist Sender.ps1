param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
        [string] $UserPrincipalName,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
        [string] $Password,
    
    [parameter(Mandatory=$true)]
        [string[]] $MailAddressList,

    [switch]$RemoveFromList
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
Import-Module ImportExcel
if ( -Not (Get-Module -ListAvailable -Name $ModuleName) ) {
    throw "ERROR: the PowerShell module <$ModuleName> is not available"
}  else {
    Write-Debug "INFO: The Module <$ModuleName> imported successfully."
}
#endregion Checking & installing MSOnline Module


$SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($UserPrincipalName, $SecurePassword)
Connect-ExchangeOnline -Credential $Credential


foreach ($Address in $MailAddressList) {

if ( $RemoveFromList) 
    {
        Set-HostedContentFilterPolicy -Identity Default -BlockedSenders @{Add = $Address}
    }
    else {

    Set-HostedContentFilterPolicy -Identity Default -AllowedSenders @{Add=$Address}
    
    }
}


# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false