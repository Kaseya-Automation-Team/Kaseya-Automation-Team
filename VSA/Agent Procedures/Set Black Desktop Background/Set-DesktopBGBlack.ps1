param (
    [parameter(Mandatory=$false)]
    [string] $WallpaperPath,

    [parameter(Mandatory=$false)]
    [string] $BackgroundRGB = '0 0 0',

    [switch] $LogIt
 )

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
            $RegKey | Write-Debug
            $RegProperty | Write-Debug
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
                $Poperty = try {Get-ItemProperty -Path $RegPath -ErrorAction Stop | Out-Null} catch { $null}
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


 if ([string]::IsNullOrEmpty($WallpaperPath)) {$WallpaperPath = ''}

#region check/start transcript
[string]$Pref = 'Continue'
if ( $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
    $LogFile = "$ScriptPath\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

#region class Wallpaper
Add-Type @' 
using System.Runtime.InteropServices; 
namespace Win32{ 
    
    public class Wallpaper{ 
        [DllImport("user32.dll", CharSet=CharSet.Auto)] 
        static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni) ; 
         
        public static void SetWallpaper(string thePath){ 
            SystemParametersInfo(20,0,thePath,3); 
        }

        private static extern IntPtr SendMessageTimeout(IntPtr hWnd, int Msg, IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, IntPtr lpdwResult);        

        public static void Refresh()
        {
            private static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);
            private const int WM_SETTINGCHANGE = 0x1a;
            private const int SMTO_ABORTIFHUNG = 0x0002;
            SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, IntPtr.Zero, null, SMTO_ABORTIFHUNG, 100, IntPtr.Zero);
        }
    }
 } 
'@
#endregion class Wallpaper

[string] $SIDPattern = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'

#region Set wallpaper
Get-WmiObject Win32_UserProfile | Where-Object {$_.SID -match $SIDPattern} | Select-Object LocalPath, SID | `
    ForEach-Object {
        $UserProfilePath = $_.LocalPath
  
        reg load "HKU\$($_.SID)" "$UserProfilePath\ntuser.dat"

        #Find & remove applied GPO Wallpaper settings
        [string] $PropertyName = 'WallPaper'
        Get-ChildItem -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion") -Recurse -ErrorAction SilentlyContinue | `
                Where-Object {$_.PSPath -match 'Policies'} | `
                ForEach-Object {
                    $Key = $_ 
                    if( $($Key.GetValueNames()) -match $PropertyName)
                    { 
                        try {
                            Remove-ItemProperty -Path Registry::$Key -Name $PropertyName -Force -Verbose -ErrorAction Stop
                            }
                        catch {Write-Error $_.Exception.Message}
                    }
                }

        #Apply New Settings
        Set-RegParam -RegPath $(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Desktop\Wallpaper") -RegValue $WallpaperPath -ValueType String -UpdateExisting
        Set-RegParam -RegPath $(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Colors\Background") -RegValue $BackgroundRGB -ValueType String -UpdateExisting
        
        [Win32.Wallpaper]::SetWallpaper( $WallpaperPath )
        [gc]::Collect()
        reg unload "HKU\$($_.SID)"
    }
#endregion Set wallpaper

#region check/stop transcript
if ( $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript