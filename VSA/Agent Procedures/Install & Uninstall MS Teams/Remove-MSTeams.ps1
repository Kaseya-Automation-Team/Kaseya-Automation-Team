<#
.SYNOPSIS
    Uninstalls Microsoft Teams (per-user installation) for all user profiles, including MSIX packages, using scheduled tasks.

.DESCRIPTION
    This script removes Microsoft Teams by:
    - Checking for admin privileges (executed under SYSTEM account).
    - Enabling registry access privileges (SeRestorePrivilege, SeBackupPrivilege).
    - Loading user registry hives to scan Uninstall keys.
    - Detecting interactive user sessions via Win32_LogonSession and HKEY_USERS.
    - Scheduling tasks with a 1-minute delay for logged-on users or at next logon for others.
    - Using ServiceAccount to run tasks in user context.
    - Removing MSIX Teams packages for all users and provisioned packages.

.NOTES
    Author: Proserv Team - VS
    Last Updated: 2025-06-06
    Requirements: PowerShell 5.1+, Administrative privileges (SYSTEM account)
#>

# Check for admin privileges (SYSTEM account expected)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "ERROR: Script requires administrative privileges. Run as SYSTEM or Administrator."
    exit 1
}

#region Privilege Setup
# Enable SeRestorePrivilege and SeBackupPrivilege for registry hive access
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class PrivilegeEnabler {
    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out LUID lpLuid);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges, ref TOKEN_PRIVILEGES NewState, uint BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

    [StructLayout(LayoutKind.Sequential)]
    public struct LUID { public uint LowPart; public int HighPart; }

    [StructLayout(LayoutKind.Sequential)]
    public struct TOKEN_PRIVILEGES { public uint PrivilegeCount; public LUID Luid; public uint Attributes; }

    public const uint TOKEN_ADJUST_PRIVILEGES = 0x0020;
    public const uint TOKEN_QUERY = 0x0008;
    public const uint SE_PRIVILEGE_ENABLED = 0x00000002;

    public static void EnablePrivilege(string privilege) {
        IntPtr token;
        LUID luid;
        TOKEN_PRIVILEGES newPrivileges = new TOKEN_PRIVILEGES();

        if (!OpenProcessToken(System.Diagnostics.Process.GetCurrentProcess().Handle, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, out token)) {
            throw new Exception("OpenProcessToken failed: " + Marshal.GetLastWin32Error());
        }

        if (!LookupPrivilegeValue(null, privilege, out luid)) {
            throw new Exception("LookupPrivilegeValue failed: " + Marshal.GetLastWin32Error());
        }

        newPrivileges.PrivilegeCount = 1;
        newPrivileges.Luid = luid;
        newPrivileges.Attributes = SE_PRIVILEGE_ENABLED;

        if (!AdjustTokenPrivileges(token, false, ref newPrivileges, 0, IntPtr.Zero, IntPtr.Zero)) {
            throw new Exception("AdjustTokenPrivileges failed: " + Marshal.GetLastWin32Error());
        }
    }
}
"@

try {
    [PrivilegeEnabler]::EnablePrivilege("SeRestorePrivilege") # For writing to registry
    [PrivilegeEnabler]::EnablePrivilege("SeBackupPrivilege")  # For reading from registry
} catch {
    Write-Output "ERROR: Failed to enable required privileges: $_"
    exit 1
}
#endregion Privilege Setup

#region Registry Hive Management
# Load Registry API for hive loading/unloading
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class RegistryApi {
    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern int RegLoadKey(IntPtr hKey, string lpSubKey, string lpFile);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern int RegUnLoadKey(IntPtr hKey, string lpSubKey);
}
"@

# Function to unload registry hive with retry logic
function Unload-RegistryHive {
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserSID,
        [int]$MaxRetries = 3,
        [int]$RetryDelaySeconds = 2
    )

    # Validate SID format
    if ($UserSID -notmatch '^S-1-(\d+-?){6}$') {
        #Write-Warning "Invalid SID format: $UserSID"
        return
    }

    $HKEY_USERS = [Microsoft.Win32.Registry]::Users.Handle.DangerousGetHandle()
    $errorCodes = @()

    for ($i = 0; $i -lt $MaxRetries; $i++) {
        # Release .NET handles before unloading
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()

        $result = [RegistryApi]::RegUnLoadKey($HKEY_USERS, $UserSID)
        if ($result -eq 0) {
            #Write-Output "Successfully unloaded registry hive for $UserSID on attempt $($i + 1)"
            return
        } else {
            $errorCodes += $result
            #Write-Output "Attempt $($i + 1) to unload hive for $UserSID failed with exit code $result"
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    #Write-Warning "Could not unload registry hive for $UserSID after $MaxRetries attempts. Error codes: $($errorCodes -join ',')"
}
#endregion Registry Hive Management

#region Interactive User Detection
# Define SID pattern for valid user SIDs
[string]$SIDPattern = '^S-1-(\d+-?){6}$'
[array]$registrySIDs = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.PSChildName -match $SIDPattern } | Select-Object -ExpandProperty PSChildName

# Get interactive logon sessions (console=2, RDP=10)
[array]$interactiveLogons = try {
    Get-CimInstance Win32_LogonSession -Filter "LogonType = 2 OR LogonType = 10" -ErrorAction Stop
} catch {
    #Write-Verbose "Error querying Win32_LogonSession: $_"
    [array]::Empty()
}

# Get associated user accounts
[array]$loggedOnUsers = @()
foreach ($session in $interactiveLogons) {
    [array]$users = try {
        Get-CimAssociatedInstance -InputObject $session -ResultClassName Win32_Account -ErrorAction Stop
    } catch {
        [array]::Empty()
    }
    if ( $users.Count -gt 0 ) {
        $loggedOnUsers += $users
    }
}

[array]$LoggedInUsersSIDs = $loggedOnUsers | 
    Where-Object { $_.SID -match $SIDPattern } | 
    Select-Object -ExpandProperty SID -Unique | 
    Where-Object { $_ -in $registrySIDs }
#endregion Interactive User Detection

#region User Profile Processing
# Process all user profiles
Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -match $SIDPattern } | ForEach-Object {
    $UserProfilePath = $_.LocalPath # User's profile folder (e.g., C:\Users\Username)
    $UserSID = $_.SID               # User's Security Identifier
    $Account = New-Object Security.Principal.SecurityIdentifier($UserSID)
    
    # Convert SID to username for logging and task principal
    $UserPrincipal = try {
        $Account.Translate([Security.Principal.NTAccount]).Value
    } catch {
        #Write-Warning "Unable to resolve SID $UserSID to account. Skipping."
        return
    }

    $HiveLoaded = $false
    # Load registry hive if not already loaded
    if (-not (Test-Path "Registry::HKEY_USERS\$UserSID")) {
        try {
            $hivePath = Join-Path $UserProfilePath 'ntuser.dat'
            if (-not (Test-Path $hivePath)) {
                #Write-Warning "ntuser.dat not found for $UserPrincipal ($UserSID). Skipping."
                return
            }
            $HKEY_USERS = [Microsoft.Win32.Registry]::Users.Handle.DangerousGetHandle()
            $result = [RegistryApi]::RegLoadKey($HKEY_USERS, $UserSID, $hivePath)
            if ($result -ne 0) {
                throw "RegLoadKey failed with code: $result"
            }
            $HiveLoaded = $true
            #Write-Output "Loaded registry hive for $UserPrincipal ($UserSID)"
        } catch {
            #Write-Warning "Could not load registry hive for $UserPrincipal ($UserSID): $_"
            return
        }
    }

    try {
        # Scan Uninstall registry key for Teams
        [string]$regPath = "Registry::HKEY_USERS\$UserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        $uninstallKey = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue | Where-Object {
            (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DisplayName -like "*Teams*"
        }

        if ($uninstallKey) {
            $uninstallString = (Get-ItemProperty $uninstallKey.PSPath).UninstallString
            if ($uninstallString) {
                # Parse UninstallString to separate executable and arguments
                if ($uninstallString -match '^"([^"]+)"(.*)') {
                    $exe = $matches[1]
                    $uninstallArgs = $matches[2].Trim()
                } elseif ($uninstallString -match '^(\S+)(.*)') {
                    $exe = $matches[1]
                    $uninstallArgs = $matches[2].Trim()
                } else {
                    $exe = $uninstallString
                    $uninstallArgs = ""
                }

                # Ensure silent uninstall by adding -s if not present
                if ($uninstallArgs -notlike '*-s*') {
                    $uninstallArgs = "$uninstallArgs -s".Trim()
                }

                # Check if user is interactively logged on
                $userIsLoggedOn = $LoggedInUsersSIDs -contains $UserSID

                # Set task trigger based on login status
                [string]$msgDetected = "INFO: Microsoft Teams per-user installation detected for $UserPrincipal"
                if ($userIsLoggedOn) {
                    $trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1))
                    Write-Output "$msgDetected. User is currently logged on; uninstall task scheduled to run in 1 minute."
                } else {
                    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $UserPrincipal
                    Write-Output "$msgDetected. User is not currently logged on; uninstall task scheduled to run at next logon."
                }

                # Create scheduled task with ServiceAccount
                [string]$taskName = "UninstallTeams_$($UserSID.Replace('-', ''))"
                $TaskParameters = @{
                    TaskName  = $taskName
                    Trigger   = $trigger
                    Principal = New-ScheduledTaskPrincipal -UserId $UserPrincipal # -LogonType ServiceAccount
                    Action    = New-ScheduledTaskAction -Execute $exe -Argument $uninstallArgs
                }

                # Overwrite existing task if it exists, but verify it's Teams-related
                if ($existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
                    if ($existingTask.Actions.Execute -like "*Teams*") {
                        #Write-Output "Overwriting existing Teams-related task $taskName for user: $UserPrincipal"
                        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
                    } else {
                        #Write-Warning "Task $taskName exists but is not Teams-related. Skipping overwrite."
                        return
                    }
                }

                # Register the task
                Register-ScheduledTask @TaskParameters | Out-Null
                #Write-Output "INFO: Registered task $taskName for $UserPrincipal"
            } else {
                Write-Output "INFO: Uninstall string not found for $UserPrincipal"
            }
        } else {
            Write-Output "INFO: Microsoft Teams not found in uninstall registry hive for $UserPrincipal"
        }
    } catch {
        #Write-Warning "Error accessing uninstall key for $UserPrincipal ($UserSID): $_"
    } finally {
        # Unload registry hive if loaded
        if ($HiveLoaded) {
            Unload-RegistryHive -UserSID $UserSID
        }
    }
}
#endregion User Profile Processing

#region MSIX Package Removal
try {
    $teamsPackages = Get-AppxPackage -AllUsers -Name "*Teams*" -ErrorAction SilentlyContinue
    if ($teamsPackages) {
        foreach ($package in $teamsPackages) {
            try {
                Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
                Write-Output "INFO: Removed Teams MSIX package for user: $($package.PackageUserInformation)"
            } catch {
                Write-Output "ERROR: Failed to remove Teams MSIX package for user $($package.PackageUserInformation): $_"
            }
        }
    } else {
        Write-Output "INFO: No Teams MSIX packages found for any users."
    }
} catch {
    Write-Output "ERROR: Failed to enumerate Teams MSIX packages: $_"
}

try {
    $provisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*Teams*" }
    if ($provisionedPackages) {
        foreach ($package in $provisionedPackages) {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName -ErrorAction Stop
                Write-Output "INFO: Removed provisioned Teams MSIX package: $($package.PackageName)"
            } catch {
                Write-Output "ERROR: Failed to remove provisioned package $($package.PackageName): $_"
            }
        }
    } else {
        Write-Output "INFO: No provisioned Teams MSIX packages found."
    }
} catch {
    Write-Output "ERROR: Failed to enumerate provisioned Teams MSIX packages: $_"
}
#endregion MSIX Package Removal