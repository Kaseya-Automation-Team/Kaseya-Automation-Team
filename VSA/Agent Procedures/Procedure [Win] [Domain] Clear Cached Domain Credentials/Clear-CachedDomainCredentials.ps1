#region Get Cached Domain credentials
Write-Debug 'Collecting cached credentials'
[string[]]$RawOutput = cmdkey /list

$Result = @()
#structurize output data
foreach ( $Entry in $RawOutput )
{
    if ( -not [string]::IsNullOrEmpty($Entry) ) {
        $Entry = $Entry.Trim()

        if ($Entry.Contains('Target: ')) {
            $Target = $Entry.Replace('Target: ', '')
        }
        if ($Entry.Contains('Type: ')) {
            $TargetType = $Entry.Replace('Type: ', '')
        }
        if ($Entry.Contains('User: ')) {
            $User = $Entry.Replace('User: ', '')

            $Result += [PSCustomObject]@{
                Target = $Target
                Type   = $TargetType
                User   = $User}
        }
    } # ( -not [string]::IsNullOrEmpty($Entry) )
}

#Filter Cached Domain credentials
$Result = $Result | Where-Object {$_.Type -match "^Domain"}
#endregion Get Cached Domain credentials

#region Clear Cached Domain credentials
#Write-Debug 'Deleting cached credentials'
foreach ( $Entry in $Result ) {
    #Write-Debug $($Entry.User)
    cmdkey /delete:$($Entry.Target)
}
#endregion Clear Cached Domain credentials