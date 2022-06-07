function Set-FTA {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String]
        $ProgId,
  
        [Parameter(Mandatory = $true)]
        [Alias("Protocol")]
        [ValidateNotNullorEmpty()]
        [String]
        $Extension,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String]
        $SID,

        [Parameter(Mandatory = $false)]
        [String]
        $Icon
    )
    $SID = ($SID.Trim()).ToLower()
    $Extension = $Extension.Trim()
    if (Test-Path -Path $ProgId) {
        $ProgId = "SFTA." + [System.IO.Path]::GetFileNameWithoutExtension($ProgId).replace(" ", "") + $Extension
    }
  
    Write-Verbose "ProgId: $ProgId"
    Write-Verbose "Extension/Protocol: $Extension"
  
    
    #Write required Application Ids to ApplicationAssociationToasts
    #When more than one application associated with an Extension/Protocol is installed ApplicationAssociationToasts need to be updated
    function local:Write-RequiredApplicationAssociationToasts {
        param (
        [Parameter( Position = 0, Mandatory = $True )]
        [String]
        $ProgId,
  
        [Parameter( Position = 1, Mandatory = $True )]
        [String]
        $Extension
      )

      try {
          $keyPath = "HKEY_USERS\$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts"
          [Microsoft.Win32.Registry]::SetValue($keyPath, $ProgId + "_" + $Extension, 0x0) 
          Write-Verbose ("Write Reg ApplicationAssociationToasts OK: " + $ProgId + "_" + $Extension)
      } catch {
          Write-Verbose ("Write Reg ApplicationAssociationToasts FAILED: " + $ProgId + "_" + $Extension)
      }
      
      $allApplicationAssociationToasts = Get-ChildItem -Path HKLM:\SOFTWARE\Classes\$Extension\OpenWithList\* -ErrorAction SilentlyContinue | 
      ForEach-Object {
          "Applications\$($_.PSChildName)"
      }
  
      $allApplicationAssociationToasts += @(
        ForEach ($item in (Get-ItemProperty -Path HKLM:\SOFTWARE\Classes\$Extension\OpenWithProgids -ErrorAction SilentlyContinue).PSObject.Properties ) {
            if ([string]::IsNullOrEmpty($item.Value) -and $item -ne "(default)") {
                $item.Name
            }
        })
  
      
      $allApplicationAssociationToasts += Get-ChildItem -Path HKLM:SOFTWARE\Clients\StartMenuInternet\* , HKCU:SOFTWARE\Clients\StartMenuInternet\* -ErrorAction SilentlyContinue | 
      ForEach-Object {
          (Get-ItemProperty ("$($_.PSPath)\Capabilities\" + (@("URLAssociations", "FileAssociations") | Select-Object -Index $Extension.Contains("."))) -ErrorAction SilentlyContinue).$Extension
      }
      
      $allApplicationAssociationToasts | 
      ForEach-Object {
          if ($_) {
              if (Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts $_"_"$Extension -Value 0 -Type DWord -ErrorAction SilentlyContinue -PassThru) {
                  Write-Verbose  ("Write Reg ApplicationAssociationToastsList OK: " + $_ + "_" + $Extension)
                } else {
                    Write-Verbose  ("Write Reg ApplicationAssociationToastsList FAILED: " + $_ + "_" + $Extension)
                }
            }
        }
  
    }
  
    function local:Update-RegistryChanges {
$code = @'
[System.Runtime.InteropServices.DllImport("Shell32.dll")] 
private static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
public static void Refresh() {
    SHChangeNotify(0x8000000, 0, IntPtr.Zero, IntPtr.Zero);    
}
'@ 
  
        try {
            Add-Type -MemberDefinition $code -Namespace SHChange -Name Notify
        } catch {}
  
        try {
            [SHChange.Notify]::Refresh()
        } catch {} 
    }
    
  
    function local:Set-Icon {
    param (
        [Parameter( Position = 0, Mandatory = $True )]
        [String]
        $ProgId,
  
        [Parameter( Position = 1, Mandatory = $True )]
        [String]
        $Icon
      )
  
        try {
            $keyPath = "HKEY_USERS\$SID\SOFTWARE\Classes\$ProgId\DefaultIcon"
            [Microsoft.Win32.Registry]::SetValue($keyPath, "", $Icon) 
            Write-Verbose "Write Reg Icon OK"
            Write-Verbose "Reg Icon: $keyPath"
        } catch {
              Write-Verbose "Write Reg Icon FAILED"
        }
    }
  
  
    function local:Write-ExtensionKeys {
      param (
        [Parameter( Position = 0, Mandatory = $True )]
        [String]
        $ProgId,
  
        [Parameter( Position = 1, Mandatory = $True )]
        [String]
        $Extension,
  
        [Parameter( Position = 2, Mandatory = $True )]
        [String]
        $ProgHash
      )
      
  
      function local:Remove-UserChoiceKey {
        param (
          [Parameter( Position = 0, Mandatory = $True )]
          [String]
          $Key
        )
  
$code = @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;

namespace Registry {
    public class Utils {
    [DllImport("advapi32.dll", SetLastError = true)]
    private static extern int RegOpenKeyEx(UIntPtr hKey, string subKey, int ulOptions, int samDesired, out UIntPtr hkResult);

    [DllImport("advapi32.dll", SetLastError=true, CharSet = CharSet.Unicode)]
    private static extern uint RegDeleteKey(UIntPtr hKey, string subKey);

    public static void DeleteKey(string key) {
        UIntPtr hKey = UIntPtr.Zero;
        RegOpenKeyEx((UIntPtr)0x80000001u, key, 0, 0x20019, out hKey);
        RegDeleteKey((UIntPtr)0x80000001u, key);
    }
    }
}
'@
    
        try {
          Add-Type -TypeDefinition $code
        }
        catch {}
  
        try {
          [Registry.Utils]::DeleteKey($Key)
        }
        catch {} 
      } 
  
      
      try {
        $keyPath = "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$Extension\UserChoice"
        Write-Verbose "Remove Extension UserChoice Key If Exist: $keyPath"
        Remove-UserChoiceKey $keyPath
      }
      catch {
        Write-Verbose "Extension UserChoice Key No Exist: $keyPath"
      }
    
  
      try {
        $keyPath = "HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$Extension\UserChoice"
        [Microsoft.Win32.Registry]::SetValue($keyPath, "Hash", $ProgHash)
        [Microsoft.Win32.Registry]::SetValue($keyPath, "ProgId", $ProgId)
        Write-Verbose "Write Reg Extension UserChoice OK"
      }
      catch {
        throw "Write Reg Extension UserChoice FAILED"
      }
    }
  
  
    function local:Write-ProtocolKeys {
      param (
        [Parameter( Position = 0, Mandatory = $True )]
        [String]
        $ProgId,
  
        [Parameter( Position = 1, Mandatory = $True )]
        [String]
        $Protocol,
  
        [Parameter( Position = 2, Mandatory = $True )]
        [String]
        $ProgHash
      )
        
  
    try {
        $keyPath = "HKEY_USERS\$SID\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\$Protocol\UserChoice"
        Write-Verbose "Remove Protocol UserChoice Key If Exist: $keyPath"
        Remove-Item -Path $keyPath -Recurse -ErrorAction Stop | Out-Null
        } catch {
            Write-Verbose "Protocol UserChoice Key No Exist: $keyPath"
        }
    
  
      try {
        $keyPath = "HKEY_USERS\$SID\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\$Protocol\UserChoice"
        [Microsoft.Win32.Registry]::SetValue( $keyPath, "Hash", $ProgHash)
        [Microsoft.Win32.Registry]::SetValue($keyPath, "ProgId", $ProgId)
        Write-Verbose "Write Reg Protocol UserChoice OK"
      }
      catch {
        throw "Write Reg Protocol UserChoice FAILED"
      }
      
    }
  
    
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
    #If ($DomainSID.IsPresent) { Write-Verbose  "Use Get-UserSidDomain" } Else { Write-Verbose  "Use Get-UserSid" } 
    #$userSid = If ($DomainSID.IsPresent) { Get-UserSidDomain } Else { Get-UserSid } 
    $userExperience = Get-UserExperience
    $userDateTime = Get-HexDateTime

    Write-Debug "UserDateTime: $userDateTime"
    Write-Debug "UserSid: $SID"
    Write-Debug "UserExperience: $userExperience"
  
    $baseInfo = "$Extension$SID$ProgId$userDateTime$userExperience".ToLower()
    Write-Verbose "baseInfo: $baseInfo"
  
    $progHash = Get-Hash $baseInfo
    Write-Verbose "Hash: $progHash"
    
    #Write AssociationToasts List
    Write-RequiredApplicationAssociationToasts $ProgId $Extension
  
    #Handle Extension Or Protocol
    if ($Extension.Contains(".")) {
      Write-Verbose "Write Registry Extension: $Extension"
      Write-ExtensionKeys $ProgId $Extension $progHash
  
    }
    else {
      Write-Verbose "Write Registry Protocol: $Extension"
      Write-ProtocolKeys $ProgId $Extension $progHash
    }
  
     
    if ($Icon) {
      Write-Verbose  "Set Icon: $Icon"
      Set-Icon $ProgId $Icon
    }
  
    Update-RegistryChanges 
}
  

#$FoundSoftware = Get-Package | Where-Object {$_.Name -eq "Microsoft Edge"} | Select-Object -ExpandProperty Status
if ("Installed" -eq (Get-Package | Where-Object {$_.Name -eq "Microsoft Edge"} | Select-Object -ExpandProperty Status) ) {
    Write-Output 'Microsoft Edge is installed on this computer'
    #region Change Users' Hives
    [string] $SIDPattern = '^S-1-5-21-(\d+-?){4}$'
    [string] $RegKeyUserProfiles = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*'
    [array] $ProfileList = Get-ItemProperty -Path Registry::$RegKeyUserProfiles | `
                        Select-Object  @{name="SID";expression={$_.PSChildName}},
                        @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}},
                        @{name="UserName";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}} | `
                        Where-Object {$_.SID -match $SIDPattern}
    # Loop through each profile on the machine
    Foreach ($Profile in $ProfileList) {
        # Load User ntuser.dat if it's not already loaded
        reg load "HKU\$($Profile.SID)" "$($Profile.UserHive)"
        #####################################################################
        # Modifying a user`s hive of the registry
        "{0} {1}" -f "`tUser:", $($Profile.UserName) | Write-Verbose
        Set-FTA -ProgId 'MSEdgeHTM' -Extension ".htm"  -SID $Profile.SID.ToLower() -Verbose
        Set-FTA -ProgId 'MSEdgeHTM' -Extension ".htm1" -SID $Profile.SID.ToLower() -Verbose
        Set-FTA -ProgId 'MSEdgeHTM' -Protocol "http"   -SID $Profile.SID.ToLower() -Verbose
        Set-FTA -ProgId 'MSEdgeHTM' -Protocol "https"  -SID $Profile.SID.ToLower() -Verbose
        #####################################################################
        # Unload ntuser.dat        
        [gc]::Collect()
        $ErrorActionPreferenceSaved = $ErrorActionPreference
        reg unload "HKU\$($Profile.SID)" | Out-Null
        $ErrorActionPreference = $ErrorActionPreferenceSaved
    }
    #endregion Change Users' Hives
} else {
    Write-Output 'Microsoft Edge is Not Found on this computer!'
}
