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

$BGInfoScheduledScript = Join-Path -Path $env:PUBLIC -ChildPath "SetBGInfoBkg.ps1"

# Configuration:

# Font Family name
$font="Input"
# Font size in pixels
$size=10.0
# spacing in pixels
$textPaddingLeft = 10
$textPaddingTop = 10
$textItemSpace = 3


# Get local info to write out to wallpaper
$os = Get-CimInstance Win32_OperatingSystem
$release = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId
$cpu = Get-CimInstance -Class CIM_Processor -Property Name | Select-Object -ExpandProperty Name
#$BootTimeSpan = $(New-TimeSpan -Start $os.LastBootUpTime -End (Get-Date))
[string[]] $IPs = Get-NetIPAddress | Where-Object {$_.PrefixOrigin -ne "WellKnown" -and  $_.AddressFamily -eq "IPv4"} | Select-Object -Property @{ Name = 'IP'; Expression = {  "$($_.IPAddress)/$($_.PrefixLength)" }} | Select-Object -ExpandProperty IP| Out-String
[string[]] $Volumes = Get-Disk | Get-Partition | Get-Volume | Where-Object {$_.DriveLetter -match '[a-zA-Z]'} | `                    Select-Object DriveLetter, Size, FileSystemType | `                    ForEach-Object { Write-Output "$($_.DriveLetter):\`t$( "{0:N2}" -f ($($_.Size) / 1Gb) ) Gb`t$($_.FileSystemType)"}

$BGInfo = ([ordered]@{
    Host = "$($os.CSName) `n$($os.Description)"
    CPU = $cpu
    RAM = "$([math]::round($os.TotalVisibleMemorySize / 1MB))GB"
    OS = "$($os.Caption) `n$($os.OSArchitecture), $($os.Version), $release"
    Volumes = $Volumes
    Boot = $os.LastBootUpTime
    #Uptime = "$($BootTimeSpan.Days) days, $($BootTimeSpan.Hours) hours"
    Snapshot = $os.LocalDateTime
    IP = $IPs
})

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

#region New-ImageInfo
Function New-ImageInfo {
    param(  
        [Parameter(Mandatory=$True, Position=1)]
        [object] $data,
        [Parameter(Mandatory=$False)]
        [string] $InputImage= $(try {Get-ItemProperty -Path Registry::'HKCU\Control Panel\Desktop\' -Name Wallpaper -ErrorAction Stop | Select-Object -ExpandProperty WallPaper} catch { $null}),
        [string] $font="Courier New",
        [float] $size=12.0,
        [float] $textPaddingLeft = 0,
        [float] $textPaddingTop = 0,
        [float] $textItemSpace = 0,
        [string] $OutputImage="out.png" 
    )

    [system.reflection.assembly]::loadWithPartialName('system') | Out-Null
    [system.reflection.assembly]::loadWithPartialName('system.drawing') | Out-Null
    [system.reflection.assembly]::loadWithPartialName('system.drawing.imaging') | Out-Null
    [system.reflection.assembly]::loadWithPartialName('system.windows.forms') | Out-Null

    $foreBrush  = [System.Drawing.Brushes]::White
    $backBrush  = new-object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(192, 0, 0, 0))

    # Create Bitmap
    $SR = [System.Windows.Forms.Screen]::AllScreens | Where-Object Primary | Select-Object -ExpandProperty Bounds | Select-Object Width, Height

    $background = new-object system.drawing.bitmap( $($SR.Width), $($SR.Height) )

    $bmp = new-object system.drawing.bitmap ( $InputImage )

    # Create Graphics
    $image = [System.Drawing.Graphics]::FromImage($background)

    # Paint image's background
    $rect = new-object system.drawing.rectanglef(0, 0, $SR.width, $SR.height)
    $image.FillRectangle($backBrush, $rect)

    # add in image
    $topLeft = new-object System.Drawing.RectangleF(0, 0, $SR.Width, $SR.Height)
    $image.DrawImage($bmp, $topLeft)

    # Draw string
    $strFrmt = new-object system.drawing.stringformat
    $strFrmt.Alignment = [system.drawing.StringAlignment]::Near
    $strFrmt.LineAlignment = [system.drawing.StringAlignment]::Near

    $taskbar = [System.Windows.Forms.Screen]::AllScreens
    $taskbarOffset = $taskbar.Bounds.Height - $taskbar.WorkingArea.Height

    # first get max key & val widths
    $maxKeyWidth = 0
    $maxValWidth = 0
    $textBgHeight = 0 + $taskbarOffset
    $textBgWidth = 0

    # a reversed ordered collection is used since it starts from the bottom
    $reversed = [ordered]@{}

    foreach ($Item in $data.GetEnumerator()) {
        $valString = "$($Item.Value)"
        $valFont = New-Object System.Drawing.Font($font, $size, [System.Drawing.FontStyle]::Regular)
        $valSize = [system.windows.forms.textrenderer]::MeasureText($valString, $valFont)
        $maxValWidth = [math]::Max($maxValWidth, $valSize.Width)

        $keyString = "$($Item.Name): "
        $keyFont = New-Object System.Drawing.Font($font, $size, [System.Drawing.FontStyle]::Bold)
        $keySize = [system.windows.forms.textrenderer]::MeasureText($keyString, $keyFont)
        $maxKeyWidth = [math]::Max($maxKeyWidth, $keySize.Width)

        $maxItemHeight = [math]::Max($valSize.Height, $keySize.Height)
        $textBgHeight += ($maxItemHeight + $textItemSpace)

        $reversed.Insert(0, $Item.Name, $Item.Value)
    }

    $textBgWidth = $maxKeyWidth + $maxValWidth + $textPaddingLeft
    $textBgHeight += $textPaddingTop
    $textBgX = $SR.Width - $textBgWidth
    $textBgY = $SR.Height - $textBgHeight

    $textBgRect = New-Object System.Drawing.RectangleF($textBgX, $textBgY, $textBgWidth, $textBgHeight)
    $image.FillRectangle($backBrush, $textBgRect)

    $i = 0
    $cumulativeHeight = $SR.Height - $taskbarOffset

    foreach ($Item in $reversed.GetEnumerator()) {
        $valString = "$($Item.Value)"
        $valFont = New-Object System.Drawing.Font($font, $size, [System.Drawing.FontStyle]::Regular)
        $valSize = [system.windows.forms.textrenderer]::MeasureText($valString, $valFont)

        $keyString = "$($Item.Name): "
        $keyFont = New-Object System.Drawing.Font($font, $size, [System.Drawing.FontStyle]::Bold)
        $keySize = [system.windows.forms.textrenderer]::MeasureText($keyString, $keyFont)

        $maxItemHeight = [math]::Max($valSize.Height, $keySize.Height) + $textItemSpace

        $valX = $SR.Width - $maxValWidth
        $valY = $cumulativeHeight - $maxItemHeight

        $keyX = $valX - $maxKeyWidth
        $keyY = $valY
        
        $valRect = New-Object System.Drawing.RectangleF($valX, $valY, $maxValWidth, $valSize.Height)
        $keyRect = New-Object System.Drawing.RectangleF($keyX, $keyY, $maxKeyWidth, $keySize.Height)

        $cumulativeHeight = $valRect.Top

        $image.DrawString($keyString, $keyFont, $foreBrush, $keyRect, $strFrmt)
        $image.DrawString($valString, $valFont, $foreBrush, $valRect, $strFrmt)
    }

    # Close Graphics
    $image.Dispose();

    # Save and close Bitmap
    $background.Save($OutputImage, [system.drawing.imaging.imageformat]::Png);
    $background.Dispose();
    $bmp.Dispose();

    # Output file
    Get-Item -Path $OutputImage
}
#region New-ImageInfo

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

#region iterate users' registry and make changes
[string] $SIDPattern = 'S-1-5-21-(\d+-?){4}$'

Get-CimInstance Win32_UserProfile | Where-Object {$_.SID -match $SIDPattern} | Select-Object LocalPath, SID | `
    ForEach-Object {
        $UserProfilePath = $_.LocalPath
        $ProfileSID = $_.SID

        reg load "HKU\$($_.SID)" "$UserProfilePath\ntuser.dat"

        [string] $PicturesPath = Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") -Name "My Pictures" | Select-Object -ExpandProperty "My Pictures"
        <#
        Typically, the path to the user's TEMP folder in the registry contains a relative path that refers to the USERPROFILE system variable.
        When the registry value is read, the runtime automatically places the running process owner's profile path in the USERPROFILE variable.
        Therefore, to get the correct path to the user's TEMP folder, the registry value referencing USERPROFILE must be corrected by replacing the process owner's profile path with the user's profile path.
        #>
        $RunningProcessProfilePath = $env:USERPROFILE

        $PicturesPath = $PicturesPath.Replace($RunningProcessProfilePath, $UserProfilePath)

        $CurrentWallpaper = $(try {Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$ProfileSID" -ChildPath 'Control Panel\Desktop') -Name Wallpaper -ErrorAction Stop | Select-Object -ExpandProperty WallPaper} catch { $null })
        
        #$WallpaperPath = "$PicturesPath\wallpaper"
        $WallpaperPath = $env:PUBLIC

        if(-not (Test-Path $WallpaperPath) ) {
           new-item $WallpaperPath -ItemType Directory -Force
        }
        $NewWallpaper = $(Join-Path -Path $PicturesPath -ChildPath 'wallpaper\BGINFO.jpg')

        #Write-Host "CurrentWallpaper $CurrentWallpaper" -ForegroundColor Cyan 
        if ( -not [string]::IsNullOrEmpty($CurrentWallpaper) )  {
            #$CurrentWallpaper | Write-Host -ForegroundColor Green
            Copy-Item -Path $CurrentWallpaper -Destination $NewWallpaper -Force
        }
        $WallPaper = New-ImageInfo -data $BGInfo -InputImage $NewWallpaper -OutputImage "$WallpaperPath\BGINFO.png" -font $font -size $size -textPaddingLeft $textPaddingLeft -textPaddingTop $textPaddingTop -textItemSpace $textItemSpace

        $BGInfoImage = "$WallpaperPath\BGINFO.png"


        #Apply New Settings

        $WallpaperStyle = 2
        $TileWallpaper = 0
        $Style = 'Stretch'
        switch ( $Style )
        {
            'Center'    { $WallpaperStyle = 0; $TileWallpaper = 0; }
            'Stretch'   { $WallpaperStyle = 2; $TileWallpaper = 0; }
            'Fill'  { $WallpaperStyle = 10; $TileWallpaper = 0; }
            'Tile'  { $WallpaperStyle = 0; $TileWallpaper = 1; }
            'Fit'   { $WallpaperStyle = 6; $TileWallpaper = 0; }
        }
        Write-Host "$WallpaperPath\BGINFO.png" -ForegroundColor Yellow

        Set-RegParam -RegPath $(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Desktop\Wallpaper") -RegValue $BGInfoImage -ValueType String -UpdateExisting
        Set-RegParam -RegPath $(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Desktop\WallpaperStyle") -RegValue $WallpaperStyle -ValueType String -UpdateExisting | Out-Null
        Set-RegParam -RegPath $(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Desktop\TileWallpaper") -RegValue $TileWallpaper -ValueType String -UpdateExisting | Out-Null
        Set-RegParam -RegPath $(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Colors\Background") -RegValue $("{0} {1} {2}" -f $R, $G, $B) -ValueType String -UpdateExisting | Out-Null

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
Add-Type -TypeDefinition `$typeDef -ReferencedAssemblies "System.Drawing.dll"
[Desktop.Background]::SetBackground($R, $G, $B, "$BGInfoImage")
"@ | Out-File $BGInfoScheduledScript -Force
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
        Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -command $BGInfoScheduledScript"
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