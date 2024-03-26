<#
.Synopsis
   Creates a new Local Administrator and saves information to VSA Custom Field.
   Version 0.1
   Author: Proserv Team - VS
#>
Param
(
    [Parameter(Mandatory=$false)]
    [string] $NameTemplate = 'Admin',

    [Parameter(Mandatory=$false)]
    [int] $PasswordLength = 12,

    [Parameter(Mandatory=$false)]
    [string] $CFName = 'LocalAdmin',

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $VSAAddress,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $VSAUser,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $PAT,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $AgentId,

    [parameter(Mandatory=$false)]
    [switch] $IgnoreCertificateErrors
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

Prepare-Module 'VSAModule'

#region Detect Available VSA Server & Connect to it
[securestring]$secStringPassword = ConvertTo-SecureString $PAT -AsPlainText -Force
[pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($VSAUser, $secStringPassword)
[hashtable] $VSAConnParams  = @{
    VSAServer   = ''
    Credential  = $Credential
}
if($PSBoundParameters.ContainsKey('IgnoreCertificateErrors')) {
    $VSAConnParams.Add('IgnoreCertificateErrors', $IgnoreCertificateErrors)
}

[string[]]$VSAServers = $VSAAddress -split ';'
foreach ( $Server in $VSAServers  ) {
    [string] $Address = "https://$([regex]::Matches( $Server, '.+?(?=\:)' ).Value)"
    $VSAConnParams.VSAServer = $Address
    $VSAConnection = try { New-VSAConnection @VSAConnParams -ErrorAction Stop } catch {$null}
    if ( $null -ne $VSAConnection ) {
        break
    }
}
if ( $null -eq $VSAConnection ) {
    "ERROR: Unable to connect to the '{0}' server(s). The procedure cannot proceed." -f $VSAAddress | Write-Output
    return
}
#endregion Detect Available VSA Server & Connect to it
[string]$CFValue = Get-VSACustomField -VSAConnection $VSAConnection -AgentId $AgentId | Where-Object {$_.FieldName -eq $CFName} | Select-Object -ExpandProperty FieldValue
if ( -not [string]::IsNullOrEmpty($CFValue)) {
    "ATTENTION: No user was created because the '{0}' Custom Field is not empty. Before proceeding, ensure that the '{0}' field is cleared and any corresponding local user is removed." -f $CFName | Write-Output
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
        #region Fill CF with credentials

        [hashtable]$CFParams = @{
            VSAConnection = $VSAConnection
            FieldName     = $CFName
        }

        [string[]]$ExistingCFs = Get-VSACustomField -VSAConnection $VSAConnection | Select-Object -ExpandProperty FieldName
        if ( $ExistingCFs -notcontains $CFName) {
            $null = New-VSACustomField @CFParams -FieldType string
        }

        [string]$CFValue = Get-VSACustomField -VSAConnection $VSAConnection -AgentId $AgentId | Where-Object {$_.FieldName -eq $CFName} | Select-Object -ExpandProperty FieldValue
        if ( [string]::IsNullOrEmpty($CFValue)) {
            $Bytes = [System.Text.Encoding]::UTF8.GetBytes("$UserName`n$PlainPassword");
            $FieldValue =[Convert]::ToBase64String($Bytes);
            $null = Update-VSACustomField @CFParams -FieldValue $FieldValue -AgentID $AgentId
            "INFO: User's credentials saved to the '{0}' field" -f $CFName | Write-Output
        }
        #endregion Fill CF with credentials
    };
    #endregion #region Create new user and add to Local Admins
}