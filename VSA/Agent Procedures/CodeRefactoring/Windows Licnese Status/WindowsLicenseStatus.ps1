<#
=================================================================================
Script Name:        Audit: Windows Licnese Status.
Description:        Get Windows Licnese Status.
Lastest version:    2022-06-01
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
$Query = "Select LicenseStatus from  SoftwareLicensingProduct Where PartialProductKey LIKE '%' and Name LIKE 'windows%'"
$LicenseInfo = Get-CimInstance -Query $Query
Switch ($LicenseInfo.LicenseStatus) {
                0 {$LicenseStatus = 'Unlicensed'; Break}
                1 {$LicenseStatus = 'Licensed'; Break}
                2 {$LicenseStatus = 'OOBGrace'; Break}
                3 {$LicenseStatus = 'OOTGrace'; Break}
                4 {$LicenseStatus = 'NonGenuineGrace'; Break}
                5 {$LicenseStatus = 'Notification'; Break}
                6 {$LicenseStatus = 'ExtendedGrace'; Break}
} 
Write-Output $LicenseStatus

eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "Windows License Status is $LicenseStatus" | Out-Null