<#
.Synopsis
   Saves information about a Local Administrator to ITGlue.
   Version 0.2
   Author: Proserv Team - VS

.DESCRIPTION
   This script saves information about a Local Administrator to ITGlue.
   It connects to the specified VSA server to retrieve the Local Admin username and password stored in custom fields.
   The script then uses this information to update or create a corresponding record in ITGlue.

.PARAMETER ITGlueAPIEndpoint
   Specifies the API endpoint for the ITGlue service.

.PARAMETER ITGlueAPIKey
   Specifies the API key required to authenticate with the ITGlue service.

.PARAMETER VSAAddress
   Specifies the address of the VSA server.

.PARAMETER VSAUser
   Specifies the username used to authenticate with the VSA server.

.PARAMETER VSAAccessToken
   Specifies the access token used to authenticate with the VSA server.

.PARAMETER AgentId
   Specifies the ID of the agent associated with the VSA server.

.PARAMETER LocalAdminUsernameField
   Specifies the name of the custom field that stores the Local Admin username in the VSA.

.PARAMETER LocalAdminPasswordField
   Specifies the name of the custom field that stores the Local Admin password in the VSA.

.PARAMETER IgnoreCertificateErrors
   Indicates whether to ignore certificate errors when connecting to the VSA server.

.EXAMPLE
   .\Save-LocalAdminToITGlue.ps1 -VSAAddress "https://vsa.example.com" -VSAUser "username" -VSAAccessToken "access_token" -AgentId "agent_id" -ITGAPIEndpoint "https://example.itglue.com" -ITGAPIKey "API_KEY"
#>


Param
(
    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VSAAddress,

    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VSAUser,

    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $PAT,

    [Parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $AgentId,

    [Parameter(Mandatory=$false, 
        ValueFromPipelineByPropertyName = $true)]
    [string] $CFUserName = 'LocalAdminUsername',

    [Parameter(Mandatory=$false, 
        ValueFromPipelineByPropertyName = $true)]
    [string] $CFPassword = 'LocalAdminPassword',

    [parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ITGAPIEndpoint,

    [parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ITGAPIKey,

    [Parameter(Mandatory=$false)]
    [switch] $IgnoreCertificateErrors
)

#region functions
function Initialize-Module ($ModuleName)
{
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Install-Module -Name $ModuleName -Force -Confirm:$false
    }
    Import-Module $ModuleName -Force
}
#endregion functions

#region Connect to VSA Env & read Custom Fields
Initialize-Module 'VSAModule'

[securestring]$SecStringPassword = ConvertTo-SecureString $PAT -AsPlainText -Force
[pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($VSAUser, $SecStringPassword)
[hashtable] $VSAConnParams  = @{
    VSAServer   = ''
    Credential  = $Credential
}
if ($PSBoundParameters.ContainsKey('IgnoreCertificateErrors')) {
    $VSAConnParams.Add('IgnoreCertificateErrors', $IgnoreCertificateErrors)
}

[string[]]$VSAServers = $VSAAddress -split ';'
foreach ($Server in $VSAServers) {
    [string] $Address = "https://$([regex]::Matches($Server, '.+?(?=\:)').Value)"
    $VSAConnParams.VSAServer = $Address
    $VSAConnection = try { New-VSAConnection @VSAConnParams -ErrorAction Stop } catch { $null }
    if ($null -ne $VSAConnection) {
        break
    }
}
if ($null -eq $VSAConnection) {
    "ERROR: Unable to connect to the '{0}' server(s). The procedure cannot proceed." -f $VSAAddress | Write-Output
    return
}

[hashtable]$CFParams = @{
    VSAConnection = $VSAConnection
    AgentId       = $AgentId
}

[string]$CFUsernameValue = Get-VSACustomField @CFParams | Where-Object {$_.FieldName -eq $CFUserName} | Select-Object -ExpandProperty FieldValue
if ([string]::IsNullOrEmpty($CFUsernameValue) ) {
    return "ERROR: Custom Field '$CFUserName' value not set. Unable to proceed."
}

[string]$CFPasswordValue = Get-VSACustomField @CFParams | Where-Object {$_.FieldName -eq $CFPassword} | Select-Object -ExpandProperty FieldValue
if ([string]::IsNullOrEmpty($CFPasswordValue) ) {
    return "ERROR: Custom Field '$CFPassword' value not set. Unable to proceed."
}
#endregion Connect to VSA Env & read Custom Fields

#region ITGlue
Initialize-Module 'ITGlueAPI'

Add-ITGlueBaseURI -base_uri $ITGAPIEndpoint
Add-ITGlueAPIKey $ITGAPIKey

$MaxPageSize = 1000
$BIOSSerialNumber = Get-CimInstance -ClassName win32_bios | Select-Object -ExpandProperty SerialNumber


[hashtable]$ConfigAttribs = @{filter_serial_number = $BIOSSerialNumber}

[array] $TaggedResources = Get-ITGlueConfigurations @ConfigAttribs | Select-Object -ExpandProperty data # | Select-Object -Last 1

#Filter by MAC address if more than one or null configurations found.

[string[]]$MACAddresses = Get-CimInstance win32_networkadapterconfiguration | Select-Object -ExpandProperty macaddress | Where-Object { -not [string]::IsNullOrEmpty($_) } | ForEach-Object { $_.Replace(':', '-')}

#Check if ITG Resource exists
$ExistingITGRes = switch ( $TaggedResources.Count  )
{
    0 { # No configurations found by BIOS Serial number. Get all configurations and then filter them by MAC address.
        #There's limitation in the ITGlueAPI PowerShell module: the commandlet Get-ITGlueConfigurations returns max 50 objects and there's no filter by mac address.

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


if( $null -eq $ExistingITGRes ) {

    return "ERROR: No IT Glue Configurations found for the system '$($Env:COMPUTERNAME)' with BIOS Serial '$BIOSSerialNumber'"

} else {
    $OrganizationID = $ExistingITGRes.attributes.'organization-id'
    [string]$PasswordObjectName = "$($Env:COMPUTERNAME) - Local Administrator Account"

    #Check if Password record already exists for the configuration.
    $ExistingPasswordAsset = Get-ITGluePasswords -filter_organization_id $OrganizationID -filter_name $PasswordObjectName | Select-Object -ExpandProperty data

    $PlainPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($CFPasswordValue))

    #Prepare data for creating / updating existing ITG password asset
    $PasswordObject = @{
        type = 'passwords'
        attributes = @{
                name          = $PasswordObjectName
                username      = $CFUsernameValue
                password      = $PlainPassword
                resource_id   = $ExistingITGRes.Id
                resource_type = 'Configuration'
                notes         = "Local Admin Password for $($Env:COMPUTERNAME)"
        }
    }

    if( $null -ne $ExistingPasswordAsset ) {
        #Update the existing asset

        Set-ITGluePasswords -id $ExistingPasswordAsset.id -data $PasswordObject 

        Write-Output "INFO: Updating ITGlue password object '$PasswordObjectName'."
    } else {

        #Create a new Password ITGlue record
        Write-Output "INFO: Creating new ITGlue password object '$PasswordObjectName'."
        $ITGNewPassword = New-ITGluePasswords -organization_id $OrganizationID -data $PasswordObject  
    }
}