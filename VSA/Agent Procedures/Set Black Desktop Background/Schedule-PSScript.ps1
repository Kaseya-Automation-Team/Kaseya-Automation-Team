param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $ScheduledTaskAction,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $TaskName,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [int] $DelaySeconds = 10
)

#region Get logged in users
[string] $SIDPattern = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'

$LoggedInUsers = @()

$LoggedInUsersSIDs = Get-ChildItem Registry::HKEY_USERS | `
    Where-Object {$_.PSChildname -match $SIDPattern} | `
    Select-Object -ExpandProperty PSChildName

if ( 0 -ne $LoggedInUsersSIDs.Length )
{
    Foreach ( $SID in $LoggedInUsersSIDs )
    {
        $Account = New-Object Security.Principal.SecurityIdentifier("$SID")
        $NetbiosName = $(  try { $Account.Translate([Security.Principal.NTAccount]) | Select-Object -ExpandProperty Value } catch { $_.Exception.Message } )

        if ( $NetbiosName -notmatch 'Exception' )
        {
            $LoggedInUsers += $NetbiosName
        }
    }
}
#endregion Get logged in users

if ( 0 -ne $LoggedInUsers.Length )
{
    
    Foreach ( $UserPrincipal in $LoggedInUsers )
    {
        $TaskName = "RunOnce-$TaskName-$($UserPrincipal.Replace('\', '.') )"
        $TaskParameters = @{
            TaskName = $TaskName
            Trigger = New-ScheduledTaskTrigger -Once -At $( (Get-Date).AddSeconds($DelaySeconds) )
            Principal = New-ScheduledTaskPrincipal -UserId $UserPrincipal
            Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $ScheduledTaskAction
        }

        if ( $null -eq $(try {Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop} Catch {$null}) )
        {
            Register-ScheduledTask @TaskParameters
        }
        else
        {
            Set-ScheduledTask @TaskParameters
        }
    }
}