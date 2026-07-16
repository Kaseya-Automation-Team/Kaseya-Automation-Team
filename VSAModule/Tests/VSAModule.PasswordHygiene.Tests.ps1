BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "Tenant/user password exposure minimized (T-5.5 / F-55)" {

    It "New-VSATenant's -Debug stream does not contain the plaintext password" {
        InModuleScope VSAModule {
            Mock Invoke-VSARestMethod {}
            $secret = 'S3cretPassw0rd!12345678'
            $securePassword = ConvertTo-SecureString $secret -AsPlainText -Force
            $debugOutput = New-VSATenant -Ref 'TestTenant' -AdminUserName 'admin' -EMail 'a@b.com' -Password $securePassword -Debug 5>&1 | Out-String
            $debugOutput | Should -Not -Match ([regex]::Escape($secret))
        }
    }

    It "New-VSATenant clears the standalone plaintext-password variable after building the body" {
        $content = Get-Content -Path (Join-Path $script:ModuleRoot 'public/New-VSATenant.ps1') -Raw
        $content | Should -Match '\$PlainPassword\s*=\s*\$null'
    }

    It "Update-VSAUser clears the standalone plaintext-password variable after building the body" {
        $content = Get-Content -Path (Join-Path $script:ModuleRoot 'public/Update-VSAUser.ps1') -Raw
        $content | Should -Match '\$PasswordForBody\s*=\s*\$null'
    }
}

Describe "New-VSATenant - ScopeRef/RoleRef (documented TenantUser fields, 2026-07-03 doc research)" {
    It "sends ScopeRef and RoleRef in the body when provided" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            $securePassword = ConvertTo-SecureString 'S3cretPassw0rd!12345678' -AsPlainText -Force
            New-VSATenant -Ref 'TestTenant' -AdminUserName 'admin' -EMail 'a@b.com' -Password $securePassword -ScopeRef 'MyScope' -RoleRef 'MyRole' | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.TenantUser.ScopeRef | Should -Be 'MyScope'
            $obj.TenantUser.RoleRef | Should -Be 'MyRole'
        }
    }

    It "omits ScopeRef and RoleRef from the body when not provided" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            $securePassword = ConvertTo-SecureString 'S3cretPassw0rd!12345678' -AsPlainText -Force
            New-VSATenant -Ref 'TestTenant' -AdminUserName 'admin' -EMail 'a@b.com' -Password $securePassword | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.TenantUser.PSObject.Properties.Name | Should -Not -Contain 'ScopeRef'
            $obj.TenantUser.PSObject.Properties.Name | Should -Not -Contain 'RoleRef'
        }
    }
}
