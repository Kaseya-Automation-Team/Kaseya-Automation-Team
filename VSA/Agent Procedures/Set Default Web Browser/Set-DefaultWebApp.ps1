<#
.Synopsis
   Set Default Web Browser
.DESCRIPTION
   Set Default Web Browser for all users.
.EXAMPLE
   .\Set-DefaultWebApp.ps1 -ProgID ChromeHTML
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
param (
[parameter(Mandatory=$true)]
    [String] $ProgID, 
    [parameter(Mandatory=$false)]
    [Switch] $LogIt
)

#region PS-FTA
<#
.SYNOPSIS
    Set File Type Association Windows 8/10

.DESCRIPTION
    Set File/Protocol Type Association Default Application Windows 8/10

.NOTES
    Version    : 0.1
    Based on   : Danyfirex & Dany3j
  
.EXAMPLE
    Get-FTA
    Show All Application Program Id

.EXAMPLE
    Get-FTA .pdf
    Show Default Application Program Id for an Extension
    
.EXAMPLE
    Set-FTA AcroExch.Document.DC .pdf
    Set Acrobat Reader DC as Default .pdf reader
 
.EXAMPLE
    Set-FTA Applications\SumatraPDF.exe .pdf
    Set Sumatra PDF as Default .pdf reader

.EXAMPLE
    Set-PTA ChromeHTML http
    Set Google Chrome as Default for http Protocol

.EXAMPLE
    Register-FTA "C:\SumatraPDF.exe" .pdf -Icon "shell32.dll,100"
    Register Application and Set as Default for .pdf reader

.LINK
    https://github.com/DanysysTeam/PS-SFTA
    
#>

function Set-FTA {
  
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $ProgId,
  
    [Parameter(Mandatory = $true)]
    [Alias("Protocol")]
    [String]
    $Extension,

    [parameter(Mandatory = $false)]
    [String]
    $SID,

    [String]
    $Icon
    
)
    $RegKey = 'HKCU:'
    if ( -Not [string]::IsNullOrEmpty($SID)) {$RegKey = "HKEY_USERS\$SID"} else { $SID = ((New-Object System.Security.Principal.NTAccount([Environment]::UserName)).Translate([System.Security.Principal.SecurityIdentifier]).value).ToLower()}
    
    if (Test-Path -Path $ProgId) {
      $ProgId = "SFTA." + [System.IO.Path]::GetFileNameWithoutExtension($ProgId).replace(" ", "") + $Extension
    }
  
    Write-Verbose "ProgId: $ProgId"
    Write-Verbose "Extension/Protocol: $Extension"
  
 
    
    function local:Get-UserExperience {
      [OutputType([string])]
        
      $userExperienceSearch = "User Choice set via Windows User Experience"
      $user32Path = [Environment]::GetFolderPath([Environment+SpecialFolder]::SystemX86) + "\Shell32.dll"
      $fileStream = [System.IO.File]::Open($user32Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
      $binaryReader = New-Object System.IO.BinaryReader($fileStream)
      [Byte[]] $bytesData = $binaryReader.ReadBytes(5mb)
      $fileStream.Close()
      $dataString = [Text.Encoding]::Unicode.GetString($bytesData)
      $position1 = $dataString.IndexOf($userExperienceSearch)
      $position2 = $dataString.IndexOf("}", $position1)
  
      Write-Output $dataString.Substring($position1, $position2 - $position1 + 1)
    }
    
  
    function local:Get-HexDateTime {
      [OutputType([string])]
  
      $now = [DateTime]::Now
      $dateTime = [DateTime]::New($now.Year, $now.Month, $now.Day, $now.Hour, $now.Minute, 0)
      $fileTime = $dateTime.ToFileTime()
      $hi = ($fileTime -shr 32)
      $low = ($fileTime -band 0xFFFFFFFFL)
      $dateTimeHex = ($hi.ToString("X8") + $low.ToString("X8")).ToLower()
      Write-Output $dateTimeHex
    }
    
    function Get-Hash {
      [CmdletBinding()]
      param (
        [Parameter( Position = 0, Mandatory = $True )]
        [string]
        $BaseInfo
      )
  
  
      function local:Get-ShiftRight {
        [CmdletBinding()]
        param (
          [Parameter( Position = 0, Mandatory = $true)]
          [long] $iValue, 
              
          [Parameter( Position = 1, Mandatory = $true)]
          [int] $iCount 
        )
      
        if ($iValue -band 0x80000000) {
          Write-Output (( $iValue -shr $iCount) -bxor 0xFFFF0000)
        }
        else {
          Write-Output  ($iValue -shr $iCount)
        }
      }
      
  
      function local:Get-Long {
        [CmdletBinding()]
        param (
          [Parameter( Position = 0, Mandatory = $true)]
          [byte[]] $Bytes,
      
          [Parameter( Position = 1)]
          [int] $Index = 0
        )
      
        Write-Output ([BitConverter]::ToInt32($Bytes, $Index))
      }
      
  
      function local:Convert-Int32 {
        param (
          [Parameter( Position = 0, Mandatory = $true)]
          $Value
        )
      
        [byte[]] $bytes = [BitConverter]::GetBytes($Value)
        return [BitConverter]::ToInt32( $bytes, 0) 
      }
  
      [Byte[]] $bytesBaseInfo = [System.Text.Encoding]::Unicode.GetBytes($baseInfo) 
      $bytesBaseInfo += 0x00, 0x00  
      
      $MD5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
      [Byte[]] $bytesMD5 = $MD5.ComputeHash($bytesBaseInfo)
      
      $lengthBase = ($baseInfo.Length * 2) + 2 
      $length = (($lengthBase -band 4) -le 1) + (Get-ShiftRight $lengthBase  2) - 1
      $base64Hash = ""
  
      if ($length -gt 1) {
      
        $map = @{PDATA = 0; CACHE = 0; COUNTER = 0 ; INDEX = 0; MD51 = 0; MD52 = 0; OUTHASH1 = 0; OUTHASH2 = 0;
          R0 = 0; R1 = @(0, 0); R2 = @(0, 0); R3 = 0; R4 = @(0, 0); R5 = @(0, 0); R6 = @(0, 0); R7 = @(0, 0)
        }
      
        $map.CACHE = 0
        $map.OUTHASH1 = 0
        $map.PDATA = 0
        $map.MD51 = (((Get-Long $bytesMD5) -bor 1) + 0x69FB0000L)
        $map.MD52 = ((Get-Long $bytesMD5 4) -bor 1) + 0x13DB0000L
        $map.INDEX = Get-ShiftRight ($length - 2) 1
        $map.COUNTER = $map.INDEX + 1
      
        while ($map.COUNTER) {
          $map.R0 = Convert-Int32 ((Get-Long $bytesBaseInfo $map.PDATA) + [long]$map.OUTHASH1)
          $map.R1[0] = Convert-Int32 (Get-Long $bytesBaseInfo ($map.PDATA + 4))
          $map.PDATA = $map.PDATA + 8
          $map.R2[0] = Convert-Int32 (($map.R0 * ([long]$map.MD51)) - (0x10FA9605L * ((Get-ShiftRight $map.R0 16))))
          $map.R2[1] = Convert-Int32 ((0x79F8A395L * ([long]$map.R2[0])) + (0x689B6B9FL * (Get-ShiftRight $map.R2[0] 16)))
          $map.R3 = Convert-Int32 ((0xEA970001L * $map.R2[1]) - (0x3C101569L * (Get-ShiftRight $map.R2[1] 16) ))
          $map.R4[0] = Convert-Int32 ($map.R3 + $map.R1[0])
          $map.R5[0] = Convert-Int32 ($map.CACHE + $map.R3)
          $map.R6[0] = Convert-Int32 (($map.R4[0] * [long]$map.MD52) - (0x3CE8EC25L * (Get-ShiftRight $map.R4[0] 16)))
          $map.R6[1] = Convert-Int32 ((0x59C3AF2DL * $map.R6[0]) - (0x2232E0F1L * (Get-ShiftRight $map.R6[0] 16)))
          $map.OUTHASH1 = Convert-Int32 ((0x1EC90001L * $map.R6[1]) + (0x35BD1EC9L * (Get-ShiftRight $map.R6[1] 16)))
          $map.OUTHASH2 = Convert-Int32 ([long]$map.R5[0] + [long]$map.OUTHASH1)
          $map.CACHE = ([long]$map.OUTHASH2)
          $map.COUNTER = $map.COUNTER - 1
        }
  
        [Byte[]] $outHash = @(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
        [byte[]] $buffer = [BitConverter]::GetBytes($map.OUTHASH1)
        $buffer.CopyTo($outHash, 0)
        $buffer = [BitConverter]::GetBytes($map.OUTHASH2)
        $buffer.CopyTo($outHash, 4)
      
        $map = @{PDATA = 0; CACHE = 0; COUNTER = 0 ; INDEX = 0; MD51 = 0; MD52 = 0; OUTHASH1 = 0; OUTHASH2 = 0;
          R0 = 0; R1 = @(0, 0); R2 = @(0, 0); R3 = 0; R4 = @(0, 0); R5 = @(0, 0); R6 = @(0, 0); R7 = @(0, 0)
        }
      
        $map.CACHE = 0
        $map.OUTHASH1 = 0
        $map.PDATA = 0
        $map.MD51 = ((Get-Long $bytesMD5) -bor 1)
        $map.MD52 = ((Get-Long $bytesMD5 4) -bor 1)
        $map.INDEX = Get-ShiftRight ($length - 2) 1
        $map.COUNTER = $map.INDEX + 1
  
        while ($map.COUNTER) {
          $map.R0 = Convert-Int32 ((Get-Long $bytesBaseInfo $map.PDATA) + ([long]$map.OUTHASH1))
          $map.PDATA = $map.PDATA + 8
          $map.R1[0] = Convert-Int32 ($map.R0 * [long]$map.MD51)
          $map.R1[1] = Convert-Int32 ((0xB1110000L * $map.R1[0]) - (0x30674EEFL * (Get-ShiftRight $map.R1[0] 16)))
          $map.R2[0] = Convert-Int32 ((0x5B9F0000L * $map.R1[1]) - (0x78F7A461L * (Get-ShiftRight $map.R1[1] 16)))
          $map.R2[1] = Convert-Int32 ((0x12CEB96DL * (Get-ShiftRight $map.R2[0] 16)) - (0x46930000L * $map.R2[0]))
          $map.R3 = Convert-Int32 ((0x1D830000L * $map.R2[1]) + (0x257E1D83L * (Get-ShiftRight $map.R2[1] 16)))
          $map.R4[0] = Convert-Int32 ([long]$map.MD52 * ([long]$map.R3 + (Get-Long $bytesBaseInfo ($map.PDATA - 4))))
          $map.R4[1] = Convert-Int32 ((0x16F50000L * $map.R4[0]) - (0x5D8BE90BL * (Get-ShiftRight $map.R4[0] 16)))
          $map.R5[0] = Convert-Int32 ((0x96FF0000L * $map.R4[1]) - (0x2C7C6901L * (Get-ShiftRight $map.R4[1] 16)))
          $map.R5[1] = Convert-Int32 ((0x2B890000L * $map.R5[0]) + (0x7C932B89L * (Get-ShiftRight $map.R5[0] 16)))
          $map.OUTHASH1 = Convert-Int32 ((0x9F690000L * $map.R5[1]) - (0x405B6097L * (Get-ShiftRight ($map.R5[1]) 16)))
          $map.OUTHASH2 = Convert-Int32 ([long]$map.OUTHASH1 + $map.CACHE + $map.R3) 
          $map.CACHE = ([long]$map.OUTHASH2)
          $map.COUNTER = $map.COUNTER - 1
        }
      
        $buffer = [BitConverter]::GetBytes($map.OUTHASH1)
        $buffer.CopyTo($outHash, 8)
        $buffer = [BitConverter]::GetBytes($map.OUTHASH2)
        $buffer.CopyTo($outHash, 12)
      
        [Byte[]] $outHashBase = @(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
        $hashValue1 = ((Get-Long $outHash 8) -bxor (Get-Long $outHash))
        $hashValue2 = ((Get-Long $outHash 12) -bxor (Get-Long $outHash 4))
      
        $buffer = [BitConverter]::GetBytes($hashValue1)
        $buffer.CopyTo($outHashBase, 0)
        $buffer = [BitConverter]::GetBytes($hashValue2)
        $buffer.CopyTo($outHashBase, 4)
        $base64Hash = [Convert]::ToBase64String($outHashBase) 
      }
  
      Write-Output $base64Hash
    }
  
    Write-Verbose "Getting Hash For $ProgId   $Extension"
  
    $userExperience = Get-UserExperience
    $userDateTime = Get-HexDateTime
    Write-Debug "UserDateTime: $userDateTime"
    Write-Debug "UserSid: $SID"
    Write-Debug "UserExperience: $userExperience"
  
    $baseInfo = "$Extension$SID$ProgId$userDateTime$userExperience".ToLower()
    Write-Verbose "baseInfo: $baseInfo"
  
    $progHash = Get-Hash $baseInfo
    Write-Verbose "Hash: $progHash"

     
    if ($Icon)
    {
        $keyPath = "$RegKey\SOFTWARE\Classes\$ProgId\DefaultIcon"
        if (Test-Path -Path Registry::$keyPath )
        {
            Remove-Item -Path Registry::$keyPath -Force -Verbose
        }
        New-Item -Path Registry::$keyPath -Force
        New-ItemProperty -Path Registry::$keyPath -Name "" -Value $Icon -PropertyType STRING -Force
    }

#region Handle Extension Or Protocol
    if ($Extension.Contains("."))
    {
        Write-Verbose "Write Registry Extension: $Extension"
        $keyPath = "$RegKey\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$Extension\UserChoice"

    }
    else
    {
        Write-Verbose "Write Registry Protocol: $Extension"
        $keyPath = "$RegKey\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\$Protocol\UserChoice"
    }
    #Apply extension/protocol handler
    if (Test-Path -Path Registry::$keyPath )
    {
        Remove-Item -Path Registry::$keyPath -Force -Verbose
    }
    New-Item -Path Registry::$keyPath -Force
    New-ItemProperty -Path Registry::$keyPath -Name "Hash" -Value $ProgHash -PropertyType STRING -Force
    New-ItemProperty -Path Registry::$keyPath -Name "ProgId" -Value $ProgId -PropertyType STRING -Force
#endregion Handle Extension Or Protocol
}
  
function Set-PTA {
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $ProgId,
  
    [Parameter(Mandatory = $true)]
    [String]
    $Protocol,
    
    [parameter(Mandatory = $false)]
    [String]
    $SID,

    [String]
    $Icon
)
    Set-FTA -ProgId $ProgId -Protocol $Protocol -SID $SID -Icon $Icon
}
#endregion PS-FTA


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

#region Change Users' Hives
[string] $SIDPattern = '^S-1-5-21-(\d+-?){4}$'
[string] $RegKeyUserProfiles = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*'

[array] $ProfileList = Get-ItemProperty -Path Registry::$RegKeyUserProfiles | `
                    Select-Object  @{name="SID";expression={$_.PSChildName}}, 
                    @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
                    @{name="UserName";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}} | `
                    Where-Object {$_.SID -match $SIDPattern}

# Loop through each profile on the machine
Foreach ($Profile in $ProfileList)
{
    # Load User ntuser.dat if it's not already loaded
    [bool] $IsProfileLoaded = Test-Path Registry::HKEY_USERS\$($Profile.SID)

    if ( -Not $IsProfileLoaded )
    {
        reg load "HKU\$($Profile.SID)" "$($Profile.UserHive)"
    }
 
    #####################################################################
    # Modifying a user`s hive of the registry
    "{0} {1}" -f "`tUser:", $($Profile.UserName) | Write-Verbose

    Set-PTA -ProgId $ProgID -Protocol http
    Set-PTA -ProgId $ProgID -Protocol https
    #####################################################################
 
    # Unload ntuser.dat        
    iF ( -Not $IsProfileLoaded )
    {
        ### Garbage collection required before closing ntuser.dat ###
        [gc]::Collect()
        reg unload "HKU\$($Profile.SID)"
    }
}
#endregion Change Users' Hives

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