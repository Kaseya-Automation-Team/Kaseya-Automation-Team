<#
=================================================================================
Script Name:        Management: Log all the users off.
Description:        Logoff all the local users logged on to the machine.
Lastest version:    2022-04-27
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>

$scriptBlock = {

     $ErrorActionPreference = 'Stop'

     try {

         ## Find all sessions that are logged in
         $sessions = quser | Where-Object { $_ -match '(\d+)\s+Active' }

         ## Parse the session IDs from the output
         $sessionIds = ($sessions -split ' +')[2]
         Write-Host "Found $(@($sessionIds).Count) user login(s) on computer."

         ## Loop through each session ID and pass each to the logoff command
         $sessionIds | ForEach-Object {logoff $_ }

     } catch {

         if ($_.Exception.Message -match 'No user exists') {Write-Host "The user is not logged in."} 
         
         else {throw $_.Exception.Message}
     }
 }

 ## Run the scriptblock's code on the remote computer
Invoke-Command -ComputerName localhost -ScriptBlock $scriptBlock