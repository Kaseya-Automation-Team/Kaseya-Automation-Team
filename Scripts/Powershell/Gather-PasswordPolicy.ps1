<#
.Synopsis
   Gathers password settings.
   Uses standard secedit.exe utility.
.DESCRIPTION
   Gathers password settings and saves information to a CSV-file
.EXAMPLE
   .\Gather-PasswordPolicy.ps1 -AgentName '12345' -FileName 'password_settings.csv' -Path 'C:\TEMP'
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    [parameter(Mandatory=$true)]
    [string]$FileName,
    [parameter(Mandatory=$true)]
    [string]$Path
)

#region functions
Function Get-SecurityPolicy { 
[CmdletBinding()]  
Param(  
    [ValidateNotNullOrEmpty()]
    [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
    [string]$FileName  
)
#run secedit and save output
    secedit /export /cfg "$FileName" | Out-Null
              
    [hashtable]$Content = @{}  
    switch -regex -file $FileName
    {  
        "^\[(.+)\]$" # Section  
        {  
            $section = $matches[1]  
            $Content[$section] = @{}  
            $CommentCount = 0  
        }  
        "^(;.*)$" # Comment  
        {  
            if (!($section))  
            {  
                $section = "No-Section"  
                $Content[$section] = @{}  
            }  
            $value = $matches[1]  
            $CommentCount = $CommentCount + 1  
            $name = "Comment" + $CommentCount  
            $Content[$section][$name] = $value  
        }   
        "(.+?)\s*=\s*(.*)" # Key  
        {  
            if (!($section))  
            {  
                $section = "No-Section"  
                $Content[$section] = @{}  
            }  
            $name,$value = $matches[1..2]  
            $Content[$section][$name] = $value  
        }  
    }
    Return $Content
}


#endregion functions

[string]$currentDate = Get-Date -UFormat "%m/%d/%Y %T"
[string]$SeceditOutput

if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) )
{
    $FileName = "$Path\$FileName"
    $SeceditOutput = "$Path\secedit_out.cfg"
}

[string[]]$IncludeSettings = @('PasswordHistorySize', 'MinimumPasswordAge', 'MaximumPasswordAge', 'MinimumPasswordLength', 'PasswordComplexity', 'ClearTextPassword')

$PasswordSettings = New-Object PSObject -Property $([hashtable](Get-SecurityPolicy -FileName $FileName).'System Access') | Select-Object $IncludeSettings

$PasswordSettings | Select-Object -Property `
@{Name = 'AgentGuid'; Expression = {$AgentName}}, `
@{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}}, `
@{Name = 'Date'; Expression = {$currentDate}}, `
@{Name = 'EnforcePasswordHistory'; Expression = {$_.PasswordHistorySize}}, `
@{Name = 'MinimumPasswordAge'; Expression = {$_.MinimumPasswordAge}}, `
@{Name = 'MaximumPasswordAge'; Expression = {$_.MaximumPasswordAge}}, `
@{Name = 'MinimumPasswordLength'; Expression = {$_.MinimumPasswordLength}}, `
@{Name = 'StorePasswordUsingReversibleEncryption'; Expression = {$_.ClearTextPassword}} `
| Export-Csv -Path "FileSystem::$FileName" -Force -Encoding UTF8 -NoTypeInformation

#cleanup
if (test-Path $SeceditOutput) { Remove-Item $SeceditOutput -Force -Confirm:$false | Out-Null}