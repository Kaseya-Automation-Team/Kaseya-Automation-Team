#region class Wallpaper
Add-Type @' 
using System.Runtime.InteropServices; 
namespace Win32{ 
    
     public class Wallpaper{ 
        [DllImport("user32.dll", CharSet=CharSet.Auto)] 
         static extern int SystemParametersInfo (int uAction , int uParam , string lpvParam , int fuWinIni) ; 
         
         public static void SetWallpaper(string thePath){ 
            SystemParametersInfo(20,0,thePath,3); 
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

        Set-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Desktop") -Name "Wallpaper" -Value ''
        Set-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Colors") -Name "Background" -Value '0 0 0'
        
        [Win32.Wallpaper]::SetWallpaper("")
        [gc]::Collect()
        reg unload "HKU\$($_.SID)"
    }
#endregion Set wallpaper