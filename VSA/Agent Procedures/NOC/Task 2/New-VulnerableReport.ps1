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
    [string] $LogFilePath = 'NOC2.csv',

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $ExcelPath = 'VulnerabilitiesReport.xlsx',

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


##################################################
#region Functions
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

#endregion Functions

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

#region Gather All Agents' Missing Patches & historical data (if exists)
[Array] $RepOnMissed = Get-ExcelSheetInfo -Path $XLSName `
                | ForEach-Object {Import-Excel -DataOnly $_.Path -WorksheetName $_.Name -NoHeader} `
                | Select-Object @{N='Data'; E={$_.PSObject.Properties.Value}}

[Array] $HistoricalData = @()
if (Test-Path -LiteralPath $LogFilePath ) {
    Import-Csv -LiteralPath $LogFilePath | `
    ForEach-Object {
        [datetime]$Date = [datetime]::parseexact( $_.Date, $FormatDate, $null)
        
        #skip the data within the current period
        if ( -Not (Compare-Period -Date $Date -TimeUnitType $TimeUnitType -TimeUnitQuantity $TimeUnitQuantity) ) {
            if ( [string]::IsNullOrEmpty($_.PatchName) ) {$_.PatchName = $null}
            $HistoricalData += $_
        }
    }
}
[Array] $CurrentData = @()
Foreach ($Row in $RepOnMissed)
{
    $Row.Data = $Row.Data | Where-Object { $_ }
    if ( 0 -lt $Row.Data.Count) {
        $CompareResult = Compare-Object -ReferenceObject $AllAgents.AgentName -DifferenceObject $Row.Data -IncludeEqual | Where-Object { ($_.SideIndicator -ne  '<=') }
        $AgentName = $CompareResult | Where-Object { ($_.SideIndicator -eq  '==') -and (-not ([string]::IsNullOrEmpty($_.InputObject))) } | Select-Object -ExpandProperty InputObject
        if ( $AgentName -in $AllAgents.AgentName) {
            [string]$PatchName = $CompareResult | Where-Object { ($_.SideIndicator -eq  '=>') -and (-not ([string]::IsNullOrEmpty($_.InputObject))) } | Select-Object -ExpandProperty InputObject
            if ( -not [string]::IsNullOrEmpty($PatchName) ) {
                $CurrentData += New-Object PSObject -Property @{Date    = $RepOnMissedDate.ToString($FormatDate)
                                                            AgentName   = $AgentName
                                                            PatchName   = $PatchName
                                                            OSType      = $($AllAgents | Where-Object {$_.AgentName -eq $AgentName} | Select-Object -ExpandProperty OSType -First 1)}
            }
        }
    }
}

$AllAgents | Where-Object -FilterScript { $_.AgentName -notin $CurrentData.AgentName } | `
            ForEach-Object {
                $CurrentData += New-Object PSObject -Property @{Date    = $RepOnMissedDate.ToString($FormatDate)
                                                            AgentName   = $_.AgentName
                                                            OSType      = $_.OSType
                                                            PatchName   = $null}
            }

#region (Over)write Log Data
[Array] $LogData = $HistoricalData + $CurrentData
$LogData  | Export-Csv -LiteralPath $LogFilePath -NoTypeInformation -Force
#endregion (Over)write Log Data
#endregion Gather All Agents' Missing Patches & historical data (if exists)

#region Generate Report


if ( Test-Path -Path $ReportPath ) { Remove-Item -Path $ReportPath -Force -Confirm:$false }

[array] $VSAData = @()

:nextEvent foreach ($Event in $LogData ) {
    $EventDate = [datetime]::parseexact( $Event.Date, $FormatDate, $null)
    
    foreach ($IntervalNumber in $MinIntervalNumber..$MaxIntervalNumber ) {
        $LogIndex = "$TimeUnitName $IntervalNumber"

        if ( Compare-Period -Date $EventDate -TimeUnitType $TimeUnitType -TimeUnitQuantity $TimeUnitQuantity -IntervalNumber $IntervalNumber ) {
            $OHT = [ordered]@{Period = "$TimeUnitName $IntervalNumber"; Machine = $Event.AgentName; Patch = $Event.PatchName; OSType = $Event.OSType}
            $VSAData += new-object psObject -property $OHT
            continue nextEvent
        }
    }
}

$VSAData = $VSAData | Sort-Object -Property Period

$WorksheetName = 'MachineStateByPeriod'
$TableName = 'StateByPeriod'
$StateDataByPeriod = $VSAData | Select-Object Period, Machine, OSType, @{Name = 'State'; Expression = {$(if ([string]::IsNullOrEmpty( $_.Patch )) {'Patched'} else {'Vulnerable'})}} -Unique
$ExcelPackage = $StateDataByPeriod | Export-Excel -Path $ReportPath -WorksheetName $WorksheetName -TableName $TableName -TableStyle Medium15 -AutoSize -PassThru

$WorksheetName = 'VulnerableMachines'
$TableName = 'PatchRawData'
($VSAData | Where-Object { -Not [string]::IsNullOrEmpty( $_.Patch )} | Select-Object Period, Machine, Patch -Unique ) | Export-Excel -ExcelPackage $ExcelPackage -WorksheetName $WorksheetName -TableName $TableName -TableStyle Medium3 -AutoSize -PassThru

$PivotTableName = 'PatchesPerMachine'
$PTObject = Add-PivotTable -ExcelPackage $ExcelPackage -PivotTableName $PivotTableName -SourceRange $ExcelPackage.Workbook.Worksheets[$WorksheetName].Tables[$TableName].Address -PivotRows @('Period', 'Machine', 'Patch') -PivotTotals None -PassThru -Activate
$PTObject.GridDropZones = $False

$PivotTableName = 'MachinesPerPatch'
$PTObject = Add-PivotTable -ExcelPackage $ExcelPackage -PivotTableName $PivotTableName -SourceRange $ExcelPackage.Workbook.Worksheets[$WorksheetName].Tables[$TableName].Address -PivotRows @('Period', 'Patch', 'Machine') -PivotTotals None -PassThru -Activate
$PTObject.GridDropZones = $False

$WorksheetName = 'MachineStateByPeriod'
$TableName = 'StateByPeriod'
$PivotTableName = 'PTStateByPeriod'
$chartdef = New-ExcelChartDefinition -Title "Vulnerable State By Periods" -ChartType PieExploded -ShowPercent
$PTObject = Add-PivotTable -ExcelPackage $ExcelPackage -PivotTableName $PivotTableName -SourceRange $ExcelPackage.Workbook.Worksheets[$WorksheetName].Tables[$TableName].Address -PivotRows @('Period', 'State') -PivotData State -PivotChartDefinition $chartdef -PassThru -Activate
$PTObject.GridDropZones = $False

Close-ExcelPackage -ExcelPackage $ExcelPackage #-Show


#endregion Generate Report
