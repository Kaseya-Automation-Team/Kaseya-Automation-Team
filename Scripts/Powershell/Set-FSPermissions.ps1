<#
.Synopsis
    Set file system permission for a user or group.
.PARAMETER Path
    The file system path to manage permission.
.PARAMETER UserOrGroup
    The account to set permissions for.
.PARAMETER Permissions
    Valid values are: 'ListDirectory', 'ReadData', 'WriteData', 'CreateFiles', 'CreateDirectories', 'AppendData', 'ReadExtendedAttributes', 'WriteExtendedAttributes', 'Traverse', 'ExecuteFile', 'DeleteSubdirectoriesAndFiles', 'ReadAttributes', 'WriteAttributes', 'Write', 'Delete', 'ReadPermissions', 'Read', 'ReadAndExecute', 'Modify', 'ChangePermissions', 'TakeOwnership', 'Synchronize' and 'FullControl'.
.PARAMETER AccessType
    Access Type. Valid values are: 'Allow' and 'Deny'
.PARAMETER RemoveRights
    (Optional) Remove specified file system rights.
.EXAMPLE
    .\Set-FSPermissions -Path c:\temp -Permissions Read, Write -UserOrGroup TestUser
.NOTES
    Version 0.1   
    Author: Proserv Team - VS
#>
param (
[parameter(Mandatory=$true, 
        ParameterSetName = 'Add')]
[ValidateScript({
    if( $_ -inotmatch "\b(ListDirectory|ReadData|WriteData|CreateFiles|CreateDirectories|AppendData|ReadExtendedAttributes|WriteExtendedAttributes|Traverse|ExecuteFile|DeleteSubdirectoriesAndFiles|ReadAttributes|WriteAttributes|Write|Delete|ReadPermissions|Read|ReadAndExecute|Modify|ChangePermissions|TakeOwnership|Synchronize|FullControl)\b" ) {
        throw "`nUnidetified permission `"$_`"`n"
    }
    return $true
    })]
    [string[]] $Permissions,

[parameter(Mandatory=$true, 
        ParameterSetName = 'Add')]
[parameter(Mandatory=$true, 
        ParameterSetName = 'Remove')]
[ValidateScript({
    if ( -not (Test-Path -Path $_) ) { throw "The path `"$Path`" is inaccessible" }
        return $true
    })]
    [string] $Path,

[parameter(Mandatory=$true, 
        ParameterSetName = 'Add')]
[parameter(Mandatory=$true, 
        ParameterSetName = 'Remove')]
[ValidateScript({
    try {
        # Attempt to retrieve the SID of the user or group
        $entity = New-Object System.Security.Principal.NTAccount($_)
        $sid = $entity.Translate([System.Security.Principal.SecurityIdentifier]).Value
        return $true
    } catch {
        throw $_
    }
    })]
    [string] $UserOrGroup,

[parameter(Mandatory=$false, 
        ParameterSetName = 'Add')]
[ValidateSet('Allow','Deny')]
    [String]$AccessType = 'Allow',

[parameter(Mandatory=$true, 
        ParameterSetName = 'Remove')]
    [switch]$RemoveRights
)

$acl = Get-Acl -Path $Path


if ($RemoveRights) {
    $entity = New-Object System.Security.Principal.NTAccount($UserOrGroup)
    $entitySID = $entity.Translate([System.Security.Principal.SecurityIdentifier]).Value
    $RulesToRemove = $acl.Access | Where-Object { $_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value -eq $entitySID }
    foreach ($Rule in $RulesToRemove) {
        $acl.RemoveAccessRule($Rule)
    }
    
} else {

    # Add the permission to the ACL
    $InheritanceFlags=[System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
    $PropagationFlags=[System.Security.AccessControl.PropagationFlags]"None"
    $FileSystemRights=[System.Security.AccessControl.FileSystemRights]"$($Permissions -join ',')"
    $AccessControl = [System.Security.AccessControl.AccessControlType]$AccessType

    if ((Get-Item $Path) -is [System.IO.DirectoryInfo]) {
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $userOrGroup,
            $FileSystemRights,
            $InheritanceFlags,
            $PropagationFlags,
            $AccessControl
        )
    } else {
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $userOrGroup,
            $FileSystemRights,
            $AccessControl
        )
    }
    $acl.AddAccessRule($rule)
}
# Apply the modified ACL to the folder
Set-Acl -Path $Path -AclObject $acl