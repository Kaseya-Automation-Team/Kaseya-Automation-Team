<#
.Synopsis
   Gathers password settings.
   Uses standard secedit.exe utility.
.DESCRIPTION
   Gathers password settings and outputs information to the console
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>

$FileName = "$env:TEMP\sec_output.txt"

#region functions
Function Get-SecurityPolicy { 
[CmdletBinding()]  
Param(  
    [ValidateNotNullOrEmpty()]
    [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
    [string]$FileName  
)
#run secedit and save output
    secedit /export /cfg "$Filename" | Out-Null
    
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

[string[]]$IncludeSettings = @('PasswordHistorySize', 'MinimumPasswordAge', 'MaximumPasswordAge', 'MinimumPasswordLength', 'PasswordComplexity', 'ClearTextPassword')

$PasswordSettings = New-Object PSObject -Property $([hashtable](Get-SecurityPolicy -FileName $FileName).'System Access') | Select-Object $IncludeSettings

Write-Verbose $PasswordSettings

$PasswordSettings | Select-Object -Property `
@{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}}, `
@{Name = 'Date'; Expression = {$currentDate}}, `
@{Name = 'EnforcePasswordHistory'; Expression = {$_.PasswordHistorySize}}, `
@{Name = 'MinimumPasswordAge'; Expression = {$_.MinimumPasswordAge}}, `
@{Name = 'MaximumPasswordAge'; Expression = {$_.MaximumPasswordAge}}, `
@{Name = 'MinimumPasswordLength'; Expression = {$_.MinimumPasswordLength}}, `
@{Name = 'StorePasswordUsingReversibleEncryption'; Expression = {$_.ClearTextPassword}} `

#cleanup
if (Test-Path $Filename -Verbose ) { Remove-Item $Filename -Force -Confirm:$false | Out-Null}