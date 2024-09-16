<#
.Synopsis
    Clears Specified Custom Field in a Kaseya Virtual System Administrator (VSA) environment.
.DESCRIPTION
    This PowerShell script downloads the VSAModule module from GitHub and installs it in the user's environment Module folder if it does not exist already.
    The script clears the specified existing custom fields in the VSA.
.PARAMETER VSAServerAddress
    The address of the Kaseya Virtual System Administrator (VSA) server.
.PARAMETER VSAUserName
    The name of the user account with permissions to create Agent Custom Fields in the destination VSA.
.PARAMETER VSAUserPAT
    The VSA user's access token.
    This can be found in the VSA system under VSA > System > User Security > Users > Access Tokens.
.PARAMETER Field
    The VSA Custom Field to be cleared.
.PARAMETER IgnoreCertificateErrors
    Indicates whether to allow self-signed certificates. Default is false.
.EXAMPLE
    .\Clear-CustomField.ps1 -VSAServerAddress 'https://vsaserver.example' -VSAUserName 'user' -VSAUserPAT '01e0e010-1010-1010-b101-ca1beec10efc' -Field 'The_Field_To_Clear'
.NOTES
    Version 0.1.1
    Requires:
        An internet connection to download the VSAModule from GitHub if the module is not already installed.
        Proper permissions to install the VSAModule and execute the script are also required.

    Author: Proserv Team - VS
#>

param (
    [parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName = $true)]
    [ValidateScript({
        if ($_ -match '^http(s)?:\/\/([\w.-]+(?:\.[\w\.-]+)+|localhost)\/?$') { $true }
        else { Throw "$_ is an invalid address. Enter a valid address that begins with https://"; }
    })]
    [string] $VSAAddress,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $VSAUserName,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $VSAUserPAT,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $Field,

    [parameter(Mandatory=$false)]
    [switch]$IgnoreCertificateErrors
)

#region Installing & loading VSA Module
$ModuleName = 'VSAModule'
Write-Host "Preparing module '$ModuleName'..."

# Check current installed version
$CurrentVersion = try {
    (Get-Module -Name $ModuleName -ListAvailable -ErrorAction Stop | Sort-Object -Property Version -Descending | Select-Object -ExpandProperty Version -First 1).ToString()
} catch {
    Write-Host "'$ModuleName' not detected on the host $($Env:COMPUTERNAME)." 
    $null
}

if (-not $CurrentVersion) {
    # Install module if not present
    Write-Host "Trying to install '$ModuleName' from GitHub."
    try {
        Install-Module -Name $ModuleName -Force -ErrorAction Stop
    } catch {
        throw "ERROR: Failed to install '$ModuleName' from GitHub!"
    }
} else {
    # Get the latest version available in the repository
    $latestVersion = (Find-Module -Name $ModuleName | Sort-Object -Property Version -Descending | Select-Object -ExpandProperty Version -First 1).ToString()
    
    # Use System.Version for better version comparison
    $currentVerObj = [System.Version]$CurrentVersion
    $latestVerObj = [System.Version]$latestVersion
    if ($currentVerObj -lt $latestVerObj) {
        Write-Host "Trying to update '$ModuleName' from GitHub."
        try {
            Update-Module -Name $ModuleName -Force -ErrorAction Stop
        } catch {
            throw "ERROR: Failed to update '$ModuleName' from GitHub!"
        }
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

#region Establish Connection
[securestring]$secStringPassword = ConvertTo-SecureString $VSAUserPAT -AsPlainText -Force
[pscredential]$VSACred = New-Object System.Management.Automation.PSCredential ($VSAUserName, $secStringPassword)

$VSAConnParams = @{
    VSAServer = $VSAAddress
    Credential = $VSACred
}
if ($PSBoundParameters.ContainsKey('IgnoreCertificateErrors')) {
    $VSAConnParams.Add('IgnoreCertificateErrors', $IgnoreCertificateErrors)
}

Write-host "One moment, please`n" 
Write-host "Connecting to the VSA Environment at`n$VSAAddress"
$VSAConnection = New-VSAConnection @VSAConnParams

if ([string]::IsNullOrEmpty($VSAConnection.Token)) {
    throw "ERROR: Could not establish connection to the VSA Server at $VSAAddress"
} else {
    Write-Host "$(Get-Date)`: Connection to '$VSAAddress' established.`n" -ForegroundColor Green
}
#endregion Establish Connection

#region Clear Custom Fields
Write-Host "Fetching Custom Fields information"
[array]$ExistingCustomFields = Get-VSACustomFields -VSAConnection $VSAConnection
if (($ExistingCustomFields | Select-Object -ExpandProperty FieldName) -notcontains $Field) {
    Throw "WARNING: No field $($Field) found in the environment!"
}

Write-Host "Fetching Agents"
[string[]]$AgentIds = Get-VSAAgent -VSAConnection $VSAConnection | Select-Object -ExpandProperty AgentId

[int]$totalAgents = $AgentIds.Count
[int]$processed = 0
if ( $processed -lt $totalAgents ) {
    
    foreach ($Id in $AgentIds) {
        Update-VSACustomField -VSAConnection $VSAConnection -AgentID $Id -FieldName $Field -FieldValue "" | Out-Null
        $processed++
        $percentComplete = ($processed / $totalAgents) * 100
        Write-Progress -Activity "Clearing Custom Field '$Field'..." -Status "Progress" -PercentComplete $percentComplete
    }
}
#endregion Clear Custom Custom Fields
Write-Host "Done!"