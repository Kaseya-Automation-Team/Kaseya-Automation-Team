<#
.Synopsis
    The script gathers information on number of comuters that are offline/online and fills in corresponding custom fields.
.DESCRIPTION
    This PowerShell script detects which computers are offline/online and stores summarized information in corresponding custom fields.
    If these custom fields do not already exist, the script automatically creates them to ensure accurate tracking of number of comuters that are offline/online over time.
    To maintain a historical record of offline and online computers, the script stores the information in a CSV file.
    This CSV file acts as a repository for collecting and preserving the data from previous reports.
.PARAMETER $VSAServerAddress
    List of primary and Secondary VSA servers devided by a semicolon.
.PARAMETER VSAUserName
    The VSA username. The user must have permissions to create VSA organizations and machine groups.
.PARAMETER VSAUserPAT
    The VSA User access token. (VSA->System->User Security->Users->Access Tokens).
.PARAMETER  DedicatedEndpoint
.PARAMETER LogFilePath
    (Optional) Name of the CSV file to store historical data.
.PARAMETER OverwriteExistingModule
    (Optional) Enforce overwriting existing PowerShell VSAModule.
.PARAMETER MailSSLDisable
    (Optional) Disables SSL connection to the Mail server.
.PARAMETER DisableLogging
    (Optional) Disables logging of the script.
.NOTES
    Version 0.1
    Author: Proserv Team - VS
#>
param (
    [parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VSAServerAddress,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $VSAUserName,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $VSAUserPAT,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $DedicatedEndpoint,
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $LogFilePath = 'NOC.csv',

    [parameter(Mandatory=$false)]
    [switch] $OverwriteExistingModule,

    [parameter(Mandatory=$false)]
    [switch] $DisableLogging
)
$ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
#region check/start transcript
[string]$Pref = 'Continue'
if ( -Not $DisableLogging )
{
    $DebugPreference       = $Pref
    $VerbosePreference     = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $LogFile = "$ScriptPath\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

$ModuleName  = 'VSAModule'

#region Checking & installing VSA Module
function Get-ModuleToFolder {
    param (
        [string] $URL,
        [string] $ArchiveName,
        [string] $ModuleInstallFolder
    )

    Write-Verbose "Downloading from GitHub: $URL"
    $TempArchiveFile = Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $ArchiveName

    Invoke-WebRequest $URL -OutFile $TempArchiveFile
    Unblock-File -Path $TempArchiveFile

    [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory( $TempArchiveFile, $ModuleInstallFolder )

    #perform cleanup
    Remove-Item -Path $TempArchiveFile -Force -ErrorAction SilentlyContinue

    Write-Verbose "Module <$moduleName> installed into <$ModuleInstallFolder> Folder"
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
            Write-Verbose "The module folder <$ModuleInstallFolder> exists."
            Write-Verbose "Removing the folder..."
            Remove-Item -Path $ModuleInstallFolder -Recurse -Force
            Get-ModuleToFolder -URL $URL -ArchiveName $ArchiveName -ModuleInstallFolder $ModuleInstallFolder
        }
    }
    #endregion check if module exists
    return $ModuleInstallFolder
}
#endregion Checking & installing VSA Module

#region Load VSA Module
#Clear-Host
#Write-host "One moment, please`n"
$ModuleName  = "VSAModule"
$ArchiveName = "$ModuleName.zip"

$InstallModuleParams = @{ ArchiveName = $ArchiveName }
if($OverwriteExistingModule) {
    $InstallModuleParams.Add('OverwriteExistingModule', $true)
}
$ModulePath  = Install-GithubModule @InstallModuleParams

Import-Module "$ModulePath\$ModuleName.psm1" -Force
#endregion Load VSA Module

if ( -Not (Get-Module -ListAvailable -Name $ModuleName) ) {
    throw "Module <$ModuleName> is not available"
}

#region prepare creds
[securestring]$secStringPassword = ConvertTo-SecureString $VSAUserPAT -AsPlainText -Force
[pscredential]$VSACredentials = New-Object System.Management.Automation.PSCredential ($VSAUserName, $secStringPassword)
#endregion prepare creds

#region Create connection objects
[hashtable] $VSAConnParams  = @{
    VSAServer   = ''
    Credential  = $VSACredentials
    ErrorAction = 'Stop'
}

#Clear-Host
#region Detect Available VSA Server & Connect to it
[string[]]$VSAServers = $VSAServerAddress -split ';'
foreach ( $Server in $VSAServers  ) {
    [string] $Address = "https://$([regex]::Matches( $Server, '.+?(?=\:)' ).Value)"
    $VSAConnParams.VSAServer = $Address
    Write-Verbose "Attempt to connect to <$Address>"
    $VSAConnection = try { New-VSAConnection @VSAConnParams } catch {$null}
    if ( $null -ne $VSAConnection ) {
        Write-Verbose "Connected to <$Address>"
        break
    }
}
#endregion Detect Available VSA Server & Connect to it

[datetime] $Now = [datetime]::Now

[int] $MinMonth = 1
[int] $MaxMonth = 6

[string] $FormatDate = 'yyyy-MM-dd HH:mm:ss'

#hashtable to store values of the Custom Fields
[hashtable] $LogsByMonths = @{}
foreach ( $Status in @('Online', 'Offline')) {
    for ($Month = $MinMonth; $Month -le $MaxMonth; $Month++ ) {
        $LogsByMonths.Add("Month $Month $Status", 0)
    }
}

#region Check & Create Custom Fields
$ExistingCustomFields = Get-VSACustomFields -VSAConnection $VSAConnection
[string[]]$CFList = $LogsByMonths | Select-Object -ExpandProperty Keys
$CFList | Where-Object { -Not $($ExistingCustomFields.FieldName).Contains($_) } | ForEach-Object { Add-VSACustomField -FieldName $_ -FieldType "number" -VSAConnection $VSAConnection}
#endregion Check & Create Custom Fields

$AllAgents = Get-VSAAgent -VSAConnection $VSAConnection | Select-Object AgentId, AgentName, Online

#region Gather All Agents' Statuses & historical data (if exists)
[Array] $LogData = @()
if (Test-Path -LiteralPath $LogFilePath ) {
    Import-Csv -LiteralPath $LogFilePath | `
    ForEach-Object {
        $_.Date = [datetime]::parseexact( $_.Date, $FormatDate, $null)
        #skip the current month
        if ( -Not (($_.Date.Year -eq $Now.Year) -and ( $_.Date.Month -eq $Now.Month)) ) {
            $LogData += $_
        }
    }
}

foreach ($Agent in $AllAgents) {
    [string] $Status = 'Online'
    if ( 0 -eq $Agent.Online) { $Status = 'Offline' }

    $LogData += New-Object PSObject -Property @{Date    = $Now
                                                AgentID = $Agent.AgentID
                                                Status  = $Status}
}
#endregion Gather All Agents' Statuses & historical data (if exists)

#region Count Events By type & Month
foreach ($Event in $LogData ) {
    #Write-Host "$Event"
    foreach ( $Status in @('Online', 'Offline')) {
        for ($Month = $MinMonth; $Month -le $MaxMonth; $Month++ ) {
                
            $HashIndex = "Month $Month $Status"
            $MonthOffset = -1*($Month - 1)
            $CompareDate = $Now.AddMonths($MonthOffset)
            #Write-Host "Status: <$Status>; Month: <$Month>; $CompareDate"
            if ( ($Event.Date.Year -eq $CompareDate.Year) -and ($Event.Date.Month -eq $CompareDate.Month) -and ( $Event.Status -eq $Status ) ) {
                $LogsByMonths[$HashIndex]++
            }
        }
    }
}
#endregion Count Events By type & Month

#region Update Custom Fields on the Dedicated Agent
$TheAgentID = $AllAgents | Where-Object {$_.AgentName -eq $DedicatedEndpoint} | Select-Object -ExpandProperty AgentId

foreach ($FieldName in $LogsByMonths.Keys) 
{
    #Write-Host " $FieldName  : $($LogsByMonths.Item($FieldName ))"

    [hashtable]$Params = @{
        AgentID       = $TheAgentID
        FieldName     = $FieldName
        FieldValue    = $($LogsByMonths.Item($FieldName ))
        VSAConnection = $VSAConnection
    }
    Update-VSACustomField @Params
}
#endregion Update Custom Fields on the Dedicated Agent
    
#region (Over)write Log Data
[Array] $NewLogData = @()
$LogData | ForEach-Object {
    $_.Date = $_.Date.ToString($FormatDate)
    $NewLogData += $_
}
$NewLogData | Export-Csv -LiteralPath $LogFilePath -NoTypeInformation -Force
#endregion (Over)write Log Data

#region check/stop transcript
if ( -Not $DisableLogging )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript