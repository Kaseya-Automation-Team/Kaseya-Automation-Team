#Get cached credentials
[string[]]$CmdkeyOutput = cmdkey /list | ForEach-Object { $_.Trim() | Write-Output } | Where-Object { -not [string]::IsNullOrEmpty( $_ ) }

$CachedCreds = @()
#Structurize raw cmdkey output 
foreach ( $Entry in $CmdkeyOutput ) {
    if ($Entry.Contains('Target: ')) {
        $Target = $Entry.Replace('Target: ', '')
    }
    if ($Entry.Contains('Type: ')) {
        $TargetType = $Entry.Replace('Type: ', '')
        $CachedCreds += [PSCustomObject]@{
            Target = $Target
            Type   = $TargetType}
    }
}

#Filter Cached Domain credentials & clear
$CachedCreds | Where-Object {$_.Type -match '^Domain'} | ForEach-Object { cmdkey /delete:$($_.Target) }