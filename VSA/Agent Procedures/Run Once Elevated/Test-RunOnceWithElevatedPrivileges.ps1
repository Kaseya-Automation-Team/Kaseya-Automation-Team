param (
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $ProgramToRun = 'regedit.exe',

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $TaskName = 'RunOnce_Test'
)

#region function Set-RegParam
function Set-RegParam {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=0)]
        [string] $RegPath,

        [parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=1)]
        [AllowEmptyString()]
        [string] $RegValue,

        [parameter(Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=2)]
        [ValidateSet('Binary', 'DWord', 'ExpandString', 'MultiString', 'None', 'QWord', 'String', 'Unknown')]
        [string] $ValueType = 'String',

        [parameter(Mandatory=$false)]
        [Switch] $UpdateExisting
    )
    
    begin {
        [string] $RegKey = Split-Path -Path Registry::$RegPath -Parent
        [string] $RegProperty = Split-Path -Path Registry::$RegPath -Leaf
    }
    process {
            $RegKey | Write-Debug
            $RegProperty | Write-Debug
            #Create key
            if( -not (Test-Path -Path $RegKey) )
            {
                try {
                    New-Item -Path $RegKey -Force -Verbose -ErrorAction Stop
                } catch { Write-Error $_.Exception.Message}
                #Create property
                try {
                    New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -Verbose -ErrorAction Stop
                } catch { Write-Error $_.Exception.Message}
            }            
            else
            {
                $Poperty = try {Get-ItemProperty -Path $RegPath -ErrorAction Stop | Out-Null} catch { $null}
                if ($null -eq $Poperty )
                {
                     #Create property
                    try {
                        New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -Verbose -ErrorAction Stop
                    } catch { Write-Error $_.Exception.Message}
                }
                #Assign value to the property
                if( $UpdateExisting )
                {
                    try {
                            Set-ItemProperty -Path $RegKey -Name $RegProperty -Value $RegValue -Force -Verbose -ErrorAction Stop
                        } catch {Write-Error $_.Exception.Message}
                }
            }
    }
}
#endregion function Set-RegParam

[string] $TaskToRun = "schtasks /run /tn $TaskName"

[string] $SIDPattern = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
[string[]]$SIDs = Get-CimInstance -Query "SELECT SID FROM Win32_UserProfile WHERE Loaded = True" | Where-Object {$_.SID -match $SIDPattern} | Select-Object -ExpandProperty SID


foreach ($SID in $SIDs)
{
    $objSID = New-Object System.Security.Principal.SecurityIdentifier ($SID)
    $Principal = $($objSID.Translate( [System.Security.Principal.NTAccount])).Value
    #region Create scheduled task
    [array] $Actions = New-ScheduledTaskAction -Execute $ProgramToRun

    $TaskParameters = @{
        TaskName = $TaskName
        Action = $Actions
        Principal = $(New-ScheduledTaskPrincipal -UserId $Principal -RunLevel Highest)
    }

    if ( $null -eq $(try {Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop} Catch {$null}) )  {
        Register-ScheduledTask @TaskParameters
    } else {
        Set-ScheduledTask @TaskParameters
    }
    Set-RegParam -RegPath $(Join-Path -Path "HKEY_USERS\$SID" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\$TaskName") -RegValue $TaskToRun -ValueType String -UpdateExisting
    #endregion Create scheduled task
}