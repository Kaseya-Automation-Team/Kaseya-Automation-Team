## Kaseya Automation Team
## Used by the "Gather RDP enablement status" Agent Procedure

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
	[string]$Path = ""
)

#Create array where all objects for export will be storred
$Results = @()

$LocalUsers = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount='True'"

ForEach ($User in $LocalUsers){
    
    $Output = New-Object psobject

    Add-Member -InputObject $Output -MemberType NoteProperty -Name MachineID -Value $AgentName
    Add-Member -InputObject $Output -MemberType NoteProperty -Name UserName -Value $User.Name
    Add-Member -InputObject $Output -MemberType NoteProperty -Name Disabled -Value $User.Disabled
    
    $LastLogonString = (net user $User.Name | findstr /B /C:"Last logon").trim("Last logon                   ")
    Add-Member -InputObject $Output -MemberType NoteProperty -Name LastLogon -Value $LastLogonString

    #Add object to the previously created array
    $Results += $Output
}


#Export results to csv file
$Results| Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8