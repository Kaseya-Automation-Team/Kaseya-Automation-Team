## Kaseya Automation Team
## Used by the "Gather Local User Info" Agent Procedure

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
	[string]$Path = ""
)

#Create array where all objects for export will be storred
$Results = @()

$LocalUsers = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount='True'"

$AdminGroupName = get-wmiobject win32_group | where {$_.sid -eq 'S-1-5-32-544'} | select Name -ExpandProperty Name

ForEach ($User in $LocalUsers){
    
    $Output = New-Object psobject

    Add-Member -InputObject $Output -MemberType NoteProperty -Name MachineID -Value $AgentName
    Add-Member -InputObject $Output -MemberType NoteProperty -Name UserName -Value $User.Name
    Add-Member -InputObject $Output -MemberType NoteProperty -Name Disabled -Value $User.Disabled
    
    $LastLogonString = (net user $User.Name | findstr /B /C:"Last logon").trim("Last logon                   ")

    if ($LastLogonString -ne "Never") {

        $LastLogonString = $LastLogonString|Get-Date
        $LastLogonString = Get-Date $LastLogonString -Format 'MM-dd-yyyy HH:mm:ss:ms'
        $LastLogonString = $LastLogonString -replace "-", "/"

    }

    $env:COMPUTERNAME | % {
    $Group = [ADSI]("WinNT://$_/$AdminGroupName,group")
    $Group.PSBase.Invoke('Members') | % {
        $UserIsAdmin = $_.GetType().InvokeMember('Name', 'GetProperty', $null, $_, $null) | Select-String -Pattern $User.Name
        }
    }

    if ($UserIsAdmin) {
        Add-Member -InputObject $Output -MemberType NoteProperty -Name IsLocalAdmin -Value "True"
    } else {

        if ($User.SID -like "S-1-5-21-*-500") {
            Add-Member -InputObject $Output -MemberType NoteProperty -Name IsLocalAdmin -Value "True"
        } else {
            Add-Member -InputObject $Output -MemberType NoteProperty -Name IsLocalAdmin -Value "False"
        }
    }

    Add-Member -InputObject $Output -MemberType NoteProperty -Name LastLogon -Value $LastLogonString

    #Add object to the previously created array
    $Results += $Output
}

#Export results to csv file
$Results| Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8