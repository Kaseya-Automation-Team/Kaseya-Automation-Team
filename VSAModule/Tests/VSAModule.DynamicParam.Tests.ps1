BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "DynamicParam network calls removed (T-7.2 / F-44)" {

    Context "Get-Command -Syntax triggers zero transport calls" {
        It "<Name>" -ForEach @(
            @{ Name = 'Enable-VSAUser' }
            @{ Name = 'Remove-VSAUser' }
            @{ Name = 'Disable-VSATenant' }
            @{ Name = 'Clear-VSATenantRoleType' }
            @{ Name = 'Set-VSATenantRoletypeLimit' }
            @{ Name = 'Set-VSATenantModuleUsageType' }
            @{ Name = 'Set-VSATenantModuleLicense' }
            @{ Name = 'Update-VSAUser' }
            @{ Name = 'Get-VSAAudit' }
        ) {
            InModuleScope VSAModule -Parameters @{ Name = $Name } {
                param($Name)
                $script:calls = 0
                Mock Invoke-VSARestMethod { $script:calls++ }
                Get-Command -Name $Name -Syntax | Out-Null
                $script:calls | Should -Be 0
            }
        }
    }

    Context 'No script-scoped cross-block state and no DynamicParam blocks remain' {
        It "<Name> has neither a DynamicParam block nor script-scoped variables" -ForEach @(
            @{ Name = 'Enable-VSAUser' }
            @{ Name = 'Remove-VSAUser' }
            @{ Name = 'Disable-VSATenant' }
            @{ Name = 'Clear-VSATenantRoleType' }
            @{ Name = 'Set-VSATenantRoletypeLimit' }
            @{ Name = 'Set-VSATenantModuleUsageType' }
            @{ Name = 'Set-VSATenantModuleLicense' }
            @{ Name = 'Update-VSAUser' }
        ) {
            $path = Join-Path $script:ModuleRoot "public/$Name.ps1"
            $content = Get-Content -Path $path -Raw
            $content | Should -Not -Match '(?im)^\s*DynamicParam\s*\{'
            $content | Should -Not -Match '\$script:'
        }
    }

    Context "Single targeted Begin-block lookup resolves Name to Id" {
        It "Remove-VSAUser resolves AdminName to UserId with one Get-VSAUser call" {
            InModuleScope VSAModule {
                $script:calls = 0
                Mock Invoke-VSARestMethod {
                    $script:calls++
                    [pscustomobject]@{ UserId = '42'; AdminName = 'alice' }
                }
                Remove-VSAUser -AdminName 'alice' | Out-Null
                # One call to resolve AdminName->UserId, one call to perform the DELETE.
                $script:calls | Should -Be 2
            }
        }

        It "Clear-VSATenantRoleType resolves both TenantName and RoleTypeName to Ids" {
            InModuleScope VSAModule {
                $script:capturedSuffix = $null
                # The role-type lookup (system/roletypes) and the write (tenantmanagement/tenant/
                # roletypes) both contain "roletypes", so they must be matched distinctly: a mock that
                # returns nothing for the lookup lets an unresolved role type reach the write.
                Mock Invoke-VSARestMethod {
                    switch -Regex ($URISuffix) {
                        'tenantmanagement/tenant/roletypes' { $script:capturedSuffix = $URISuffix; break }
                        'system/roletypes' { [pscustomobject]@{ RoleTypeId = '6'; RoleTypeName = 'VSA Admin' }; break }
                        default { [pscustomobject]@{ Id = '99'; Ref = 'Acme' } }
                    }
                }
                Clear-VSATenantRoleType -TenantName 'Acme' -RoleTypeName 'VSA Admin' | Out-Null
                # Assert BOTH ids: asserting only the tenant id let an unresolved role type reach the
                # wire as roleTypeId=0 (F-4).
                $script:capturedSuffix | Should -Match 'roletypes/99'
                $script:capturedSuffix | Should -Match 'roleTypeId=6'
            }
        }

        It "Clear-VSATenantRoleType throws rather than sending an unresolved RoleTypeName" {
            InModuleScope VSAModule {
                Mock Invoke-VSARestMethod {
                    if ($URISuffix -match 'system/roletypes') { return }
                    [pscustomobject]@{ Id = '99'; Ref = 'Acme' }
                }
                { Clear-VSATenantRoleType -TenantName 'Acme' -RoleTypeName 'No Such Role' } |
                    Should -Throw '*No role type found*'
            }
        }
    }

    Context "ArgumentCompleter is attached and best-effort" {
        It "Remove-VSAUser's AdminName parameter has an ArgumentCompleter attribute" {
            $cmd = Get-Command -Name Remove-VSAUser
            $param = $cmd.Parameters['AdminName']
            $completer = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ArgumentCompleterAttribute] }
            $completer | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Update-VSAUser ByName keeps Begin-resolved Ids in the body (F-25)" {
    It "resolves AdminName/RoleNames/ScopeNames/OrgName and includes the Ids in the PUT body" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Get-VSAUser         { [pscustomobject]@{ UserId = 42; AdminName = 'jdoe' } }
            Mock Get-VSARoles        { [pscustomobject]@{ RoleId = 7;  RoleName  = 'Admins' } }
            Mock Get-VSAScope        { [pscustomobject]@{ ScopeId = 9; ScopeName = 'AllScope' } }
            Mock Get-VSAOrganization { [pscustomobject]@{ OrgId = 3;   OrgName   = 'Acme' } }
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Update-VSAUser -AdminName 'jdoe' -AdminRoleNames 'Admins' -AdminScopeNames 'AllScope' -DefaultStaffOrgName 'Acme' | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.UserId            | Should -Be 42
            $obj.AdminRoleIds      | Should -Contain 7
            $obj.AdminScopeIds     | Should -Contain 9
            $obj.DefaultStaffOrgId | Should -Be 3
        }
    }
}

Describe "Scheduling DynamicParam binds when Repeat != Never (F-33)" {
    # Before F-33 the helper call sites passed the type in argument position ('-Type [int]'),
    # which PowerShell parsed as the STRING '[int]'. Converting that to [Type] threw, so the whole
    # DynamicParam block failed with "Cannot retrieve the dynamic parameters for the cmdlet" and
    # EVERY recurring (Repeat != 'Never') schedule was unusable. These tests bind a dynamic param
    # (proving the block is retrievable) with the transport mocked so nothing hits the network.
    It "<Name> evaluates its DynamicParam block (Repeat != Never) without the [Type]-cast failure" -ForEach @(
        @{ Name = 'New-VSAAPScheduled';           Args = @{ AgentID='1'; AgentProcedureId='1'; EndAt='2359'; EndOn=[datetime]'2030-12-31'; Repeat='Months' } }
        @{ Name = 'New-VSAScheduleAuditBaseLine';  Args = @{ AgentID='1'; Repeat='Months' } }
        @{ Name = 'Set-VSAAuditSchedule';          Args = @{ AgentID='1'; Repeat='Months' } }
        @{ Name = 'Set-VSAScheduleAuditSysInfo';   Args = @{ AgentID='1'; Repeat='Months' } }
        @{ Name = 'Set-VSAPatchIgnore';            Args = @{ AgentID='1'; Repeat='Months' } }
    ) {
        # -Repeat 'Months' forces PowerShell to retrieve the dynamic parameters. Before the fix that
        # failed for ALL of these with "Cannot retrieve the dynamic parameters ... Cannot convert the
        # '[int]' value ... to type 'System.Type'". Each cmdlet's mandatory params are supplied so
        # nothing prompts, and the transport is mocked so nothing hits the network.
        InModuleScope VSAModule -Parameters @{ Name = $Name; CmdArgs = $Args } {
            param($Name, $CmdArgs)
            Mock Invoke-VSARestMethod { }
            $err = $null
            try { & $Name @CmdArgs -ErrorAction Stop 6>$null } catch { $err = "$($_.Exception.Message)" }
            $err | Should -Not -Match 'dynamic parameter'
            $err | Should -Not -Match "Cannot convert.*'System\.Type'"
        }
    }

    It "New-VSAAPScheduled binds -DayOfMonth 'LastDay' and reaches the transport (no [Type] cast error)" {
        InModuleScope VSAModule {
            $script:reached = $false
            Mock Invoke-VSARestMethod { $script:reached = $true }
            $threw = $null
            try {
                New-VSAAPScheduled -AgentID 123 -AgentProcedureId 456 -Repeat 'Months' `
                    -DayOfMonth 'LastDay' -EndAt '2359' -EndOn ([datetime]'2030-12-31') `
                    -StartOn ([datetime]'2030-01-01') | Out-Null
            } catch { $threw = $_.Exception.Message }
            # The F-33 regression signature was a binding-time failure; assert it is gone and the
            # body actually reached the (mocked) transport.
            $threw | Should -Not -Match 'dynamic parameter'
            $threw | Should -Not -Match 'Cannot convert.*System\.Type'
            $script:reached | Should -BeTrue
        }
    }
}

Describe "Scheduling cmdlets have no static/dynamic parameter collisions (F-36)" {
    # Set-VSAPatchIgnore declared EndAt/EndOn/EndAfterIntervalTimes/SpecificDayOfMonth BOTH as static
    # params and again in its DynamicParam block. During discovery ($Repeat unbound -> guard true) the
    # dynamic block runs and PowerShell throws "A parameter with the name '<x>' was defined multiple
    # times", leaving Get-Command's .Parameters null -- which crashed unrelated metadata tests. Guard:
    # every scheduling cmdlet must expose a non-null parameter set and resolve a dynamic param cleanly.
    It "<Name> exposes non-null .Parameters and resolves a dynamic param without a duplicate-name error" -ForEach @(
        @{ Name = 'New-VSAAPScheduled' }
        @{ Name = 'New-VSAScheduleAuditBaseLine' }
        @{ Name = 'Set-VSAAuditSchedule' }
        @{ Name = 'Set-VSAScheduleAuditSysInfo' }
        @{ Name = 'Set-VSAPatchIgnore' }
        @{ Name = 'Start-VSAPatchUpdate' }
    ) {
        $cmd = Get-Command $Name -Module VSAModule
        $cmd.Parameters | Should -Not -BeNullOrEmpty
        { $cmd.ResolveParameter('DayOfMonth') } | Should -Not -Throw
    }
}
