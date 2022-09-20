<#
=================================================================================
Script Name:        Audit: Get DNS Entries Of An Endpoint.
Description:        Get local admins from the windows computer.
Lastest version:    2022-04-21
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
# Set the variable $localUsersOnly = $false if you need also collect Domain's members of the Administrators group
$localUsersOnly = $true
$theLocalAdminGroup = try { Get-WmiObject -Class Win32_Group -Filter 'SID = "S-1-5-32-544"'} catch { $null }
if( $null -ne $theLocalAdminGroup )
{
    [string[]]$admins = @()
    #query WMI to get the group's members
    [string]$query = "GroupComponent = `"Win32_Group.Domain='" + $theLocalAdminGroup.Domain + "',NAME='" + $theLocalAdminGroup.Name + "'`""
    #The group members are read from the query results. Regex to extract useful info from the query output
    [string]$regexp = '\"\S+\",Name=\"(.+?)\"$'
    $admins =  try {
        Get-WmiObject win32_groupuser -Filter $query | Select -ExpandProperty PartComponent | `
        ForEach-Object{ [regex]::match($_,$regexp).Groups[0].Value -replace '",Name="', '\' -replace '"', ''} | Sort-Object
    } catch { $null }
    if ( $null -ne $admins )
    {
        if ( $localUsersOnly )
        {
            $admins = $admins | Where-Object {$_ -match "^$($env:COMPUTERNAME)"}
        }
        #remove host name from local accounts
        $admins = $admins | ForEach-Object{ $_ -replace "$env:COMPUTERNAME\\", ''}
        if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
        if (-not [string]::IsNullOrEmpty( $Path ) ) { $FileName = "$Path\$FileName" }
        $currentDate = Get-Date -UFormat "%m/%d/%Y %T"
        [array]$outputArray = @()
        $admins | ForEach-Object {
            $outputArray += [pscustomobject]@{
                Hostname = $env:COMPUTERNAME
                'Group name' = $($theLocalAdminGroup.Name)
                Administrator = $_
                Date = $currentDate
            }
        }
        $outputArray | Write-Output
    }
}