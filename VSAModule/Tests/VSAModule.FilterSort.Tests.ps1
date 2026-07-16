BeforeAll {
    $ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $ModuleRoot 'VSAModule.psd1') -Force
}

# Get-VSATenantModuleLicense and Get-VSATenantRoletypeFunclist declared -Filter/-Sort (and documented
# them) but never forwarded them to the transport, so they were silently ignored. These tests lock in
# the wiring: the values must reach Invoke-VSARestMethod, and empty ones must not be forwarded.
# (Pester exposes a mocked command's bound arguments as named variables in the mock body, so we capture
# $Filter/$Sort directly rather than $PSBoundParameters, which does not reflect splatted arguments.)
Describe "Tenant list cmdlets forward -Filter/-Sort to the transport" {

    It "Get-VSATenantModuleLicense forwards -Filter and -Sort" {
        InModuleScope VSAModule {
            $script:f = $script:s = '<unset>'
            Mock Invoke-VSARestMethod { $script:f = $Filter; $script:s = $Sort }
            Get-VSATenantModuleLicense -TenantId 10001 -Filter "Name eq 'x'" -Sort "Name" | Out-Null
            $script:f | Should -Be "Name eq 'x'"
            $script:s | Should -Be "Name"
        }
    }

    It "Get-VSATenantModuleLicense does not forward Filter/Sort when not supplied" {
        InModuleScope VSAModule {
            $script:f = $script:s = '<unset>'
            Mock Invoke-VSARestMethod { $script:f = $Filter; $script:s = $Sort }
            Get-VSATenantModuleLicense -TenantId 10001 | Out-Null
            $script:f | Should -BeNullOrEmpty
            $script:s | Should -BeNullOrEmpty
        }
    }

    It "Get-VSATenantRoletypeFunclist forwards -Filter and -Sort" {
        InModuleScope VSAModule {
            $script:f = $script:s = '<unset>'
            Mock Invoke-VSARestMethod { $script:f = $Filter; $script:s = $Sort }
            Get-VSATenantRoletypeFunclist -RoleTypeId 4 -Filter "funcName eq 'y'" -Sort "funcName desc" | Out-Null
            $script:f | Should -Be "funcName eq 'y'"
            $script:s | Should -Be "funcName desc"
        }
    }

    It "Get-VSATenantRoletypeFunclist does not forward Filter/Sort when not supplied" {
        InModuleScope VSAModule {
            $script:f = $script:s = '<unset>'
            Mock Invoke-VSARestMethod { $script:f = $Filter; $script:s = $Sort }
            Get-VSATenantRoletypeFunclist -RoleTypeId 4 | Out-Null
            $script:f | Should -BeNullOrEmpty
            $script:s | Should -BeNullOrEmpty
        }
    }
}
