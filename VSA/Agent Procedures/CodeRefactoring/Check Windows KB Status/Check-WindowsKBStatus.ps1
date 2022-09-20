<#
=================================================================================
Script Name:        Audit: Check Windows KB Status
Description:        Part of Upstream Fully Managed Workplace
Lastest version:    2022-06-01
=================================================================================



Required variable inputs:
The kb variable shoud be assigned



Required variable outputs:
None
#>
# Assign the KB number to the variable below

$kb = "KB5013942"


IF ($kb.Contains("kb"))
{ 
    $kb = $kb.Replace("kb","") 
    $kb = 'KB' + $kb
}



if ($kb -eq (get-hotfix | Where-Object HotFixID -Like $kb | Select-Object HotFixID | ft -hidetableheaders | Out-String).trim())
{
    $date = (get-hotfix | Where-Object HotFixID -Like $kb | Select-Object InstalledOn | ft -hidetableheaders | Out-String).trim()
    
    Write-Output "$kb was installed on $date"
    eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "$kb was installed on $date" | Out-Null

}

else {

    Write-Output "$kb was not installed on this computer!"
    eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "$kb was not installed on this computer!" | Out-Null
}