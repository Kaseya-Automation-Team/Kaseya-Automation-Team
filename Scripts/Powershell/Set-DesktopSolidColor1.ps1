<#
.Synopsis
   Sets desired desktop background for all users.
.DESCRIPTION
   To change the desktop background for already logged in users, the script also creates scheduled tasks that will run once for each of the logged in users to apply the changes
.NOTES
   Version 0.1
   Author: Proserv Team - VS
   requires -version 5.1
#>

#Specifies level of Red color. Vaild Range 0-255
[int] $R = 40
#Specifies level of Green color. Vaild Range 0-255
[int] $G = 150
#Specifies level of Blue color. Vaild Range 0-255
[int] $B = 255
#Specifies scheduled script delay in seconds
[int]$DelaySeconds = 15

$SolidDesktopScheduledScript = Join-Path -Path $env:PUBLIC -ChildPath "SetSolidBkg.ps1"

#Create VSAX Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSAX")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSAX", "Application")
}

#region function Set-RegParam
function Set-RegParam {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=0)]
        [string] $RegPath,

        [parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=1)]
        [AllowEmptyString()]
        [string] $RegValue,

        [parameter(Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=2)]
        [ValidateSet('Binary', 'DWord', 'ExpandString', 'MultiString', 'None', 'QWord', 'String', 'Unknown')]
        [string] $ValueType = 'String',

        [parameter(Mandatory=$false)]
        [Switch] $UpdateExisting
    )
    
    begin {
        [string] $RegKey = Split-Path -Path Registry::$RegPath -Parent
        [string] $RegProperty = Split-Path -Path Registry::$RegPath -Leaf
    }
    process {
            #Create key
            if( -not (Test-Path -Path $RegKey) )
            {
                try {
                    New-Item -Path $RegKey -Force -Verbose -ErrorAction Stop
                } catch { Write-Error $_.Exception.Message}
                #Create property
                try {
                    New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -Verbose -ErrorAction Stop
                } catch { Write-Error $_.Exception.Message}
            }            
            else
            {
                $Poperty = try {Get-ItemProperty -Path Registry::$RegPath -Verbose -ErrorAction Stop | Out-Null} catch { $null}
                if ($null -eq $Poperty )
                {
                     #Create property
                    try {
                        New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -Verbose -ErrorAction Stop
                    } catch { Write-Error $_.Exception.Message}
                }
                #Assign value to the property
                if( $UpdateExisting )
                {
                    try {
                            Set-ItemProperty -Path $RegKey -Name $RegProperty -Value $RegValue -Force -Verbose -ErrorAction Stop
                        } catch {Write-Error $_.Exception.Message}
                }
            }
    }
}
#endregion function Set-RegParam

#region function Get-LoggedOnUser
function Get-LoggedOnUser () {

    $regexa = '.+Domain="(.+)",Name="(.+)"$'
    $regexd = '.+LogonId="(\d+)"$'

    $logontype = @{
        "0"="Local System"
        "2"="Interactive" #(Local logon)
        "3"="Network" # (Remote logon)
        "4"="Batch" # (Scheduled task)
        "5"="Service" # (Service account logon)
        "7"="Unlock" #(Screen saver)
        "8"="NetworkCleartext" # (Cleartext network logon)
        "9"="NewCredentials" #(RunAs using alternate credentials)
        "10"="RemoteInteractive" #(RDP\TS\RemoteAssistance)
        "11"="CachedInteractive" #(Local w\cached credentials)
    }

    $LogonSessions = @(Get-WmiObject win32_logonsession)
    $LogonUsers = @(Get-WmiObject win32_loggedonuser)

    $SessionUser = @{}

    $LogonUsers | ForEach-Object {
        $_.antecedent -match $regexa | Out-Null
        $username = $matches[1] + "\" + $matches[2]
        $_.dependent -match $regexd | Out-Null
        $session = $matches[1]
        $SessionUser[$session] += $username
    }


    $LogonSessions | ForEach-Object {
        $StartTime = [management.managementdatetimeconverter]::todatetime($_.StartTime)

        $LoggedOnUsers = New-Object -TypeName psobject
        $LoggedOnUsers | Add-Member -MemberType NoteProperty -Name "Session" -Value $_.logonid
        $LoggedOnUsers | Add-Member -MemberType NoteProperty -Name "User" -Value $SessionUser[$_.logonid]
        $LoggedOnUsers | Add-Member -MemberType NoteProperty -Name "Type" -Value $logontype[$_.logontype.tostring()]
        $LoggedOnUsers | Add-Member -MemberType NoteProperty -Name "Auth" -Value $_.authenticationpackage
        $LoggedOnUsers | Add-Member -MemberType NoteProperty -Name "StartTime" -Value $StartTime

        Write-Output $LoggedOnUsers
    }
}
#endregion function Get-LoggedOnUser

[string] $SIDPattern = 'S-1-5-21-(\d+-?){4}$'

#region iterate users' registry and make changes
Get-CimInstance Win32_UserProfile | Where-Object {$_.SID -match $SIDPattern} | Select-Object LocalPath, SID | `
    ForEach-Object {
        $UserProfilePath = $_.LocalPath
  
        reg load "HKU\$($_.SID)" "$UserProfilePath\ntuser.dat"
        [System.Diagnostics.EventLog]::WriteEntry("VSAX", "Registry file $UserProfilePath\ntuser.dat is being processed", "Information", 200)

        #Find & remove applied GPO Wallpaper settings

        #Apply New Settings
        Set-RegParam -RegPath $(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Desktop\Wallpaper") -RegValue '' -ValueType String -UpdateExisting
        Set-RegParam -RegPath $(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Colors\Background") -RegValue $("{0} {1} {2}" -f $R, $G, $B) -ValueType String -UpdateExisting
        
        #[Desktop.Background]::SetBackground($R, $G, $B)
        [gc]::Collect()
        (reg unload "HKU\$($_.SID)" ) 2> $null
    }
#endregion iterate users' registry and make changes

#region Generate sceduled script
$ScheduledTaskAction = @"
`$typeDef = @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Desktop { 
    public class Background { 
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        private static extern int SetSysColors(int cElements, int[] lpaElements, int[] lpRgbValues);

        public const int COLOR_DESKTOP = 1;
        public int[] first = {COLOR_DESKTOP};

        public static void SetBackground(byte r, byte g, byte b)
        {
            int[] elements = {COLOR_DESKTOP};            
            System.Drawing.Color color = System.Drawing.Color.FromArgb(r,g,b);
            int[] colors = { System.Drawing.ColorTranslator.ToWin32(color) };
            SetSysColors(elements.Length, elements, colors);
        }
    }
}
'@
Add-Type -TypeDefinition `$typeDef -ReferencedAssemblies "System.Drawing.dll"
[Desktop.Background]::SetBackground($R, $G, $B)
"@ | Out-File $SolidDesktopScheduledScript -Force
#endregion Generate sceduled script

[string[]]$LoggedUsers = Get-LoggedOnUser | Where-Object {$_.Type -eq 'Interactive' -and ($_.Auth -in @('NTLM', 'Kerberos'))} | Select-Object -ExpandProperty User -Unique
[System.Diagnostics.EventLog]::WriteEntry("VSAX", "Logged on users:`n$($LoggedUsers | Out-String)", "Information", 200)

#region schedule script for logged on users
Foreach ( $UserPrincipal in $LoggedUsers ) {
    $At = $( (Get-Date).AddSeconds($DelaySeconds) )
    $TaskName = "RunOnce-$TaskName-$($UserPrincipal.Replace('\', '.') )"
    [System.Diagnostics.EventLog]::WriteEntry("VSAX", "Creating scheduled task $TaskName for user $UserPrincipal at $At", "Information", 200)
    "PowerShell.exe $ScheduledTaskAction" | Write-Debug
    $TaskParameters = @{
        TaskName = $TaskName
        Trigger = New-ScheduledTaskTrigger -Once -At $At
        Principal = New-ScheduledTaskPrincipal -UserId $UserPrincipal
        Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -command $SolidDesktopScheduledScript"
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
#endregion schedule script for logged on users