<#
.Synopsis
    Synchronizes Custom Fields between source and destination VSA.
.DESCRIPTION
    Downloads the VSAModule PowerShell module from github and installs it if the module folder is not found in the user's environment Module folder.
    Compares Custom Fields by name in Source and Destination VSA instances.
    Missed fields are created in the destination VSA.
    The source Custom Fields with their values are collected and bound to the Machine Name.
    Corresponding destination Assets are found by matching the Machine Name.
    Destination Assets' Custom fields are populated with the values collected at the source.
.PARAMETER SourceVSAAddress
    The address of the source VSA server.
.PARAMETER DestinationVSAAddress
    The address of the destination VSA server.
.PARAMETER SourceVSAUserName
    The source VSA User name. The user must have permissions to read Agent Custom Fields.
.PARAMETER DestinationVSAUserName
    The destination VSA User name. The user must have permissions to create/update Agent Custom Fields.
.PARAMETER SourceUserPAT
    The source VSA User access token. (VSA->System->User Security->Users->Access Tokens)
.PARAMETER DestinationUserPAT
    The destination VSA User access token. (VSA->System->User Security->Users->Access Tokens)
.PARAMETER OverwriteExistingModule
    (Optional) Downloads the VSAModule module from github and overwrites the existing one in the user's environment Module folder.
.PARAMETER LogIt
    (Optional) Logs execution transcript to a file.
.EXAMPLE
    .\Sync-CustomFields.ps1 -SourceVSAAddress 'https://source.example' -SourceVSAUserName 'user1' -SourceUserPAT '01e0e010-1010-1010-b101-ca1beec10efc' `
     -DestinationVSAAddress 'https://destination.example' -DestinationVSAUserName 'user2' -DestinationUserPAT '02e0e020-2020-2020-b202-ca2beec20efc' -OverwriteExistingModule
    Populates  the VSA Machine Summary with the Active Directory Computer description. Overwrites existing VSAModule if found.
.NOTES
    Version 0.1
    Requires:
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
    [string] $SourceVSAAddress,

    [parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName = $true)]
    [ValidateScript(
            {if ($_ -match '^http(s)?:\/\/([\w.-]+(?:\.[\w\.-]+)+|localhost)$') {$true}
            else {Throw "$_ is an invalid address. Enter a valid address that begins with https://"}}
            )]
    [string] $DestinationVSAAddress,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $SourceVSAUserName,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $DestinationVSAUserName,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $SourceUserPAT,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $DestinationUserPAT,

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

"`n[Start]`t$(Get-Date)" | Write-Debug

if ($SourceVSAAddress -eq $DestinationVSAAddress) {
    Throw "Source and destination are the same!"
}

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

#region Load VSA Module
Clear-Host
Write-host "One moment, please`n"
$ModuleName  = "VSAModule"
$ArchiveName = "$ModuleName.zip"

$InstallModuleParams = @{ ArchiveName = $ArchiveName }
if($OverwriteExistingModule) {
    $InstallModuleParams.Add('OverwriteExistingModule', $true)
}
$ModulePath  = Install-GithubModule @InstallModuleParams

Import-Module "$ModulePath\$ModuleName.psm1" -Force
#endregion Load VSA Module

if ( Get-Module -ListAvailable -Name $ModuleName) {

    #region prepare creds & set connection

    # Convert to SecureString
    [securestring]$secStringPassword = ConvertTo-SecureString $SourceUserPAT -AsPlainText -Force
    [pscredential]$SourceCred = New-Object System.Management.Automation.PSCredential ($SourceVSAUserName, $secStringPassword)

    # Convert to SecureString
    [securestring]$secStringPassword = ConvertTo-SecureString $DestinationUserPAT -AsPlainText -Force
    [pscredential]$DestinationCred = New-Object System.Management.Automation.PSCredential ($DestinationVSAUserName, $secStringPassword)
    #endregion prepare creds

    #region Create connection objects
    $SourceConnParams       = @{
                                VSAServer     = $SourceVSAAddress
                                Credential    = $SourceCred
                            }
    $DestinationConnParams  = @{
                                VSAServer     = $DestinationVSAAddress
                                Credential    = $DestinationCred
                            }
    Clear-Host
    Write-host "One moment, please`n" 
    Write-host "Connecting to the Source VSA Environment`n" -ForegroundColor Green
    $SourceVSA     = New-VSAConnection @SourceConnParams
    Write-host "`nConnecting to the Destination VSA Environment`n" -ForegroundColor Green
    $DestinationVSA = New-VSAConnection @DestinationConnParams 
    #endregion prepare creds & set connection

    #region Check & Create Custom Custom Fields
    $Output = "`nGet the Source Custom Fields To Transfer`n"
    $Output | Write-Host -ForegroundColor Green
    $Output | Write-Debug

    $SourceCustomFields      = Get-VSACustomFields -VSAConnection $SourceVSA
    if($null -eq $SourceCustomFields) {
        Throw "No Custom Fields found in the source!"
    }
    $DestinationCustomFields = Get-VSACustomFields -VSAConnection $DestinationVSA

    [hashtable] $CompareParams = @{
                                ReferenceObject  = $SourceCustomFields.FieldName
                                DifferenceObject = $DestinationCustomFields.FieldName
                            }

    [string[]] $FieldsToTransfer = Compare-Object @CompareParams | Where-Object {$_.SideIndicator -eq '<='} | Select-Object -ExpandProperty InputObject

    $Output = "`n$FieldsToTransfer" | Out-String
    $Output | Write-Host -ForegroundColor Cyan
    $Output | Write-Debug
    Write-host "`nTransfer the Custom Fields`n"

    $SourceCustomFields | Where-Object {$_.FieldName -in $FieldsToTransfer} | ForEach-Object { $_ | Add-VSACustomField -VSAConnection $DestinationVSA }
    #endregion & Create Custom Custom Fields

    #region Migrate Custom Fields Values
        #region Collect Custom Fields Values in the Source Env
    $SourceAgents = Get-VSAAgent -VSAConnection $SourceVSA

    $Output = "`n<Collecting Custom Fields Data>`n<Source>`t$($SourceVSA.URI)`n"
    $Output | Write-Host -ForegroundColor Green
    $Output | Write-Debug

    [array]$FieldsDataToTranfer =@()
    Foreach($Agent in $SourceAgents)
    {
        "[scan]`tAgentID:`t$($Agent.AgentID)" | Write-Debug

        $CustomFields = Get-VSACustomFields -AgentId $Agent.AgentID -VSAConnection $SourceVSA
        if ($null -ne $CustomFields)
        {
            "`tAgentName:`t$($Agent.AgentName)`n`t[Custom Fields]:`n$($CustomFields | ConvertTo-Json)" | Write-Debug

            $FieldsDataToTranfer += [pscustomobject]@{
                AgentName = $Agent.AgentName
                Fields    = $CustomFields
            }
        }
    }
        #endregion Collect Custom Fields Values in the Source Env

    #Since agents in different environments have different identifiers, the corresponding agents are found by matching agent name.

        #region Set Custom Fields Values in the Destination Env
    $DestinationAgents = Get-VSAAgent -VSAConnection $DestinationVSA

    #Filter out corresponding Destination Agents by name.
    $DestinationAgents = $DestinationAgents | Where-Object {$_.AgentName -in $($FieldsDataToTranfer | Select-Object -ExpandProperty AgentName) }

    "`n[Migrating Custom Fields Data]`n[Destination]`t$($DestinationVSA.URI)`n"| Write-Debug

    Foreach($Agent in $DestinationAgents)
    {
        "<update>`tAgentID:`t$($Agent.AgentID)" | Write-Debug

        [array]$CustomFields = $FieldsDataToTranfer | Where-Object {$_.AgentName -eq $Agent.AgentName} | Select-Object -ExpandProperty Fields

        "`tAgentName:`t$($Agent.AgentName)`n`t<Custom Fields>:`n$($CustomFields | ConvertTo-Json)" | Write-Debug

        Foreach($CustomField in $CustomFields)
        {
            [hashtable]$Params = @{
                AgentID       = $Agent.AgentID
                FieldName     = $CustomField.FieldName
                FieldValue    = $CustomField.FieldValue
                VSAConnection = $DestinationVSA
            }
            Update-VSACustomField @Params
        }
    }
        #endregion Set Custom Fields Values in the Destination Env
    #endregion Migrate Custom Fields Values
} else {
    Write-Host "Module" -ForegroundColor Yellow -NoNewline
    Write-Host "`t$ModuleName" -ForegroundColor Red -NoNewline
    Write-Host "`tis not available" -ForegroundColor Yellow
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