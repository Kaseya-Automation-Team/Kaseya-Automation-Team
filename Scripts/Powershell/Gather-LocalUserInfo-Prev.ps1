## Kaseya Automation Team
## Used by the "Gather Local User Info" Agent Procedure

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
	[string]$Path = "",
    [parameter(Mandatory=$true)]
	[string]$Filename = "",
    [parameter(Mandatory=$false)]
    [int]$Limit = 3,
    [parameter(Mandatory=$false)]
    [int]$LogIt = 1
)

[string]$Pref = "Continue"
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $LogFile = "$Path\$ScriptName.log"
    Start-Transcript -Path $LogFile
}

Write-Debug "Script execution started"

#Create array where all objects for export will be storred
$Results = @()

$LocalUsers = Get-LocalUser

Write-Debug ($LocalUsers| Select-Object * | Out-String)

$AdminGroup = Get-LocalGroupMember -SID 'S-1-5-32-544' | Where-Object {$_.PrincipalSource -eq "Local"}

Write-Debug ($AdminGroup | Select-Object * |Out-String)

$Counter = 0

ForEach ($User in $LocalUsers){

    $Counter = $Counter+1

    Write-Debug $Counter
    Write-Debug $User.Name
    
    $Output = New-Object psobject

    Add-Member -InputObject $Output -MemberType NoteProperty -Name MachineID -Value $AgentName
    Add-Member -InputObject $Output -MemberType NoteProperty -Name UserName -Value $User.Name
    Add-Member -InputObject $Output -MemberType NoteProperty -Name Enabled -Value $User.Enabled
    
    $LastLogonString = $User.LastLogon

     if ($LastLogonString) {

        $LastLogonString = $LastLogonString|Get-Date
        $LastLogonString = Get-Date $LastLogonString -Format 'MM-dd-yyyy HH:mm:ss:ms'
        $LastLogonString = $LastLogonString -replace "-", "/"

    } else {

        $LastLogonString = "Never"
    }

    Write-Debug ($LastLogonString|Out-String)

    if ($AdminGroup.Name -contains "$env:COMPUTERNAME\$User")
    {
        Add-Member -InputObject $Output -MemberType NoteProperty -Name IsLocalAdmin -Value "True"

    } else {

        Add-Member -InputObject $Output -MemberType NoteProperty -Name IsLocalAdmin -Value "False"
    }

    Add-Member -InputObject $Output -MemberType NoteProperty -Name LastLogon -Value $LastLogonString

    #Add object to the previously created array
    $Results += $Output

    If ($Limit -ne 0) {

        if ($Counter -eq $Limit) {

            Write-Debug "Limit of $Limit records has been reached"
            Exit

        }
            
    }
}

#Export results to csv file
$Results| Export-Csv -Path $Path\$Filename -NoTypeInformation -Encoding UTF8

if (1 -eq $LogIt)
{
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}