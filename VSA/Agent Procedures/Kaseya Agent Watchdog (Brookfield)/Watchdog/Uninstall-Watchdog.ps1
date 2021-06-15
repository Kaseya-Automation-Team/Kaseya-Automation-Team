$isInstalled = Get-ScheduledTask -TaskName "Kaseya Agent Watchdog" -ErrorAction SilentlyContinue

if ($isInstalled) {
    Write-Host "Kaseya Agent Watchdog task has been found and will be removed."

    try {
        Unregister-ScheduledTask -TaskName "Kaseya Agent Watchdog" -Confirm:$false -ErrorAction Stop
    } catch {
        Write-Host "Unable to delete task:"
        Write-Host $_.Exception.Message
    }

    Write-Host "Kaseya Agent Watchdog task has been successfully removed."
} else {
    Write-Host "Kaseya Agent task wasn't found on this computer."
}