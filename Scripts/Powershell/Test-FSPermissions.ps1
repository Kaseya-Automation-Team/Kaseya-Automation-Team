<#
.Synopsis
   Detect filesystem permissions changes.
.DESCRIPTION
   Used by Agent Procedure
   Detects filesystem permissions changes and saves information on changes to a TXT-file.
.EXAMPLE
   .\Test-FSPermissions.ps1  -AgentName '123456' -OutputFilePath 'C:\TEMP\fs_deficiency.txt' -RefJSON 'C:\FS_Permissions.json'
.EXAMPLE
   .\Test-FSPermissions.ps1  -AgentName '123456' -OutputFilePath 'C:\TEMP\fs_deficiency.txt' -RefJSON 'C:\FS_Permissions.json' -LogIt 0
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    [parameter(Mandatory=$true)]
    [string]$OutputFilePath,
    # Path to the JSON file that lists filesystem objects with corresponding users/groups & their permissions
    [parameter(Mandatory=$true)]
    [string[]] $RefJSON,
    # Create transcript file
    [parameter(Mandatory=$false)]
    [int] $LogIt = 1
 )
#region check/start transcript
[string]$Pref = 'Continue'
if ( 1 -eq $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
    $LogFile = "$ScriptPath\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

[array] $RefAccessParams = Get-Content -Raw -Path $ReferenceJSON  | ConvertFrom-Json
[string[]] $Deficiencies = @()

foreach ( $Path in $($RefAccessParams.Path | Select-Object -Unique) )
{
    Write-Debug "Path: $Path`nActual Permissions"
    #region get actual ACL & replace enumerated permissions
    $ActualAcl = foreach ( $Access in (Get-Acl -Path $Path).Access )
    {
        # see https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights
        $Permissions = switch($Access.FileSystemRights.value__)
        {
            2032127     { 'FullControl' }
            1179785     { 'Read' }
            1180063     { 'Read, Write' }
            1179817     { 'ReadAndExecute' }
            1245631     { 'ReadAndExecute, Modify, Write' }
            1180095     { 'ReadAndExecute, Write' }
            268435456   { 'FullControl' }
            -1610612736 { 'ReadAndExecute, Synchronize ' }
            -536805376  { 'Modify, Synchronize ' }
            default     { $Access.FileSystemRights.ToString()}
        }
        [PSCustomObject] @{
            'IdentityReference' = $Access.IdentityReference
            'FileSystemRights'  = $Permissions
        }
        [string] $Info = "{0} : {1}" -f $($Access.IdentityReference), $Permissions
        Write-Debug $Info
    }
    #endregion get actual ACL & replace enumerated permissions

    #region detect if security members changed

    $RefAcl = $RefAccessParams | Where-Object {$Path -eq $_.Path}

    Write-Debug "Path: $Path`nReference Permissions"
    $RefAcl | Select-Object UserOrGroup, Permission | `
    ForEach-Object {[string] $Info = "{0} : {1}" -f $_.UserOrGroup, $_.Permission; Write-Debug $Info }

    # Gather users/groups that have permission to the FS object
    [string[]] $ActualUsersOrGroups = ( $ActualAcl | Select-Object -Unique -ExpandProperty IdentityReference).Value
    # Gather users/groups that must have permission to the path according to the JSON
    [string[]] $RefUsersOrGroups = ( $RefAcl | Select-Object -Unique -ExpandProperty UserOrGroup )
    
    [array] $DiffUsersOrGroups = Compare-Object -ReferenceObject $RefUsersOrGroups -DifferenceObject $ActualUsersOrGroups

    if (0 -ne $DiffUsersOrGroups.Count)
    {
        foreach ($item in $DiffUsersOrGroups)
        {
            if ( '=>' -eq $item.SideIndicator)
            {
                $Deficiencies += "Permissions added for $($item.InputObject) to $Path"
            }
            else
            {
                $Deficiencies += "Permissions removed for $($item.InputObject) to $Path"
            }
        }
    }
    #endregion detect if security members changed

    #region detect if permissions changed

    foreach( $UserOrGroup in $RefUsersOrGroups)
    {
        #Reference access rights from the JSON
        [string[]] $RefAccessRights = (
            $RefAcl | `
            Where-Object { $UserOrGroup -eq $_.UserOrGroup } | `
            Select-Object -ExpandProperty Permission | `
            ForEach-Object {$_ -split ','}
        ).Trim()
        #Actual access rights from the FS
        [string[]] $ActualAccessRights = @()
        $ActualAccessRights += $ActualAcl |  `
            Where-Object { $_.IdentityReference -eq $UserOrGroup} | `
            Select-Object -ExpandProperty FileSystemRights | `
            Where-Object {$null -ne $_} | `
            ForEach-Object {$_ -split ','} |`
            ForEach-Object {$_.Trim()}

        [array] $DiffAccessRights = Compare-Object -ReferenceObject $RefAccessRights -DifferenceObject $ActualAccessRights

        if (0 -ne $DiffAccessRights.Count)
        {
            foreach ($item in $DiffAccessRights)
            {
                if ( '=>' -eq $item.SideIndicator)
                {
                    $Deficiencies += "$($item.InputObject) permissions added for $UserOrGroup to $Path"
                }
                else
                {
                    $Deficiencies += "$($item.InputObject) permissions removed for $UserOrGroup to $Path"
                }
            }
        }
    }    
    #endregion detect if permissions changed
}# foreach ( $Path in $($RefAccessParams.Path | Select-Object -Unique) )

#region write results
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
if( 0 -lt $Deficiencies.Count )
{
    $Deficiencies = , "Host: $($env:ComputerName)" + $Deficiencies
    [System.IO.File]::WriteAllLines("$OutputFilePath", $Deficiencies, $Utf8NoBomEncoding)
}
else
{
    [System.IO.File]::WriteAllLines("$OutputFilePath", "No Deficiencies", $Utf8NoBomEncoding)
}
#endregion write results

#region check/stop transcript
if ( 1 -eq $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript