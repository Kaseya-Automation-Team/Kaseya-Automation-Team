## Kaseya Automation Team
    
param (
    [parameter(Mandatory=$false)]
    [int]$LogIt = 1
)

#Start execution timer
$stopwatch = [system.diagnostics.stopwatch]::StartNew()

#Specify folder to log files and file mask here
$LogsPath = "c:\work\vsa\parser\audit.log.*"

#Read files from folder
$LogsFiles = Get-ChildItem $LogsPath

#Get folder where this script remains
$ScriptDir = Split-Path ($MyInvocation.MyCommand.Path) -Parent

[string]$Pref = "Continue"
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $LogFile = "$ScriptDir\LogParser.log"
    Start-Transcript -Path $LogFile
}

Write-Debug "Script execution started"
Write-Debug ($LogsPath|Out-String)
Write-Debug ($LogsFiles|Out-String)
Write-Debug ($ScriptDir|Out-String)

Function Parse-String {

    try {
        #Replace line brake characters
        $Line = $Line.Replace("`n", "")

        #Regex which parses the line from log
        $Line -match "^(\d+-\d+-\d+ \d+:\d+:\d+,\d+)\s.+deviceName=(.+), address=(.+), macaddress=(.+),.+suspended=(.+),.+$"
    
        $DateTime = $Matches[1]
        $DeviceName = $Matches[2]
        $DeviceAddress = $Matches[3]
        $MacAddress = $Matches[4]
        $SuspendedStatus = $Matches[5]

        return "$DateTime,$DeviceName,$DeviceAddress,$MacAddress,$SuspendedStatus"
    }
    catch {
        Write-Debug "Unable to parse following string:"
        Write-Debug ($Line|Out-String)
        Write-Debug ($_.Exception|Out-String)
    }
}

Function Export-to-CSV
{
    try {
        $Content = Parse-String
        $Export.WriteLine($content)
    }
    catch {
        Write-Debug "Unable to parse following string:"
        Write-Debug ($Line|Out-String)

    }
}

#Create TEMP and CSV folders
$null = New-Item -Name "temp" -ItemType "Directory" -Force -Path $ScriptDir
$null = New-Item -Name "csv" -ItemType "Directory" -Force -Path $ScriptDir

Foreach ($Log in $LogsFiles) {

    #Run Garbage Collector
    [system.gc]::Collect()

    $LogName = $Log.Name

    #Export to CSV file, which has the same name as log file
    $Export = [System.IO.StreamWriter] "$ScriptDir\csv\$Logname.csv"

    #Parse only strings which are ralted to devices and put them into file in TEMP folder
    Select-String -Path $Log.FullName -Pattern "on device" | Select-Object -ExpandProperty Line | Out-File -FilePath "$ScriptDir\temp\$LogName"

    $Logname = "$ScriptDir\temp\$LogName"

    #Read TEMP file
    $AllLines = [System.IO.File]::ReadLines($LogName)
       
    Foreach ($Line in $AllLines) {

        If ($Line -like "*CreateNetworkDevice*") {
            Export-to-CSV
        }

        elseif ($Line -like "*DeleteTestContainer*") {
            Export-to-CSV
        }

        elseif ($Line -like "*UpdateNetworkDevice*") {
            Export-to-CSV
        }

    }

    $Export.close()

}

#Stop timer here
$stopwatch.Stop()

if (1 -eq $LogIt)
{
    Write-Debug "Total execution time: "
    Write-Debug ($stopwatch.Elapsed.TotalSeconds|Out-String)
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
} else {
    Write-Host "Total execution time:"$stopwatch.Elapsed.TotalSeconds
}