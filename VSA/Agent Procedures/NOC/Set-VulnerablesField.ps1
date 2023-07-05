<#
.Synopsis
    The script fills calculates percentage of vulnerable comuters and fills in corresponding custom fields.
.DESCRIPTION
    This PowerShell script facilitates the automation of receiving scheduled Machines Vulnerable reports in Excel format, which are sent to a predefined email inbox.
    The script connects to the mailbox, reads the email content, parses the Excel file, and calculates the percentage of vulnerable computers based on the report.
    The calculated percentage is then stored in corresponding custom fields, which are associated with the VSA report.
    If these custom fields do not already exist, the script automatically creates them to ensure accurate tracking of the vulnerability percentages over time.
    To maintain a historical record of vulnerable and invulnerable computers, the script stores the information in a CSV file.
    This CSV file acts as a repository for collecting and preserving the data from previous reports.
.PARAMETER $VSAServerAddress
    List of primary and Secondary VSA servers devided by a semicolon.
.PARAMETER VSAUserName
    The VSA username. The user must have permissions to create VSA organizations and machine groups.
.PARAMETER VSAUserPAT
    The VSA User access token. (VSA->System->User Security->Users->Access Tokens).
.PARAMETER  DedicatedEndpoint
    VSA Machine Id on which the script is to be executed and set values for the custom fields.
.PARAMETER MailAddress
    Email address of to which the reports are sent.
.PARAMETER MailServer
    Address of the POP server to connect.
.PARAMETER MailPwd
    Password to establish POP connection.
.PARAMETER PortPOP
    (Optional) Port number on which the POP server accepts connection (995 by default for SSL connection, 110 - no SSL).
.PARAMETER XLSName
    (Optional) Name of the attached Excel file.
.PARAMETER LogFilePath
    (Optional) Name of the CSV file to store historical data.
.PARAMETER OverwriteExistingModule
    (Optional) Enforce overwriting existing PowerShell VSAModule.
.PARAMETER MailSSLDisable
    (Optional) Disables SSL connection to the Mail server.
.PARAMETER DisableLogging
    (Optional) Disables logging of the script.
.NOTES
    Version 0.1.2
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
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $MailServer,
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $MailAddress,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $MailPwd,

    [parameter(Mandatory = $false,  
        ValueFromPipelineByPropertyName = $true)]
    [int] $PortPOP = 995,
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $XLSName = 'Machines vulnerable (Excluding Rejected and Suppressed).xlsx',
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $LogFilePath = 'NOC2.csv',

    [parameter(Mandatory=$false)]
    [switch] $OverwriteExistingModule,

    [parameter(Mandatory=$false)]
    [switch] $MailSSLDisable,

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

Write-verbose "Script Path: [$ScriptPath]"


#region get email
$assemblyPath   = Join-Path -Path $ScriptPath -ChildPath 'OpenPop.dll'
$AttachmentPath = $ScriptPath

try {
    [Reflection.Assembly]::LoadFile($assemblyPath)
} catch {
    throw "An error occurred while loading the assembly <$assemblyPath> : $($_.Exception.Message)"
}

$POP3Client = New-Object OpenPop.Pop3.Pop3Client
$POP3Client.Connect( $MailServer, $PortPOP, $( -Not $MailSSLDisable ) )
      
if ( -Not $POP3Client.Connected ) {
    throw "POP3 client failed to connect with server $MailServer"
} else {
    $POP3Client.Authenticate( $MailAddress, $MailPwd )
    Remove-Variable MailPwd

    $msgTotal = $POP3Client.GetMessageCount()
    foreach ($MsgNumber in 1..$msgTotal) {

        $EMail = $pop3Client.GetMessage( $MsgNumber ).ToMailMessage()
        
        Write-Verbose "Processing message $MsgNumber..."

        $XLSAttachments = @()
        $XLSAttachments += $EMail.Attachments | Where-Object { $_.Name -eq $XLSName }
        
        foreach ( $Attachment in  $XLSAttachments) {
            $SaveTo = Join-Path -Path $AttachmentPath -ChildPath $Attachment.Name
            
            Write-Verbose "`tSaving attachment [$($Attachment.Name)] to: [$SaveTo]" 

            New-Item -Path $SaveTo -ItemType "File" -Force
            $FileStream = New-Object IO.FileStream $SaveTo, 'Create'
            $Attachment.ContentStream.CopyTo( $FileStream )
            $FileStream.Close()
        }
    }
}

#endregion get email

#region Checking & installing ImportExcel Module
[string] $ModuleName = 'ImportExcel'
[string] $PkgProvider = 'NuGet'

if ( -not ((Get-Module -ListAvailable | Select-Object -ExpandProperty Name) -contains $ModuleName) ) {
    Write-Verbose "Please wait for the necessary modules to install."
    if ( -not ((Get-PackageProvider -ListAvailable | Select-Object -ExpandProperty Name) -contains $PkgProvider) ) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Install-PackageProvider -Name $PkgProvider -Force -Confirm:$false
    }
    Install-Module -Name $ModuleName -Force -Confirm:$false
}
Import-Module ImportExcel
if ( -Not (Get-Module -ListAvailable -Name ImportExcel) ) {
    throw "Module <ImportExcel> is not available"
}
#endregion Checking & installing ImportExcel Module

#region Parse Excel File
$XLSName = Split-Path -Path $XLSName -Leaf
$XLSName = Join-Path -Path $ScriptPath -ChildPath $XLSName

[string[]] $ExcelData = Get-ExcelSheetInfo -Path $XLSName `
                | ForEach-Object {Import-Excel -DataOnly $_.Path -WorksheetName $_.Name -NoHeader} `
                | Select-Object { $_.PSObject.Properties } `
                | ForEach-Object { $_.PSObject.Properties | Select-Object -ExpandProperty Value | Select-Object -ExpandProperty Value } `
                | Where-Object { -Not [string]::IsNullOrEmpty($_) } `
                | Select-Object -Unique
Write-Verbose "Excel data [$XLSName]: $($ExcelData | Out-String)"
#endregion Parse Excel File


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
[hashtable] $VulnerableLogsByMonths = @{}
[hashtable] $InvulnerableLogsByMonths = @{}

foreach ($Month in $MinMonth..$MaxMonth) {
    $VulnerableLogsByMonths.Add("Month $Month Percentage Of Vulnerable", 0)
    $InvulnerableLogsByMonths.Add("Month $Month Percentage Of Invulnerable", 0)
}

#region Check & Create Custom Fields
$ExistingCustomFields = Get-VSACustomFields -VSAConnection $VSAConnection
[string[]]$CFList = $VulnerableLogsByMonths + $InvulnerableLogsByMonths | Select-Object -ExpandProperty Keys
$CFList | Where-Object { -Not $($ExistingCustomFields.FieldName).Contains($_) } | ForEach-Object { Add-VSACustomField -FieldName $_ -FieldType "number" -VSAConnection $VSAConnection}
#endregion Check & Create Custom Fields

$AllAgents  = Get-VSAAgent -VSAConnection $VSAConnection | Select-Object AgentId, AgentName, ComputerName
#$Vulnerable = $AllAgents | Where-Object { $ExcelData.Contains($_.ComputerName) }

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
    [string] $Status = 'Invulnerable'
    if ( $ExcelData.Contains($Agent.ComputerName) ) { $Status = 'Vulnerable' }

    $LogData += New-Object PSObject -Property @{Date    = $Now
                                                AgentID = $Agent.AgentID
                                                Status  = $Status}
}
#endregion Gather All Agents' Statuses & historical data (if exists)

#region Count the vulnerable month
foreach ($Month in $MinMonth..$MaxMonth) {
    [int] $EventsPerMonth = 0
    #Write-Host "$Event"
    foreach ($Event in $LogData ) {
        $HashIndex = "Month $Month Percentage Of Vulnerable"
        $MonthOffset = -1*($Month - 1)
        $CompareDate = $Now.AddMonths($MonthOffset)
        #Write-Host "Status: <$Status>; Month: <$Month>; $CompareDate"
        if ( ($Event.Date.Year -eq $CompareDate.Year) -and ($Event.Date.Month -eq $CompareDate.Month) ) {
            $EventsPerMonth++
                if ( 'Vulnerable' -eq $Event.Status ) {
                $VulnerableLogsByMonths[$HashIndex]++
            }
        }
    }
    if ( 0 -lt $EventsPerMonth) {
        $VulnerableLogsByMonths[$HashIndex] = [math]::Round( ($VulnerableLogsByMonths[$HashIndex]*100/$EventsPerMonth) )
    }
}
#endregion Count the vulnerable month

#region Update Custom Fields on the Dedicated Agent
$DedicatedAgentID = $AllAgents | Where-Object {$_.AgentName -eq $DedicatedEndpoint} | Select-Object -ExpandProperty AgentId

foreach ($Month in $MinMonth..$MaxMonth) {
    $VulnerableFieldName  = "Month $Month Percentage Of Vulnerable"
    [int] $VulnerableFieldValue = $VulnerableLogsByMonths.Item( $VulnerableFieldName )

    [hashtable]$Params = @{
        AgentID       = $DedicatedAgentID
        FieldName     = $VulnerableFieldName
        FieldValue    = $VulnerableFieldValue
        VSAConnection = $VSAConnection
    }
    Update-VSACustomField @Params

    $InvulnerableFieldName  = "Month $Month Percentage Of Invulnerable"
    [int] $InvulnerableFieldValue = 100 - $VulnerableFieldValue
    [hashtable]$Params = @{
        AgentID       = $DedicatedAgentID
        FieldName     = $InvulnerableFieldName
        FieldValue    = $InvulnerableFieldValue
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