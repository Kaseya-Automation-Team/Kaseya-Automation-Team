function global:Find-PropText{  
    param($iObject,$iFindText,[switch]$ReturnProps)  
  
    # look through names and values of the object properties for matching text  
    $anythingFound = (  
        $iObject.PsObject.Properties |  
        Where {  
            $_.Name -like $iFindText -or  
            $_.Value -like $iFindText  
        }  
    )  
  
    # If -ReturnProps, return any found properties, otherwise return bool of any found  
    If ($ReturnProps){Return $anythingFound}  
    ElseIf ($anythingFound){Return $true}  
    Else{Return $false}  
}  
  
  
$findFilter = '*sysaid*'  
  
  
##########################  
## Kill Process/Service ##  
##########################  
  
# Stop services, delete services, kill processes.  repeat attempts while services/processes are found  
    $saServices = Get-Service | Where {$_.Name -like $findFilter}  
    $saProcesses = Get-Process | Where {$_.ProcessName -like $findFilter}  
    $bailTrigger = 100000  
    $bailCount = 1  
  
While ($saServices -and $saProcesses){  
    # Stop SysAid services  
    $null = $saServices | Stop-Service  
  
  
    # Remove SysAid services  
    ForEach ($saService in $saServices){  
        $thisServiceName = $saService.Name  
        $thisServiceExists = Get-Service $thisServiceName  
        If ($thisServiceExists){$thisServiceStopped = ((Get-Service $thisServiceName).Status -eq 'Stopped')}  
        # Delete the service entry  
        If ($thisServiceExists -and $thisServiceStopped){(Get-WmiObject Win32_Service -Filter "name='$thisServiceName'").Delete()}  
    }  
  
  
    # Kill SysAid processes  
    $null = $saProcesses | Stop-Process  
  
    # Check services & processes  
    $saServices = Get-Service | Where {$_.Name -like $findFilter}  
    $saProcesses = Get-Process | Where {$_.ProcessName -like $findFilter}  
  
    If ($bailCount -ge $bailTrigger){  
        $saServices = $null  
        $saProcesses = $null  
    }  
    Else{$bailCount++}  
}  
  
  
#########################  
## File System Changes ##  
#########################  
  
# Delete local SysAid folders  
    $unc86Folder = 'C:\Program Files (x86)\SysAid'  
    $unc64folder = 'C:\Program Files\SysAid'  
    # 'C:\Windows\Installer\{FC5E1D1D-6D3F-4844-A937-567D589F655E}'  
    # 'C:\Windows\Temp\{FC5E1D1D-6D3F-4844-A937-567D589F655E}'  
  
    If (Test-Path $unc86Folder){Remove-Item $unc86Folder -Force -Recurse}  
    If (Test-Path $unc64Folder){Remove-Item $unc64Folder -Force -Recurse}  
  
# Delete SysAid desktop icon  
    #stub also remove start menu entries?  
    $uncPublicDesktop = 'C:\Users\Public\Desktop'  
      
    $null = (  
        Get-ChildItem $uncPublicDesktop |  
        Where {$_.Name -like $findFilter} |  
        Remove-Item -Force  
    )  
  
# Delete any cached installer sources  
    # Find folders that contain the filter text  
    $installerCacheUNC = 'C:\Windows\Installer'  
    $cachedInstallers = (  
        Get-ChildItem $installerCacheUNC -Force |  
        ForEach{  
            $subTreeMatches = $_ |  
                Get-ChildItem -Recurse -Force |  
                Where {$_.Name -like $findFilter}  
            If ($subTreeMatches){$_}  
        }  
    )  
      
    # Use the name of the folder to find any additional cache files  
    $deletableInstallerCache = @()  
    ForEach ($cachedInstaller in $cachedInstallers){  
        Get-ChildItem $installerCacheUNC -Force |  
        Where {$_.Name -like ('*' + $cachedInstaller.Name + '*')} |  
        ForEach {$deletableInstallerCache += $_}  
    }  
  
    # Remove found cached installers  
    If ($deletableInstallerCache){  
        $null = (  
            $deletableInstallerCache |  
            Remove-Item -Force -Recurse  
        )  
    }  
  
  
######################  
## Registry Changes ##  
######################  
  
# Remove registry entries  
    $null = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT  
  
    # Remove registry entries  
  
    $manualRegKeys = `  
        'HKLM:\System\CurrentControlSet\services\SysAidAgent',  
        'HKLM:\System\ControlSet001\services\SysAidAgent'  
  
    $oldRegKeys = `  
        'HKLM:\SOFTWARE\Ilient',  
        'HKLM:\SOFTWARE\Wow6432Node\Ilient',  
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{FC5E1D1D-6D3F-4844-A937-567D589F655E}'  
    ForEach ($oldKey in $oldRegKeys){$manualRegKeys += $oldKey}  
  
    $installedKeys = `  
        'HKCR:\Installer',  
        'HKLM:\SOFTWARE\Classes\Installer',  
        'HKLM:\SOFTWARE\WOW6432Node\Classes\Installer'  
  
    $subKeys = 'Products','Features','UpgradeCodes'  
  
    $targetKeys = @()  
      
    ForEach ($subKey in $subKeys){  
        ForEach ($installedKey in $installedKeys){  
            $targetKeys += ($installedKey + '\' + $subKey)  
        }  
    }  
  
    # Keep only keys that exist  
    $targetKeys = $targetKeys | Where {(Test-Path $_)}  
  
    # Find any registry keys with properties matching the $findFilter ('SysAid')  
    $matchingKeys = (  
        $targetKeys |  
        Get-ChildItem -ErrorAction SilentlyContinue |  
        Get-ItemProperty |  
        ForEach {If (Find-PropText $_ $findFilter){$_}}  
    )  
  
    # Find any package codes listed, we will use these to discover more potential registry points  
    $packageCodes = $matchingKeys | Select -ExpandProperty PackageCode | Sort -Unique  
  
    # Search target keys for sub-properties matching any discoveries from $packageCodes  
    ForEach ($iCode in $packageCodes){  
        $codeResults = (  
            $targetKeys |  
            Get-ChildItem -ErrorAction SilentlyContinue |  
            Get-ItemProperty |  
            ForEach {If (Find-PropText $_ ('*' + $iCode + '*')){$_}}  
        )  
        # If any results, add each individually to the matching keys.  
        If ($codeResults){$codeResults | %{$matchingKeys += $_}}  
    }  
  
    # If any old keys exist, add them to the results  
    ForEach ($manualKey in $manualRegKeys){  
        If ((Test-Path $manualKey)){$matchingKeys += (Get-ItemProperty $manualKey)}  
    }  
  
    # Clear any duplicate key matches from list, then delete all matches  
    $matchingKeys = $matchingKeys | Sort -Unique PSPath  
    If ($matchingKeys){  
        ForEach ($iMatch in ($matchingKeys.PSPath)){  
            Remove-Item $iMatch -Force -Recurse  
        }  
    }  