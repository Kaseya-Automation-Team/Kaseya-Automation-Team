## Kaseya Automation Team
    
param (
    [parameter(Mandatory=$false)]
    [int]$LogIt = 0
)

#Start execution timer
$stopwatch = [system.diagnostics.stopwatch]::StartNew()

#Get folder where this script remains
$ScriptDir = Split-Path ($MyInvocation.MyCommand.Path) -Parent

#Specify folder to log files and file mask here
$LogsPath = "$ScriptDir\logs\webapp\audit.log.*"

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

<#
Function Parse-String {

    try {
        #Replace line brake characters
        $Line = $Line.Replace("`n", "")

        #Regex which parses the line from log
        $Line -match "^\d+-\d+-\d+ \d+:\d+:\d+,\d+\s.+deviceName=(.+?), address=(.+), macaddress.+$" | Out-Null
    
        $DeviceName = $Matches[1]
        $DeviceAddress = $Matches[2]
        $DeviceID = $DeviceName+$DeviceAddress

        $Device += $DeviceID

        return "$DeviceID"
    }
    catch {
        Write-Debug "Unable to parse following string:"
        Write-Debug ($Line|Out-String)
        Write-Debug ($_.Exception|Out-String)
    }
}
#>

<#
Function Export-to-CSV
{
    try {
        $Content = Parse-String
		Write-Host $Content
        #$Export.WriteLine($content)
    }
    catch {
        Write-Debug "Unable to parse following string:"
        Write-Debug ($Line|Out-String)

    }
}
#>

#Create TEMP and CSV folders
$null = New-Item -Name "temp" -ItemType "Directory" -Force -Path $ScriptDir
$null = New-Item -Name "csv" -ItemType "Directory" -Force -Path $ScriptDir

Foreach ($Log in $LogsFiles) {

    #Run Garbage Collector
    [system.gc]::Collect()

    $LogName = $Log.Name

    #Export to CSV file, which has the same name as log file
    #$Export = [System.IO.StreamWriter] "$ScriptDir\csv\$Logname.csv"

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

            #$DeviceItem = New-Object psobject

            #Add-Member -InputObject $DeviceItem -MemberType NoteProperty -Name DeviceName -Value $DeviceName
            #Add-Member -InputObject $DeviceItem -MemberType NoteProperty -Name DeviceAddress -Value $DeviceAddress

            #$AllDevices += $DeviceItem

            $AllDevices +=$DeviceName

           # $AllDevices = $AllDevices |Select-Object -Unique

        }
        catch {
            Write-Debug "Unable to parse following string:"
            Write-Debug ($Line|Out-String)
            Write-Debug ($_.Exception|Out-String)
        }
        
     }

     $AllDevices = $AllDevices|Get-Unique

     Foreach ($Device in $AllDevices) {
        #$SecondDeviceAddress = $Device.DeviceAddress
        #$SecondDeviceName = $Device.DeviceName

        Write-Host "==============="
        #Select-String -Path $LogName -Pattern "(CreateNetworkDevice.*$Device|DeleteTestContainer.*$Device|UpdateNetworkDevice.*$Device)"
        $CreateEvent = Select-String -Path $LogName -Pattern "(CreateNetworkDevice.*$Device)"|Select-Object -Last 1| Foreach {$_.Line}

        if (!$CreateEvent) {
            $CreateEventTimeStamp = "NULL"
        } else {
            $CreateEvent -match "^(.+) a.d.c." | Out-Null
            $CreateEventTimeStamp = $Matches[1]
        }

#        Write-Host $CreateEventTimeStamp

#        Write-Host "Delete events:"
        $DeleteEvent = Select-String -Path $LogName -Pattern "(DeleteTestContainer.*$Device)"|Select-Object -Last 1| Foreach {$_.Line}

        if (!$DeleteEvent) {
            $DeleteEventTimeStamp = "NULL"
        } else {
            $DeleteEvent -match "^(.+) a.d.c." | Out-Null
            $DeleteEventTimeStamp = $Matches[1]
        }
#        Write-Host $DeleteEventTimeStamp

#        Write-Host "Update events:"
        $UpdateEvent = Select-String -Path $LogName -Pattern "(UpdateNetworkDevice.*$Device)"|Select-Object -Last 1| Foreach {$_.Line}

        if (!$UpdateEvent) {
            $UpdateEventTimeStamp = "NULL"
        } else {
            $UpdateEvent -match "^(.+) a.d.c." | Out-Null
            $updateEventTimeStamp = $Matches[1]
        }

        Write-Host "$Device`: created: $CreateEventTimeStamp, updated: $UpdateEventTimeStamp, deleted: $DeleteEventTimeStamp"

        #Write-Host $UpdateEventTimeStamp
        Write-Host "==============="
     }
 <#      
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

    #$Export.close()
#>
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