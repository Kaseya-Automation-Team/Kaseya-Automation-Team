param (
    [parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName = $true)]
    [ValidateScript(
            { if ( $($_.Trim()) -match '^http(s)?:\/\/([\w.-]+(?:\.[\w\.-]+)+|localhost)\/?$') {$true}
            else {Throw "$_ is an invalid address. Enter a valid address that begins with https://"}}
            )]
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
    [switch] $OverwriteExistingModule
)

[string]$Pref = 'Continue'

$ModuleName  = 'VSAModule'
$VSAServerAddress = $VSAServerAddress.Trim()

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

    Write-Output "Module"
    Write-Output "`t$ModuleName"
    Write-Output "`tis not available"

} else {

    #region prepare creds & set connection

    # Convert to SecureString
    [securestring]$secStringPassword = ConvertTo-SecureString $VSAUserPAT -AsPlainText -Force
    [pscredential]$VSACredentials = New-Object System.Management.Automation.PSCredential ($VSAUserName, $secStringPassword)

    #endregion prepare creds

    #region Create connection objects
    $VSAConnParams  = @{
                            VSAServer     = $VSAServerAddress
                            Credential    = $VSACredentials
                        }
    #Clear-Host
    Write-Verbose "Connecting to the VSA Environment`n" -ForegroundColor Green
    $VSAConnection = New-VSAConnection @VSAConnParams
    #endregion prepare creds & set connection

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
            $LogData += $_
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
}