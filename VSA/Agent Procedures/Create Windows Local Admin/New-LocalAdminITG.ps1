<#
.Synopsis
   Creates a new Local Administrator and saves information to ITGlue.
   Version 0.1
   Author: Proserv Team - VS
#>
Param
(
    [Parameter(Mandatory=$false)]
    [string] $NameTemplate = 'Admin',

    [Parameter(Mandatory=$false)]
    [int] $PasswordLength = 12,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $APIEndpoint,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $APIKey
)
Add-Type -AssemblyName System.Web;

#region function Prepare-Module
function Prepare-Module ($ModuleName)
{
    if ( -not (Get-Module -ListAvailable -Name $ModuleName ) ) {
        Install-Module -Name $ModuleName -Force -Confirm:$false
    }
    Import-Module $ModuleName -Force
}
#endregion function Prepare-Module

Prepare-Module 'ITGlueAPI'

#region Connect to ITGlue
Add-ITGlueBaseURI -base_uri $APIEndpoint
Add-ITGlueAPIKey $APIKey
#endregion Connect to ITGlue

#region Get ITGGlue Configuration to stroe credentials for a new user
$MaxPageSize = 1000
$BIOSSerialNumber = Get-CimInstance -ClassName win32_bios | Select-Object -ExpandProperty SerialNumber
#There's limitation in the ITGlueAPI PowerShell module: the commandlet Get-ITGlueConfigurations returns max 50 objects and there's no filter by mac address.  

[hashtable]$ConfigAttribs = @{filter_serial_number = $BIOSSerialNumber}

[array] $TaggedResources = Get-ITGlueConfigurations @ConfigAttribs | Select-Object -ExpandProperty data # | Select-Object -Last 1

#Filter by MAC address if more than one or null configurations found.
[string[]]$MACAddresses = Get-CimInstance win32_networkadapterconfiguration | Select-Object -ExpandProperty macaddress | Where-Object { -not [string]::IsNullOrEmpty($_) } | ForEach-Object { $_.Replace(':', '-')}

$ExistingITGRes = switch ( $TaggedResources.Count  )
{
    0 { # No configurations found by BIOS Serial number. Get all configurations and then filter them by MAC address.
        [hashtable]$ConfigAttribs = @{ page_size = $MaxPageSize }
        Get-ITGlueConfigurations @ConfigAttribs | Select-Object -ExpandProperty data | Where-Object { $MACAddresses.Contains($_.attributes.'mac-address') | Select-Object -Last 1 }
    }
    1 { # The only configuration found by BIOS Serial number
        $TaggedResources[0]
    }
    default { #More than one configuration found. Filter them by MAC address.
        [array] $MACFiltered = $TaggedResources | Where-Object { $MACAddresses.Contains($_.attributes.'mac-address')}
        
        If ( 1 -le $MACFiltered.Count ) { # MAC filtering did return configurations
            $TaggedResources = $MACFiltered
        }
        $TaggedResources | Select-Object -Last 1
    }
}
#endregion Get ITGGlue Configuration to stroe credentials for a new user

if( $null -eq $ExistingITGRes ) {

    "No IT Glue Configurations found for '{0}' with BIOS Serial '{1}'" -f $BIOSSerialNumber, $($Env:COMPUTERNAME) | Write-Output

} else {
    $OrganizationID = $ExistingITGRes.attributes.'organization-id'
    [string]$PasswordObjectName = "$($Env:COMPUTERNAME) - Local Administrator Account"

    #Check if Password record already exists for the configuration.
    $ExistingPasswordAsset = Get-ITGluePasswords -filter_organization_id $OrganizationID -filter_name $PasswordObjectName | Select-Object -ExpandProperty data
    if( $null -ne $ExistingPasswordAsset ) {
        #Write-Output "Updating Local Administrator Password"
        #$ITGNewPassword = Set-ITGluePasswords -id $ExistingPasswordAsset.id -data $PasswordObject
        "ATTENTION: No user was created because '{0}' resource found in ITGlue. Before proceeding, ensure that the '{0}' ITGlue resource and any corresponding local user is removed." -f $PasswordObjectName | Write-Output
    } else {

        #region Create new user and add to Local Admins
        [string[]]$Names = Get-LocalUser | Select-Object -ExpandProperty Name;
        do {
            $UserName = '{0}{1}' -f $NameTemplate, $(((100..999) | Get-Random).ToString())
        } until ($Names -notcontains $UserName);

        do {
            $PlainPassword = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, 1)
        } until ($PlainPassword -match '\d');

        $SecurePassword = ConvertTo-SecureString $PlainPassword -AsPlainText -Force;
        $user = New-LocalUser -Name $UserName -Password $SecurePassword;
    
        if ( $null -eq $user) {
            'ERROR: Failed to create user {0} on the host {1}' -f $UserName, $env:COMPUTERNAME | Write-Output;
        } else {
            Add-LocalGroupMember -SID 'S-1-5-32-544' -Member $user;
            'INFO: User {0} created on the host {1}' -f $UserName, $env:COMPUTERNAME | Write-Output;
            
            #region add credentials to ITGlue
            
            $PasswordObject = @{
                type = 'passwords'
                attributes = @{
                        name          = $PasswordObjectName
                        username      = $UserName
                        password      = $PlainPassword
                        resource_id   = $ExistingITGRes.Id
                        resource_type = 'Configuration'
                        notes         = "Local Admin Password for $($Env:COMPUTERNAME)"
                }
            }
             #Create a new Password ITGlue record
            Write-Output "Creating new Local Administrator credentials to ITGlue"
            $ITGNewPassword = New-ITGluePasswords -organization_id $OrganizationID -data $PasswordObject  
        }
        #endregion Create new user and add to Local Admins
    }  
}