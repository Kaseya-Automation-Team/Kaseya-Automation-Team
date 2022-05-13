<#
    Sets desired solid color desktop background for all users.
#>

[int] $R = 0  #           Specifies level of Red color. Vaild Range 0-255
[int] $G = 0 #            Specifies level of Green color. Vaild Range 0-255
[int] $B = 0 #            Specifies level of Blue color. Vaild Range 0-255

[int] $DelaySeconds = 5 # Specifies scheduled script delay in seconds

#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
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

        #Find & remove applied GPO Wallpaper settings

        #Apply New Settings
        Set-RegParam -RegPath $(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Desktop\Wallpaper") -RegValue '' -ValueType String -UpdateExisting
        Set-RegParam -RegPath $(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Colors\Background") -RegValue $("{0} {1} {2}" -f $R, $G, $B) -ValueType String -UpdateExisting
        
        #[Desktop.Background]::SetBackground($R, $G, $B)
        [gc]::Collect()
        (reg unload "HKU\$($_.SID)" ) 2> $null
    }
#endregion iterate users' registry and make changes

[System.Diagnostics.EventLog]::WriteEntry("VSA X", "Solid color RGB($R,$G,$B) Desktop background applied for all users' registry hives", "Information", 200)

#region Generate sceduled script
[string] $ScheduledTaskAction = @"
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
"@
[string] $EncodedTaskAction = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ScheduledTaskAction))
#endregion Generate sceduled script

[string[]]$LoggedUsers = Get-LoggedOnUser | Where-Object {$_.Type -eq 'Interactive' -and ($_.Auth -in @('NTLM', 'Kerberos'))} | Select-Object -ExpandProperty User -Unique

#region schedule script for logged on users
Foreach ( $UserPrincipal in $LoggedUsers ) {
    $At = $( (Get-Date).AddSeconds($DelaySeconds) )
    $TaskName = "RunOnce-$TaskName-$($UserPrincipal.Replace('\', '.') )"
    "PowerShell.exe $ScheduledTaskAction" | Write-Debug
    $TaskParameters = @{
        TaskName = $TaskName
        Trigger = New-ScheduledTaskTrigger -Once -At $At
        Principal = New-ScheduledTaskPrincipal -UserId $UserPrincipal
        Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -EncodedCommand $EncodedTaskAction"
    }

    if ( $null -eq $(try {Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop} Catch {$null}) ) {
        Register-ScheduledTask @TaskParameters
    } else {
        Set-ScheduledTask @TaskParameters
    }
}
#endregion schedule script for logged on users