#region initialization
 param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
    [string]$FileName = "",
    [parameter(Mandatory=$true)]
    #[ValidateScript({
    #if( -Not ($_ | Test-Path) ){
    #    throw "Provided path does not exist" 
    #}
    #return $true
    #})]
    [string]$Path = "",
	[Switch]$localUsersOnly
 )

    if (-not [string]::IsNullOrEmpty( $FileName ) ) { $FileName = $FileName.Trim()}
    if (-not [string]::IsNullOrEmpty( $Path ) ) { $Path = $Path.Trim()}
    if (-not [string]::IsNullOrEmpty( $AgentName ) ) { $AgentName = $AgentName.Trim()}
    

[hashtable] $theParameters = @{AgentName = $AgentName
                                Path= $Path
                                FileName = $FileName
                                localUsersOnly = $localUsersOnly
                            }

    #Make sure that the existing output file deleted before collecting the data
    if(Test-Path "$Path\$FileName") {Remove-Item "$Path\$FileName" -Force}
#endregion initialization

<#
.Synopsis
   Saves local administrators list to a csv
.DESCRIPTION
   Gets the local admininistrators group members and saves information of the host, the administators group name, 
    member's account, agent name and current datatime into the csv-file
    The script has parameters  FileName, Path, AgentName and switch localUsersOnly
    The parameters FileName, Path, AgentName are mandatory.
    By default the script gets all the local administrators, including AD domain objects
.EXAMPLE
   Get-LocalAdmins -FileName 'localadmins.csv' -Path 'C:\TEMP' -AgentName '123456'
   Gets all the local administrators and saves the list to the localadmins.csv in the C:\TEMP folder
.EXAMPLE
   Get-LocalAdmins -FileName 'localadmins.csv' -Path 'C:\TEMP' -AgentName '123456' -localUsersOnly
   Gets local users only. AD Domain objects are skipped 
.NOTES
   Version 0.1
   Author: Vladislav Semko
   Email: Vladislav.Semko@kaseya.com
#>
function Get-LocalAdmins
{
    [CmdletBinding()]
    Param
    (
        #The output file name
        [parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)] 
        [string] $FileName,
        #Domain users and groups are included to the output by default
        [parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)] 
        [string] $Path,
        #Agent Identifier
        [parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)] 
        [string] $AgentName,
        #Local & domain by default
        [switch] $localUsersOnly
        
    )

    <#
    By design:
    - Windows local groups cannot be nested. However, domain groups can be added to local groups.
    - There can be the only one Local Administrators group.
    - The Local Administrators group always has the same SID, regardles of Locale setting or OS version
    #>
    $theLocalAdminGroup = try { Get-WmiObject -Class Win32_Group -Filter 'SID = "S-1-5-32-544"'} catch { $null }
    if( $null -ne $theLocalAdminGroup )
    {
        [string[]]$admins = @()

        #query WMI to get the group's members
        [string]$query = "GroupComponent = `"Win32_Group.Domain='" + $theLocalAdminGroup.Domain + "',NAME='" + $theLocalAdminGroup.Name + "'`""

        #The group members are read from the query results. Regex to extract useful info from the query output
        [string]$regexp = '\"\S+\",Name=\"(.+?)\"$'

        $admins =  try {
            (Get-WmiObject win32_groupuser -Filter $query).PartComponent | 
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

            $currentDate = Get-Date -UFormat “%m/%d/%Y %T”

            [array]$outputArray = @()
            $admins | ForEach-Object {
                $outputArray += [pscustomobject]@{
                    AgentGuid = $AgentName
                    Hostname = $env:COMPUTERNAME
                    'Group name' = $($theLocalAdminGroup.Name)
                    Administrator = $_
                    Date = $currentDate
                }
            }
            $outputArray | Export-Csv -Path $FileName -Encoding UTF8 -NoTypeInformation
        }
    }
}

Get-LocalAdmins @theParameters