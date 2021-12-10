<#
.Synopsis
    Populates VSA Machine Summary with the Active Directory Computer description.
.DESCRIPTION
    Gets the Description attribute from the AD domain of which the computer running the script is a member.
    Downloads the VSAModule PowerShell module from github and installs it if the module folder is not found in the user's environment Module folder.
    Creates a Custom Field if it does not exist.
    The VSA Сustom Field is populated with AD Description when the VSA Asset names match the AD Computer names.   
.PARAMETER VSAAddress
    The address of the VSA server.
.PARAMETER VSAUserName
    The VSA User name. The VSA user must have permissions to create/update Agent Custom Fields.
.PARAMETER VSAUserPAT
    The VSA User access token. (VSA->System->User Security->Users->Access Tokens)
.PARAMETER FieldName
    (Optional) A VSA Custom Field to be populated with AD Computer description. (Default = ADDescription)
.PARAMETER OrgRef
    (Optional) Specifies string to filter VSA agents by an organization reference. OrgRef uniquely identifies an organization within the VSA, usually a shorten name or acronim.
.PARAMETER OverwriteExistingModule
    (Optional) Downloads the VSAModule module from github and overwrites the existing one in the user's environment Module folder.
.PARAMETER LogIt
    (Optional) Logs execution transcript to a file.
.EXAMPLE
    .\Add-ADDSDescriptionToCustomField.ps1 -VSAAddress 'https://vsaserver.example' -VSAUserName 'vsa_user' -VSAUserPAT '01e0e010-1010-1010-b101-ca1beec10efc' -OverwriteExistingModule -LogIt
    Populates  the VSA Machine Summary with the Active Directory Computer description. Overwrites existing VSAModule if found. 
.EXAMPLE
    .\Add-ADDSDescriptionToCustomField.ps1 -VSAAddress 'https://vsaserver.example' -VSAUserName 'vsa_user' -VSAUserPAT '01e0e010-1010-1010-b101-ca1beec10efc' -OrgRef 'kserver' -FieldName 'MyField'
    Filters VSA Agents by OrgRef. Populates specified VSA Custom Field with the Active Directory Computer description.
.NOTES
    Version 0.1
    Requires:
        AD membership for the computer running the script.
        The ActiveDirectory PowerShell module installed on the computer running the script (usually a domain controller).
        Internet connection to download VSAModule from GitHub if the module was not installed beforehand.
        Proper permissions to execute the script.
   
    Author: Proserv Team - VS

#>
param (
    [parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName = $true)]
    [ValidateScript(
            {if ($_ -match '^http(s)?:\/\/([\w.-]+(?:\.[\w\.-]+)+|localhost)$') {$true}
            else {Throw "$_ is an invalid address. Enter a valid address that begins with https://"}}
            )]
    [string] $VSAAddress,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $VSAUserName,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $VSAUserPAT,

    [parameter(Mandatory=$false)]
    [string] $FieldName = "ADDescription",

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $OrgRef,

    [parameter(Mandatory=$false)]
    [switch] $OverwriteExistingModule,

    [parameter(Mandatory=$false)]
    [switch] $LogIt
)

#region check/start transcript
[string]$Pref = 'Continue'
if ( $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
    $LogFile = "$ScriptPath\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

#region Checking & installing VSA Module
function Get-ModuleToFolder {
    param (
        [string] $URL,
        [string] $ArchiveName,
        [string] $ModuleInstallFolder
    )

    Write-Host "Downloading from GitHub: $URL" -ForegroundColor Cyan
    $TempArchiveFile = Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $ArchiveName

    Invoke-WebRequest $URL -OutFile $TempArchiveFile
    Unblock-File -Path $TempArchiveFile

    [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory( $TempArchiveFile, $ModuleInstallFolder )

    #perform cleanup
    Remove-Item -Path $TempArchiveFile -Force -ErrorAction SilentlyContinue

    Write-Host "Module" -NoNewline
    Write-Host "`t$moduleName" -ForegroundColor Green -NoNewline
    Write-Host "`tinstalled into`t" -NoNewline
    Write-Host $ModuleInstallFolder -ForegroundColor Green -NoNewline
    Write-Host "`tFolder"
}

function Install-GithubModule
{
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $ArchiveName,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ModuleFolder,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [uri] $URIBase = 'https://github.com/Kaseya-Automation-Team/Kaseya-Automation-Team/raw/main/Public/archive',

        [Parameter(Mandatory=$false)]
        [Switch] $OverwriteExistingModule
    )
    
    # Name for the folder where the module is installed
    if ( [string]::IsNullOrEmpty($ModuleFolder) ) {
        $ModuleFolder = $([io.path]::GetFileNameWithoutExtension($ArchiveName))
    }

    $ModuleName = Split-Path $ModuleFolder -leaf

    $URL = $URIBase, $ArchiveName -join '/' 
     
    #region check if module exists
        #region check if module folder already created
    $separator = [IO.Path]::PathSeparator
    $ProfileModulePath = $env:PSModulePath.Split($separator)[0]
    if ( -not (Test-Path $ProfileModulePath) ) {
        New-Item -ItemType Directory -Path $ProfileModulePath
    }
        #endregion check if module folder already created
    $ModuleInstallFolder = Join-Path -Path $ProfileModulePath -ChildPath $ModuleName
    [bool] $FolderExists = Test-Path $ModuleInstallFolder

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if ($OverwriteExistingModule) {
        $Ovr = '1'
    } else {$Ovr = '0'}
    [int] $State = [convert]::ToInt32( $([string]([int]$FolderExists) + $Ovr  ), 2 )
    switch ($State)
    {
        {$_ -le 1} { #The module folder does not exist
            Get-ModuleToFolder -URL $URL -ArchiveName $ArchiveName -ModuleInstallFolder $ModuleInstallFolder
        }
        2 { #The module folder exists. Not overwrite
            break
        }
        3 { #The module folder exists. Overwrite
            Write-Host "The module folder" -NoNewline
            Write-Host "`t$ModuleInstallFolder" -ForegroundColor Yellow  -NoNewline
            Write-Host "`texists." -NoNewline
            Write-Host "`t Removing" -ForegroundColor Red
            Remove-Item -Path $ModuleInstallFolder -Recurse -Force
            Get-ModuleToFolder -URL $URL -ArchiveName $ArchiveName -ModuleInstallFolder $ModuleInstallFolder
        }
    }
    #endregion check if module exists
    return $ModuleInstallFolder
}
#endregion Checking & installing VSA Module

Clear-Host
Write-host "One moment, please`n"
$ModuleName  = "VSAModule"
$ArchiveName = "$ModuleName.zip"

$InstallModuleParams = @{ ArchiveName = $ArchiveName }
if($OverwriteExistingModule) {$InstallModuleParams.Add('OverwriteExistingModule', $true)}
$ModulePath  = Install-GithubModule @InstallModuleParams

Import-Module "$ModulePath\$ModuleName.psm1" -Force
Import-Module ActiveDirectory

if ( (Get-Module -ListAvailable -Name $ModuleName) -and (Get-Module -ListAvailable -Name ActiveDirectory)) {
    # Prepare VSA connection credentials
    [securestring]$secStringPassword = ConvertTo-SecureString $VSAUserPAT -AsPlainText -Force
    [pscredential]$SourceCred = New-Object System.Management.Automation.PSCredential ($VSAUserName, $secStringPassword)

    #region Create connection objects
    $VSAConnParams = @{
                        VSAServer     = $VSAAddress
                        Credential    = $SourceCred
                      }
    
    Write-host "Connecting to the VSA Environment`n"
    $VSAConnection = New-VSAConnection @VSAConnParams
    #endregion Create connection objects

    [array]$SourceCustomFields = Get-VSACustomFields -VSAConnection $VSAConnection

    #Create the field if needed
    if ( (0 -eq $SourceCustomFields.Count) -or ( -not ($SourceCustomFields | Select-Object -ExpandProperty FieldName).Contains($FieldName) ) ) {
        Add-VSACustomField -VSAConnection $VSAConnection -FieldName $FieldName -FieldType string
    }
    #region Populate Custom Fields Values
    $SourceAgents = Get-VSAAgent -VSAConnection $VSAConnection
    if ( -not [string]::IsNullOrEmpty($OrgRef)) {
        $SourceAgents = $SourceAgents | Where-Object {$_.AgentName -match $OrgRef}
    }
    Foreach( $Agent in $SourceAgents ) {
        $ComputerName = ($Agent.AgentName).split('.')[0]
        [string] $Info = "Processing Agent $($Agent.AgentID). Computer Name: $ComputerName"
        $Agent.AgentName | Write-Debug
        Write-Host $Info
        [string] $Description = try {Get-ADComputer $ComputerName -Properties Description  -ErrorAction Stop | Select-Object -ExpandProperty Description} catch {$null}
        if ( -not [string]::IsNullOrEmpty($Description) ) {
            [hashtable]$Params = @{
                AgentID       = $Agent.AgentID
                FieldName     = $FieldName
                FieldValue    = $Description
                VSAConnection = $VSAConnection
            }
            Write-Host "$ComputerName. Set description:" -NoNewline
            Write-Host "`t$Description"  -ForegroundColor Green
            Update-VSACustomField @Params
        }
    }
    
    #endregion Populate Custom Fields Values
} #if (Get-Module -ListAvailable -Name $ModuleName)
else {
    if ( -not (Get-Module -ListAvailable -Name $ModuleName) ) {
        Write-Host "Module" -ForegroundColor Yellow -NoNewline
        Write-Host "`t$ModuleName" -ForegroundColor Red -NoNewline
        Write-Host "`tis not available" -ForegroundColor Yellow
    }
    if ( -not (Get-Module -ListAvailable -Name ActiveDirectory) ) {
        Write-Host "Module" -ForegroundColor Yellow -NoNewline
        Write-Host "`tActiveDirectory" -ForegroundColor Red -NoNewline
        Write-Host "`tis not available" -ForegroundColor Yellow
    }
}
#region check/stop transcript
if ( $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript