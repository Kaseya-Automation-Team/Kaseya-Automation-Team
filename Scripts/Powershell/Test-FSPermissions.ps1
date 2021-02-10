param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    [parameter(Mandatory=$true)]
    [string]$FileName,
    [parameter(Mandatory=$true)]
    [string]$Path,
    #list of filesystem objects to check
    # Path to the JSON file that contains filesystem objects with elegible users/groups & their permissions
    [parameter(Mandatory=$true)]
    [string[]]$ReferenceJSON
 )

[array] $RefPermissions = Get-Content -Raw -Path $ReferenceJSON  | ConvertFrom-Json
[string[]] $Deficiencies = @()

foreach ( $Path in $($RefPermissions.Path | Select-Object -Unique) )
{
    #region get actual ACL & replace enumerated permissions
    $AclAccess = foreach ($Access in (Get-Acl -Path $Path).Access) {
        # see https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights
        $permissions = switch($Access.FileSystemRights.value__) {
            2032127     { 'FullControl'; break}
            1179785     { 'Read'; break}
            1180063     { 'Read, Write'; break}
            1179817     { 'ReadAndExecute'; break}
            1245631     { 'ReadAndExecute, Modify, Write'; break}
            1180095     { 'ReadAndExecute, Write'; break}
            268435456   { 'FullControl'; break}
            -1610612736 { 'ReadAndExecute, Synchronize '; break}
            -536805376  { 'Modify, Synchronize '; break}
            default     { $Access.FileSystemRights.ToString()}
        }
        [PSCustomObject] @{
            'IdentityReference' = $Access.IdentityReference
            'FileSystemRights'  = $permissions
        }
    }
    #endregion get actual ACL & replace enumerated permissions
    $RefAccess = $RefPermissions | Where-Object {$Path -eq $_.Path}
    # Gather users/groups that have permission to the FS object
    [string[]] $ActualUsersOrGroups = ( $AclAccess | Select-Object -Unique -ExpandProperty IdentityReference).Value
    # Gather users/groups that must have permission to the path according to the JSON
    [string[]] $RefUsersOrGroups = ( $RefAccess | Select-Object -Unique -ExpandProperty UserOrGroup )
    
    #region detect if security members changed
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
            $RefAccess | `
            Where-Object { $UserOrGroup -eq $_.UserOrGroup } | `
            Select-Object -ExpandProperty Permission | `
            ForEach-Object {$_ -split ','}
        ).Trim()
        #Actual access rights from the FS
        [string[]] $ActualAccessRights = @()
        $ActualAccessRights += $AclAccess |  `
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
}

if( 0 -lt $Deficiencies.Count )
{
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines("$Path\$FileName", $Deficiencies, $Utf8NoBomEncoding)
}