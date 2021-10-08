$kb = $args[0]
$workDir = $args[1]

IF ($kb.Contains("KB"))
{ 
    $kb = $kb.Replace("KB","") 
}

$kb = 'KB' + $kb

if ($kb -eq (get-hotfix | Where-Object HotFixID -Like $kb | Select-Object HotFixID | ft -hidetableheaders | Out-String).trim())
{
    $date = (get-hotfix | Where-Object HotFixID -Like $kb | Select-Object InstalledOn | ft -hidetableheaders | Out-String).trim()
    
    echo "$kb was installed on $date" | Out-File $workdir\$kb.txt
}