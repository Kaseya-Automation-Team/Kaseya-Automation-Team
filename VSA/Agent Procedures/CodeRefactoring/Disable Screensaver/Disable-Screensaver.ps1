<#
=================================================================================
Script Name:        Management: Disable screensaver
Description:        This script disables the screensaver on windows devices.
Lastest version:    2022-09-20
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>

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
$regKey0		= "ScreenSaveActive"



$log = $log + "VSAX Disable screen saver.`n"
$log = setRegistyValue -Path $Path -Name $regKey0 -Value '0'

write-host $log
createWindowsEvent -Description $log

