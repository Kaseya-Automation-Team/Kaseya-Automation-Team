<#
.Synopsis
    Creates a custom field.
.DESCRIPTION
    Downloads the VSAModule PowerShell module from github and installs it if the module folder is not found in the user's environment Module folder.
    Creates a custom field. By default field name is 'Win 10 Feature Version'. By default field type is 'string'.
.PARAMETER VSAAddress
    The address of the VSA server.
.PARAMETER VSAUserName
    The VSA User name. The user must have permissions to delete Agent Custom Fields.
.PARAMETER VSAUserPAT
    The VSA User access token. (VSA->System->User Security->Users->Access Tokens)
.PARAMETER OverwriteExistingModule
    (Optional) Downloads the VSAModule module from github and overwrites the existing one in the user's environment Module folder.
.PARAMETER LogIt
    (Optional) Logs execution transcript to a file.
.EXAMPLE
    .\Add-CustomField.ps1 -VSAAddress 'https://vsa.example' -VSAUserName 'user1' -VSAUserPAT '01e0e010-1010-1010-b101-ca1beec10efc'
.NOTES
    Version 0.1
    Requires:
        Internet connection to download VSAModule from GitHub if the module was not installed beforehand.
        Proper permissions to install module VSAModule and execute the script.
   
    Author: Proserv Team - VS

#>
param (
    [parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName = $true)]
    [ValidateScript(
            {if ($_ -match '^http(s)?:\/\/([\w.-]+(?:\.[\w\.-]+)+|localhost|vsalocal)$') {$true}
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
    [ValidateNotNullOrEmpty()]
    [string] $FieldName = 'Win 10 Feature Version',

    [parameter(Mandatory=$false)]
    [ValidateSet("string", "number", "datetime", "date", "time")]
    [string]$FieldType = 'string',

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
    [securestring]$secStringPassword = ConvertTo-SecureString $VSAUserPAT -AsPlainText -Force
    [pscredential]$VSACred = New-Object System.Management.Automation.PSCredential ($VSAUserName, $secStringPassword)

    #region Create connection objects
    $VSAConnParams =  @{
                            VSAServer     = $VSAAddress
                            Credential    = $VSACred
                        }
    Clear-Host
    Write-host "One moment, please`n" 
    Write-host "Connecting to the VSA Environment`n" -ForegroundColor Green
    $VSAConnection     = New-VSAConnection @VSAConnParams
    Write-host "OK"
    #endregion prepare creds & set connection

    [string[]] $ExistingFields = Get-VSACustomFields -VSAConnection $VSAConnection | Select-Object -ExpandProperty FieldName

    # If no FieldsToRemove specified remove all custom fields
    
    if ( $ExistingFields -notcontains $FieldToCreate )
    {
        Add-VSACustomField -FieldName $FieldName -FieldType $FieldType -VSAConnection $VSAConnection
        Write-Host "The field [$FieldName] was created" -ForegroundColor Green -NoNewline
    }
    else {
        Write-Host "The field [$FieldName] already exists" -ForegroundColor Green -NoNewline
    }

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