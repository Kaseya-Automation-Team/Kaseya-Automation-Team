## Kaseya Automation Team
## Modification date: 25-05-2021
## Version 2.6
    
param (
    [parameter(Mandatory=$false)]
    [int]$LogIt = 0
)

#Start execution timer
$stopwatch = [system.diagnostics.stopwatch]::StartNew()

#Get folder where this script remains
$ScriptDir = Split-Path ($MyInvocation.MyCommand.Path) -Parent

#Specify folder to log files and file mask here
$LogsPath = "$ScriptDir\logs\webapp\audit.log*"

#Read files from folder
$LogsFiles = Get-ChildItem $LogsPath

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
Write-Debug ($LogsFiles|Out-String)
Write-Debug ($ScriptDir|Out-String)

$AllDevices = @()

#Create TEMP and CSV folders
$null = New-Item -Name "temp" -ItemType "Directory" -Force -Path $ScriptDir
#$null = New-Item -Name "csv" -ItemType "Directory" -Force -Path $ScriptDir

    #Export to CSV file, which has the same name as log file
    #$Export = [System.IO.StreamWriter] "$ScriptDir\csv\audit.csv"

Foreach ($Log in $LogsFiles) {

    #Run Garbage Collector
    [system.gc]::Collect()

    $LogName = $Log.Name

    #Parse only strings which are ralted to devices and put them into file in TEMP folder
    Select-String -Path $Log.FullName -Pattern "on device" | Select-Object -ExpandProperty Line | Out-File -FilePath "$ScriptDir\temp\$LogName"

    $Logname = "$ScriptDir\temp\$LogName"

    #Read TEMP file
    $AllLines = [System.IO.File]::ReadLines($LogName)

     Foreach ($Line in $AllLines) {
        try {
            #Replace line brake characters
            $Line = $Line.Replace("`n", "")

            #Regex which parses the line from log
            $Line -match "^\d+-\d+-\d+ \d+:\d+:\d+,\d+\s.+deviceName=(.+?), address=(.+), macaddress.+$" | Out-Null
    
            $DeviceName = $Matches[1]
            $DeviceAddress = $Matches[2]

            $AllDevices +=$DeviceName

        }
        catch {
            Write-Debug "Unable to parse following string:"
            Write-Debug ($Line|Out-String)
            Write-Debug ($_.Exception|Out-String)
        }
        
     }

     $AllDevices = $AllDevices|Sort-Object -Unique

     Write-Output "Device Name,IP Address, Created, Deleted, Suspended"
	 
     Foreach ($Device in $AllDevices) {

        Write-Debug ($Device|Out-String)

        #Create event
        $CreateEvent = Select-String -Path $LogName -Pattern "(CreateNetworkDevice.*$Device)"|Select-Object -Last 1| Foreach {$_.Line}

        Write-Debug ($CreateEvent|Out-String)

        if (!$CreateEvent) {
            $CreateEventTimeStamp = "NULL"
            $DeviceIpAddress = "NULL"
        } else {
            $CreateEvent -match "^(.+) a.d.c.+\saddress=(.+?)," | Out-Null
            $CreateEventTimeStamp = $Matches[1]
            $DeviceIpAddress = $Matches[2]
        }

        #Delete event
        $DeleteEvent = Select-String -Path $LogName -Pattern "(DeleteTestContainer.*$Device)"|Select-Object -Last 1| Foreach {$_.Line}

        Write-Debug ($DeleteEvent|Out-String)

        if (!$DeleteEvent) {
            $DeleteEventTimeStamp = "NULL"
        } else {
            $DeleteEvent -match "^(.+) a.d.c." | Out-Null
            $DeleteEventTimeStamp = $Matches[1]
        }

        #SuspendEvent
        $SuspendEvent = Select-String -Path $LogName -Pattern "(UpdateNetworkDevice.*$Device.*suspended=true)"|Select-Object -Last 1| Foreach {$_.Line}

        Write-Debug ($SuspendEvent|Out-String)
        
        if (!$SuspendEvent) {
            $SuspendEventTimeStamp = "NULL"
        } else {
            $SuspendEvent -match "^(.+) a.d.c." | Out-Null
            $SuspendEventTimeStamp = $Matches[1]
        }

        if ($DeviceIpAddress -ne "NULL") {

        #$Content = "$Device`, $DeviceIpAddress, created: $CreateEventTimeStamp, deleted: $DeleteEventTimeStamp, suspended: $SuspendEventTimeStamp"
        $Content = "$Device`, $DeviceIpAddress, $CreateEventTimeStamp, $DeleteEventTimeStamp, $SuspendEventTimeStamp"

        #$Export.WriteLine($Content)

		Write-Output $Content

        }

     }

     
}

#$Export.close()

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