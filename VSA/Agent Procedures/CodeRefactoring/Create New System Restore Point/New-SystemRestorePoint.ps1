<#
=================================================================================
Script Name:        Management: Create New System Restore Point
Description:        Enables system restore functionality and then creates new system restore point, if there is no any created within last 24 hours.
Lastest version:    2022-09-20
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>

#Turn on system restore feature
Enable-ComputerRestore $env:SystemDrive

#Create system restore point
try {
    Checkpoint-Computer -Description "VSAXRestore"
	eventcreate /L Application /T INFORMATION /SO "VSA X" /ID 200 /D "System Restore point has been created by VSA X."
} catch {
    Write-Error $_.Exception.Message
	eventcreate /L Application /T ERROR /SO "VSA X" /ID 400 /D "$_.Exception.Message"
}