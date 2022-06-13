<#
.Synopsis
   Sets desired desktop background for all users.
.DESCRIPTION
   Sets desired desktop background for all users.
   Used by the "Set Desktop Background for All Users" Agent Procedure
.PARAMETER R
    Specifies level of Red color. Vaild Range 0-255
.PARAMETER G
    Specifies level of Green color. Vaild Range 0-255
.PARAMETER B
    Specifies level of Blue color. Vaild Range 0-255
.PARAMETER WallpaperPath
    Specifies full local path to the image file to be set as desktop wallpaper.
.PARAMETER LogIt
    Specifies whether to log script execution transcript.
.EXAMPLE
   .\Set-DesktopBackground.ps1 -R 255 -G 255 -B 255
.EXAMPLE
   .\Set-DesktopBackground.ps1 -WallpaperPath "c:\windows\web\wallpaper\theme1\img2.jpg"
.NOTES
   Version 0.1
   Author: Proserv Team - VS
   requires -version 5.1
#>

param (
    [parameter(Mandatory=$false,
    ValueFromPipelineByPropertyName=$true)]
    [ValidateRange(0, 255)]
    [int] $R = 0,

    [parameter(Mandatory=$false,
    ValueFromPipelineByPropertyName=$true)]
    [ValidateRange(0, 255)]
    [int] $G = 0,

    [parameter(Mandatory=$false,
    ValueFromPipelineByPropertyName=$true)]
    [ValidateRange(0, 255)]
    [int] $B = 0,

    [parameter(Mandatory=$false,
    ValueFromPipelineByPropertyName=$true)]
    [string] $WallpaperPath = '',

    [parameter(Mandatory=$false,
    ValueFromPipelineByPropertyName=$true)]
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
[string] $TypeDefinition = @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Desktop { 
    public class Background { 
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        private static extern int SystemParametersInfo(int uAction, int uParm, string lpvParam, int fuWinIni);
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        private static extern int SetSysColors(int cElements, int[] lpaElements, int[] lpRgbValues);

        public const int COLOR_DESKTOP = 1;
        public int[] first = {COLOR_DESKTOP};

        public static void SetWallPaper(string thePath)
        {
            SystemParametersInfo( 0x0014, 0, thePath, 0x02 | 0x01 );
        }
        public static void SetBackground(byte r, byte g, byte b, string thePath)
        {
            int[] elements = {COLOR_DESKTOP};            
            if(string.IsNullOrEmpty(thePath))
            {
                System.Drawing.Color color = System.Drawing.Color.FromArgb(r,g,b);
                int[] colors = { System.Drawing.ColorTranslator.ToWin32(color) };
    
                SetSysColors(elements.Length, elements, colors);
            }        
            else
            {
                SetWallPaper(thePath);
            }
            
        }
    }
} 
'@
[hashtable] $AddTypeParams = @{
    TypeDefinition = $TypeDefinition
    ReferencedAssemblies = "System.Drawing.dll"
}
Add-Type @AddTypeParams
#endregion class Wallpaper

[string] $SIDPattern = 'S-1-5-21-(\d+-?){4}$'

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
        Set-RegParam -RegPath $(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Colors\Background") -RegValue $("{0} {1} {2}" -f $R, $G, $B) -ValueType String -UpdateExisting
        
        [Desktop.Background]::SetBackground($R, $G, $B, $WallpaperPath)
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