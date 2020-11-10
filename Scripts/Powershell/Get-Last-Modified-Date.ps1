$targetff = $args[0]
$daysold = $args[1]
$lastDay = (Get-Date).AddDays(-$daysold)
#while ($true)
#{
    if ((Get-ItemProperty -Path $targetff -Name LastWriteTime).LastWriteTime -gt $lastDay)
    {
        write-host "Folder has been Updated within the $daysold day(s)"
    }
    else
    {
        write-host "Folder has not been Updated more than $daysold day(s), since"(Get-ItemProperty -Path $targetff -Name LastWriteTime).LastWriteTime
    }
    # start-sleep -seconds 300
#}