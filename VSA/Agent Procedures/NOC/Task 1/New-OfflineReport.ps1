<#
.Synopsis
    The script gathers information on number of comuters that are offline/online and creates a report in MS Excel format.
.DESCRIPTION
    This PowerShell script detects which computers are offline/online and saves summarized information and detailed in an Excel file.
    To maintain a historical record of offline and online computers, the script stores the information in a CSV file.
    This CSV file acts as a repository for collecting and preserving the data from previous reports.
.PARAMETER $VSAServerAddress
    Primary and Secondary VSA servers devided by a semicolon.
.PARAMETER VSAUserName
    The VSA username. The user must have permissions to create VSA organizations and machine groups.
.PARAMETER VSAUserPAT
    The VSA User access token. (VSA->System->User Security->Users->Access Tokens).
.PARAMETER TimeUnitType
    The type of time interval. Valid values are 'Week' or 'Month'.
.PARAMETER TimeUnitQuantity
    The amount of specified time intervals within patching period. Valid values are 1,2,3.
.PARAMETER LogFilePath
    (Optional) Name of the CSV file to store historical data.
.PARAMETER ExcelPath
    (Optional) Path to the Excel file with report on Offline and online machines.
.PARAMETER OverwriteExistingModule
    (Optional) Enforce overwriting existing PowerShell VSAModule.
.PARAMETER MailSSLDisable
    (Optional) Disables SSL connection to the Mail server.
.PARAMETER DisableLogging
    (Optional) Disables logging of the script.
.EXAMPLE
    .\New-OfflineReport.ps1 -VSAServerAddress 'https://YourServer.vsa' -VSAUserName 'user1' -VSAUserPAT '01e0e010-1010-1010-b101-ca1beec10efc' -TimeUnitType 'Week'
.NOTES
    Version 0.2.1
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
    [ValidateSet('Week', "Month")]
    [string] $TimeUnitType,

    [parameter(Mandatory=$false)]
    [ValidateScript({
            if( ( 0 -gt $_ ) -and ( 4 -le $_ ) ) {
                throw "Interval duration is out of the allowed range"
            }
            return $true
        })]
    [int] $TimeUnitQuantity = 1,
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $LogFilePath = 'NOC.csv',

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $ExcelPath = 'OfflineReport.xlsx',

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
    #$VerbosePreference     = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $LogFile = "$ScriptPath\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

#region init
$TimeUnitName = $TimeUnitType
if (1 -lt $TimeUnitQuantity) {
    $TimeUnitName = "$($TimeUnitQuantity)x$($TimeUnitType)s"
}

[string] $FormatDate = 'yyyy-MM-dd HH:mm:ss'
[datetime] $Now = [datetime]::Now
[int] $MinIntervalNumber = 1
[int] $MaxIntervalNumber = 6

[Array] $LogData = @()
#endregion init

#region functions
function Get-WeekNumber {
    Param(
    [parameter(Mandatory = $false)]
    [datetime]$Date = [datetime]::Now,

    [parameter(Mandatory=$false)]
    [switch] $UseUICulture
    )
    <#
    First create an integer(0/1) from the boolean,
    "Is the integer DayOfWeek value greater than zero?".
    Then Multiply it with 4 or 6 (weekrule = 0 or 2) minus the integer DayOfWeek value.
    This turns every day (except Sunday) into Thursday.
    Then return the ISO8601 WeekNumber.
    #>
    if ($UseUICulture) {
        $Culture = Get-UICulture
    } else {
        $Culture = Get-Culture
    }
    [datetime]$Date = Get-Date($Date)
    $WeekRule = $Culture.DateTimeFormat.CalendarWeekRule.value__
    $FirstDayOfWeek = $Culture.DateTimeFormat.FirstDayOfWeek.value__
    $WeekRuleDay = [int]($Date.DayOfWeek.Value__ -ge $FirstDayOfWeek ) * ( (6 - $WeekRule) - $Date.DayOfWeek.Value__ )
    return $Culture.Calendar.GetWeekOfYear(($Date).AddDays($WeekRuleDay), $WeekRule, $FirstDayOfWeek)
}

function Compare-Period
{

    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false,
                   HelpMessage="Enter the date for evaluation.",
                   Position=0)]
        [datetime]
        $Date,

        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Select the type of time interval (Week or Month).",
                   Position=1)]
        [ValidateSet('Week', "Month")]
        [string]
        $TimeUnitType,

        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Indicate the number of intervals of a given type for a historical date. The script will assess whether the provided date falls within this preceding time span.",
                   Position=3)]
        [ValidateScript({
            if( ( 0 -gt $_ ) -and ( 10 -le $_ ) ) {
                throw "Number of intervals is out of the allowed range"
            }
            return $true
        })]
        [int]
        $IntervalNumber = 1,

        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Specify the duration of the time interval in terms of the number of weeks or months.",
                   Position=4)]
        [ValidateScript({
            if( ( 0 -gt $_ ) -and ( 4 -le $_ ) ) {
                throw "Interval duration is out of the allowed range"
            }
            return $true
        })]
        [int]
        $TimeUnitQuantity = 1
    )

    Begin
    {
        [datetime] $Now             = [datetime]::Now
        [bool]     $FallsIntoPeriod = $false
        [int]      $DateOffset      = -1*($IntervalNumber - 1)*$TimeUnitQuantity
    }
    Process
    {
        switch ($TimeUnitType) {
            'Week' {
                #Write-host "Log event's year: [$($Date.Year)], Year(Now): <$($Now.Year)>; Event week number: [$(Get-WeekNumber -Date $Date)], Week(Now): [$(Get-WeekNumber -Date $Now)] "
                $Days = 7*$DateOffset
                $ReferenceDate = $Now.AddDays($Days)

                $FallsIntoPeriod = $(($Date.Year -eq $ReferenceDate.Year) -and ( [Math]::Ceiling( (Get-WeekNumber -Date $Date)/$TimeUnitQuantity ) -eq [Math]::Ceiling( (Get-WeekNumber -Date $ReferenceDate)/$TimeUnitQuantity) ) )
            }
            'Month' {
                $ReferenceDate = $Now.AddMonths($DateOffset)

                $FallsIntoPeriod = $(($Date.Year -eq $ReferenceDate.Year) -and ( [Math]::Ceiling( $Date.Month/$TimeUnitQuantity ) -eq [Math]::Ceiling( $ReferenceDate.Month/$TimeUnitQuantity )))
            }

        }
    }
    End
    {
        return $FallsIntoPeriod
    }
}

function Get-ModuleToFolder {
    param (
        [string] $URL,
        [string] $ArchiveName,
        [string] $ModuleInstallFolder
    )

    Write-Debug "Downloading from GitHub: $URL"
    $TempArchiveFile = Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $ArchiveName

    Invoke-WebRequest $URL -OutFile $TempArchiveFile
    Unblock-File -Path $TempArchiveFile

    [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory( $TempArchiveFile, $ModuleInstallFolder )

    #perform cleanup
    Remove-Item -Path $TempArchiveFile -Force -ErrorAction SilentlyContinue

    Write-Debug "Module <$moduleName> installed into <$ModuleInstallFolder> Folder"
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
            Write-Debug "The module folder <$ModuleInstallFolder> exists."
            Write-Debug "Removing the folder..."
            Remove-Item -Path $ModuleInstallFolder -Recurse -Force
            Get-ModuleToFolder -URL $URL -ArchiveName $ArchiveName -ModuleInstallFolder $ModuleInstallFolder
        }
    }
    #endregion check if module exists
    return $ModuleInstallFolder
}
#endregion functions

#region Checking & installing ImportExcel Module
[string] $ModuleName = 'ImportExcel'
[string] $PkgProvider = 'NuGet'

if ( -not ((Get-Module -ListAvailable | Select-Object -ExpandProperty Name) -contains $ModuleName) ) {
    Write-Debug "Please wait for the necessary modules to install."
    if ( -not ((Get-PackageProvider -ListAvailable | Select-Object -ExpandProperty Name) -contains $PkgProvider) ) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Install-PackageProvider -Name $PkgProvider -Force -Confirm:$false
    }
    Install-Module -Name $ModuleName -Force -Confirm:$false
}
Import-Module ImportExcel
if ( -Not (Get-Module -ListAvailable -Name $ModuleName) ) {
    throw "ERROR: the PowerShell module <$ModuleName> is not available"
}  else {
    Write-Debug "INFO: The Module <$ModuleName> imported successfully."
}
#endregion Checking & installing ImportExcel Module



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
    throw "ERROR: the PowerShell module <$ModuleName> is not available"
}  else {
    Write-Debug "INFO: The Module <$ModuleName> imported successfully."
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
Write-Debug "Processing server list: $($VSAServers | Out-String)"
foreach ( $Server in $VSAServers  ) {
    [string] $Address = "https://$([regex]::Matches( $Server, '.+?(?=\:)' ).Value)"
    $VSAConnParams.VSAServer = $Address
    Write-Debug "Attempt to connect to <$Address>"
    $VSAConnection = try { New-VSAConnection @VSAConnParams } catch {$null}
    if ( $null -ne $VSAConnection ) {
        Write-Debug "Connected to <$Address>"
        break
    }
}
#endregion Detect Available VSA Server & Connect to it

$AllAgents = Get-VSAAgent -VSAConnection $VSAConnection # | Select-Object AgentId, Online
Write-Debug "Information on current agents' online status has been gathered. Total $($AllAgents.Count) agents."

#region Gather All Agents' Statuses & historical data (if exists)

#Write-Host "Period Type: $TimeUnitType"
[Array] $LogData = @()
if (Test-Path -LiteralPath $LogFilePath ) {
    Import-Csv -LiteralPath $LogFilePath | `
    ForEach-Object {
        [datetime]$Date = [datetime]::parseexact( $_.Date, $FormatDate, $null)

        #skip the data within the current period        
        if ( -Not (Compare-Period -Date $Date -TimeUnitType $TimeUnitType -TimeUnitQuantity $TimeUnitQuantity) ) {
            $LogData += $_
        }
    }
    Write-Debug "Historical data loaded from the <$LogFilePath> file."
}

foreach ($Agent in $AllAgents) {
    [string] $Status = 'Online'
    if ( 0 -eq $Agent.Online) { $Status = 'Offline' }
    #The updated historical data will be now as follows:
    $LogData += New-Object PSObject -Property @{Date    = $Now.ToString($FormatDate)
                                                AgentID = $Agent.AgentID
                                                Status  = $Status}
}
#endregion Gather All Agents' Statuses & historical data (if exists)

#region Parse the collected data for reporting
Write-Debug "Patching period interval passed to the script: <$($TimeUnitName)>. Parsing information..."

[hashtable] $LogsByPeriods  = @{}
[string[]]  $AgentsByPeriod = @()
foreach ( $Status in @('Online', 'Offline')) {
    foreach ($IntervalNumber in $MinIntervalNumber..$MaxIntervalNumber ) {
        $LogsByPeriods.Add("$TimeUnitName $IntervalNumber $Status", $AgentsByPeriod)
    }
}

foreach ($Event in $LogData ) {
    $Event.Date = [datetime]::parseexact( $Event.Date, $FormatDate, $null)
    foreach ( $Status in @('Online', 'Offline')) {

        foreach ($IntervalNumber in $MinIntervalNumber..$MaxIntervalNumber ) {
                
            $HashIndex = "$TimeUnitName $IntervalNumber $Status"

            if ( ( $Event.Status -eq $Status ) -and (Compare-Period -Date $Event.Date -TimeUnitType $TimeUnitType -TimeUnitQuantity $TimeUnitQuantity -IntervalNumber $IntervalNumber) ) {
                $LogsByPeriods[$HashIndex] += $Event.AgentID
            }
        }
    }
}
#endregion Parse the collected data for reporting

#region (Over)write historical Data
Write-Debug "Writing updated historical data to file: <$($LogFilePath)>"
[Array] $UpdatedHistoricalData = @()
$LogData | ForEach-Object {
    $_.Date = $_.Date.ToString($FormatDate)
    $UpdatedHistoricalData += $_
}
$UpdatedHistoricalData | Export-Csv -LiteralPath $LogFilePath -NoTypeInformation -Force
#endregion (Over)write historical Data

#region Create Report in MS Excel format
Write-Debug "Creating report file: <$($ExcelPath)>"
if (Test-Path -Path $ExcelPath ) { Remove-Item -Path $ExcelPath -Force -Confirm:$false }

[int]$Column = 1
foreach ($key in ($LogsByPeriods.Keys | Sort-Object) ) {
    [string[]]$AggregatedData = @($key) + @($LogsByPeriods[$key].Count)
    [string[]]$DetailedData   = @('Machine Id') + @($AllAgents | Where-Object -FilterScript { $_.AgentId -in $($LogsByPeriods[$key]) } | Select-Object -ExpandProperty AgentName | Sort-Object)
        
    $AggregatedData | Export-Excel -Path $ExcelPath -StartColumn $Column -StartRow 1 -BoldTopRow -AutoSize
    $DetailedData   | Export-Excel -Path $ExcelPath -StartColumn $Column -StartRow 3 -BoldTopRow -AutoSize
    #Remove-Variable -Name DetailedData
    #[gc]::Collect()
    $Column++
}
#endregion Create Report in MS Excel format

#region check/stop transcript
if ( -Not $DisableLogging )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    #$VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript