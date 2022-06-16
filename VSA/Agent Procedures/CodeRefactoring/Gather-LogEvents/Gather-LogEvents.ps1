#Creating the default variables, but these can be changed as per the requirement
$Path = "$ENV:temp\EventLogs.csv"
$LogName = "System"
$Days = "30"


#Create array where all objects for export will be storred
$Results = @()

#Convert days to the specic date
$StartTime = (Get-date).AddDays(-$Days)

$AllEvents = Get-WinEvent -FilterHashtable @{
    StartTime=$StartTime
    Logname=$LogName
    #1 is Critical, 2 is Error
    Level=1, 2
}

ForEach ($Event in $AllEvents) {

    #Create new obect
    $Output = New-Object psobject

    #Collect time and date
    $Time = $Event.TimeCreated
    $Time = Get-Date $Time -Format 'MM/dd/yyyy hh:mm:ss:ms'
    $Time = $Time -replace "-", "/"

    #Collect level id and level name
    $LevelName = $Event.LevelDisplayName
    $Level = $Event.Level

    #Collect message
    $Message = $Event.Message

    #Skip log records without any message
    If ($Message) {

        #Remove carriage return and new lines from the error message
        $Message = $Event.Message.Replace("`r`n","")

        #Fill newly created objects with data
        Add-Member -InputObject $Output -TypeName LevelName -MemberType NoteProperty -Name LevelName -Value $LevelName
        Add-Member -InputObject $Output -TypeName Level -MemberType NoteProperty -Name Level -Value $Level
        Add-Member -InputObject $Output -TypeName Message -MemberType NoteProperty -Name Message -Value $Message
        Add-Member -InputObject $Output -TypeName DateTime -MemberType NoteProperty -Name DateTime -Value $Time


        #Add object to the previously created array
        $Results += $Output
    }

}

#Export results to csv file
$Results| Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8