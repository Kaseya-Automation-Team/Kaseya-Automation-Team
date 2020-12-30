<#
.Synopsis
   Wipes the system
.DESCRIPTION
   Wipes the system. Must be started under the SYSTEM account
.EXAMPLE
   PSEXEC -i -s Powershell.exe -WindowStyle Hidden -File Wipe-TheSystem.ps1
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>


$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_RemoteWipe"
$methodName = "doWipeProtectedMethod"

$session = New-CimSession

$params = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
$param = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("param", "", "String", "In")
$params.Add($param)

$instance = Get-CimInstance -Namespace $namespaceName -ClassName $className -Filter "ParentID='./Vendor/MSFT' and InstanceID='RemoteWipe'"
$session.InvokeMethod($namespaceName, $instance, $methodName, $params)
