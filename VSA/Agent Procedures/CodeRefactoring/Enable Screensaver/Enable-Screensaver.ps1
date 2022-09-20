<#
=================================================================================
Script Name:        Enable Screensaver
Description:        This script enables the screensaver on windows devices. One must edit the newScreenSaver variable to set to the required screensaver. Also, lock timeout can be changed by setting lockTimeMins variable.
Lastest version:    2022-09-20
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
# Sets the current users's screensave to "Mystify" (edit line 5 to change this)
# Sets a lock time of 5 minutes (edit line 4 to change this)

$lockTimeMins 	= 5
$newScreenSaver	= 'c:\windows\system32\mystify.scr'


function Test-RegistryValue {
	param (
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]$Path,

		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]$Name
	)
	
	try {
		Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Name -ErrorAction Stop | Out-Null
		return $true
	 }
	catch {
		return $false
	}
}

function setRegistyValue {
	param (
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]$Path,

		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]$Name,

		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]$Value
	)
	if (!(Test-RegistryValue -Path $Path -Name $Name)) {
		$log = $log + "$Path\$Name does not exist.`n"
	}
	else {
		$log = $log + "$Path\$Name exists.`n"
		$currentValue = (Get-ItemPropertyValue -Path $Path -Name $Name)
		$log = $log + "Current value = $regKeyRoot\$Name = $currentValue`n"
	}
	$log = $log + "Setting Value $Path\$Name = $Value`n"
	New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force | Out-Null
	return $log
}

function createWindowsEvent {
	param (
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]$Description
	)

	eventcreate.exe /L Application /T INFORMATION /SO VSAX /ID 200 /D "$description" | Out-Null
}


$log 			= ''
$Path     		= "HKCU:\Control Panel\Desktop"
$regKey0		= "scrnsave.exe"
$regKey1		= "ScreenSaveTimeOut"
$regKey2		= "ScreenSaveActive"
$regKey3		= "ScreenSaverIsSecure"
$lockTime 		= $lockTimeMins * 60

$log = $log + "VSAX Set screen saver.`n"
$log = setRegistyValue -Path $Path -Name $regKey0 -Value $newScreenSaver
$log = setRegistyValue -Path $Path -Name $regKey1 -Value $lockTime
$log = setRegistyValue -Path $Path -Name $regKey2 -Value '1'
$log = setRegistyValue -Path $Path -Name $regKey3 -Value '1'
write-host $log
createWindowsEvent -Description $log