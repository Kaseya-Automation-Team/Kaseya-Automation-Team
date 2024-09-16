<#
.Synopsis
   Creates a new Local Administrator and saves information to VSA Custom Fields.
.DESCRIPTION
   This script creates a new Local Administrator account on the target system and saves the username and password information to specified VSA Custom Fields.
   It connects to the VSA server, generates a unique username and password, and then sets them for the Local Administrator account. The script also updates the specified Custom Fields in the VSA with the newly created username and password.
   
   The script supports the following parameters:
   .PARAMETER UserNameLength
        Specifies the length of the generated username. Default is 16 characters.
   .PARAMETER PasswordLength
        Specifies the length of the generated password. Default is 16 characters.
   .PARAMETER CFUserName
        Specifies the name of the Custom Field where the username will be stored in the VSA. Default is 'LocalAdminUsername'.
   .PARAMETER CFPassword
        Specifies the name of the Custom Field where the password will be stored in the VSA. Default is 'LocalAdminPassword'.
   .PARAMETER VSAAddress
        Specifies the address of the VSA server.
   .PARAMETER VSAUser
        Specifies the username for connecting to the VSA server.
   .PARAMETER PAT
        Specifies the personal access token for authentication.
   .PARAMETER AgentId
        Specifies the ID of the agent in the VSA.
   .PARAMETER IgnoreCertificateErrors
        Indicates whether to ignore certificate errors when connecting to the VSA server.

.NOTES
   Version 0.3
   Author: Proserv Team - VS
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
    [ValidateRange(1, 20)]
    [int] $UsernameLength = 16,

    [Parameter(Mandatory=$false, 
        ValueFromPipelineByPropertyName = $true)]
    [int] $PasswordLength = 16,

    [Parameter(Mandatory=$false, 
        ValueFromPipelineByPropertyName = $true)]
    [string] $CFUserName = 'LocalAdminUsername',

    [Parameter(Mandatory=$false, 
        ValueFromPipelineByPropertyName = $true)]
    [string] $CFPassword = 'LocalAdminPassword',

    [Parameter(Mandatory=$false)]
    [switch] $IgnoreCertificateErrors
)

Add-Type -AssemblyName System.Web;

#region functions
#region Installing & loading VSA Module
$ModuleName = 'VSAModule'

# Check current installed version
$CurrentVersion = try {
    (Get-Module -Name $ModuleName -ListAvailable -ErrorAction Stop | Sort-Object -Property Version -Descending | Select-Object -ExpandProperty Version -First 1).ToString()
} catch {
    $null
}

if (-not $CurrentVersion) {
    # Install module if not present
    Install-Module -Name $ModuleName -Force
} else {
    # Get the latest version available in the repository
    $latestVersion = (Find-Module -Name $ModuleName | Sort-Object -Property Version -Descending | Select-Object -ExpandProperty Version -First 1).ToString()
    if ($CurrentVersion -lt $latestVersion) {
        # Update the module if a newer version is available
        Update-Module -Name $ModuleName -Force
        $CurrentVersion = $latestVersion
    }
}

# Import the module specifying the version
try {
    Import-Module -Name $ModuleName -RequiredVersion $CurrentVersion -Force -ErrorAction Stop
} catch {
    throw "Failed to import module '$ModuleName' version '$CurrentVersion'."
}
#endregion Installing & loading VSA Module

function New-UniqueUsername {
    param(
        [ValidateRange(1, 20)]
        [int]$MaxLength = 20
    )

    $FirstCharacter = [string]::Empty
    # First char should not be first char of the reserved words
    while ([string]::IsNullOrEmpty($FirstCharacter)) {
        $FirstCharacter = [char]$(Get-Random -InputObject ((66..90) + (98..122) | Where-Object { $_ -notin @('C','L','N','P') }))
    }

    $InvalidCharCodes = @(0x20, 0x2F, 0x5C, 0x3A, 0x2A, 0x3F, 0x22, 0x3C, 0x3E, 0x7C)

    $RestOfUsername = -join ((1..$($MaxLength - 1)) | ForEach-Object {
        do {
            $RandomCharCode = Get-Random -InputObject ((48..57) + (65..90) + (97..122))
        } while ($InvalidCharCodes -contains $RandomCharCode)
        [char]$RandomCharCode
    })

    [string]$Username = '{0}{1}' -f $FirstCharacter, $RestOfUsername

    return $Username
}


function Set-CustomFieldValue {
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $CFName,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $CFValue,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId
    )

    [hashtable]$CFParams = @{
        VSAConnection = $VSAConnection
    }
    [string[]]$ExistingCFs = Get-VSACustomField @CFParams | Select-Object -ExpandProperty FieldName
    if ($ExistingCFs -notcontains $CFName) {
        $null = New-VSACustomField @CFParams -FieldName $CFName -FieldType string
    }

    $CFParams.Add('AgentId', $AgentId)
    $CFParams.Add('FieldName', $CFName)
    $CFParams.Add('FieldValue', $CFValue)
    Update-VSACustomField @CFParams | Out-Null

    "INFO: A new value set to the Custom Field '$CFName'" | Write-Output    
}
#endregion functions

#region Detect Available VSA Server & Connect to it
[securestring]$SecStringPassword = ConvertTo-SecureString $PAT -AsPlainText -Force
[pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($VSAUser, $SecStringPassword)
[hashtable] $VSAConnParams  = @{
    VSAServer   = ''
    Credential  = $Credential
    ErrorAction = 'Stop'
}
if ($PSBoundParameters.ContainsKey('IgnoreCertificateErrors')) {
    $VSAConnParams.Add('IgnoreCertificateErrors', $IgnoreCertificateErrors)
}

[string[]]$VSAServers = $VSAAddress -split ';'
foreach ($Server in $VSAServers) {
    #Obtain the server address removing protocol and port number if specified
    [string] $Address = "https://$([regex]::Match($Server, "^(?:https?://)?([^/:]+)").Groups[1].Value)"
    $VSAConnParams.VSAServer = $Address
    "Trying to connect to '$Address'" | Write-Output
    $VSAConnection = try { New-VSAConnection @VSAConnParams } catch { $null }
    if ($null -ne $VSAConnection) {
        Write-Output "Connection to '$Address': OK"
        break
    } else {
        "Unable to connect to '$Address' using the user's '$VSAUser' credentials!" | Write-Output
    }
}
if ($null -eq $VSAConnection) {
    "ERROR: Unable to connect to the '{0}' server(s) using the user's '$VSAUser' credentials! The procedure cannot proceed." -f $VSAAddress | Write-Output
    return
}
#endregion Detect Available VSA Server & Connect to it

#region New Password
do {
    $PlainTextPassword = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, 1)
} until ($PlainTextPassword -match '\d');
$SecurePassword = ConvertTo-SecureString $PlainTextPassword -AsPlainText -Force;
#endregion New Password

[hashtable]$CFParams = @{
    VSAConnection = $VSAConnection
    AgentId       = $AgentId
}

[string]$CFUsernameValue = Get-VSACustomField @CFParams | Where-Object {$_.FieldName -eq $CFUserName} | Select-Object -ExpandProperty FieldValue

if ( [string]::IsNullOrEmpty($CFUsernameValue) ) {
    # Create a new user & add to Local Admins

    [string[]] $ExistingUserNames = Get-LocalUser | Select-Object -ExpandProperty Name;
    [string]   $NewUsername = do {
        New-UniqueUsername -MaxLength $UserNameLength
    } until ($ExistingUserNames -notcontains $NewUsername);
    
    $UserAccount = New-LocalUser -Name $NewUsername -Password $SecurePassword;
    
    if ($null -eq $UserAccount) {
        return "ERROR: Failed to create user '$NewUsername' on the system $($env:COMPUTERNAME)"
    } else {
        Add-LocalGroupMember -SID 'S-1-5-32-544' -Member $UserAccount;
        "INFO: User '$NewUsername' created on the system $($env:COMPUTERNAME)" | Write-Output;

        # Save new username to CF
        $CFParams.Add('CFName', $CFUserName)
        $CFParams.Add('CFValue', $NewUsername)

        Set-CustomFieldValue @CFParams

        # Save new password to CF
        $Bytes = [System.Text.Encoding]::UTF8.GetBytes($PlainTextPassword);
        $NewPassword = [Convert]::ToBase64String($Bytes);
        $CFParams = @{
            VSAConnection = $VSAConnection
            AgentId       = $AgentId
            CFName        = $CFPassword
            CFValue       = $NewPassword
        }

        Set-CustomFieldValue @CFParams
    }
} else {

    # Reset password for the existing user
    $UserAccount = Get-LocalUser -Name $CFUsernameValue
    if ( $null -eq $UserAccount ) {
        Write-Output "WARNING: the Custom Field '$CFUserName' contains username '$CFUsernameValue'. However, no user '$CFUsernameValue' was found on the system $($env:COMPUTERNAME)!"
        return
    } else {
        $UserAccount | Set-LocalUser -Password $SecurePassword
        Write-Output "INFO: the Custom Field '$CFUserName' already contains username '$CFUsernameValue'. Updating password for user '$CFUsernameValue' on the system $($env:COMPUTERNAME)"
    }
    # Save new password to CF
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($PlainTextPassword);
    $NewPassword = [Convert]::ToBase64String($Bytes);
    $CFParams = @{
        VSAConnection = $VSAConnection
        AgentId       = $AgentId
        CFName        = $CFPassword
        CFValue       = $NewPassword
    }

    Set-CustomFieldValue @CFParams
}