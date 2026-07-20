BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
    # A real 26-digit RoleTypeId observed on the sandbox, and a second 26-digit identity. These
    # overflow Int32/Int64 and, as JSON numbers, lose precision -- so they can only travel as strings.
    $script:BigId  = '52361412952525411214415725'
    $script:BigId2 = '11257819792528624824877126'
}

Describe "VSA object ids are 26-digit strings across mutating cmdlets (F-82)" {

    It "<Cmd> -<Param> is typed [<Type>], not a numeric type that overflows or renders N.0" -TestCases @(
        @{ Cmd = 'Update-VSAUser';           Param = 'UserId';                   Type = [string]   }
        @{ Cmd = 'Update-VSAUser';           Param = 'DefaultStaffOrgId';        Type = [string]   }
        @{ Cmd = 'Update-VSAUser';           Param = 'DefaultStaffDepartmentId'; Type = [string]   }
        @{ Cmd = 'Update-VSAUser';           Param = 'AdminRoleIds';             Type = [string[]] }
        @{ Cmd = 'Update-VSAUser';           Param = 'AdminScopeIds';            Type = [string[]] }
        @{ Cmd = 'Set-VSAAgentAlert';        Param = 'ScriptId';                 Type = [string]   }
        @{ Cmd = 'Set-VSASystemAlert';       Param = 'ScriptId';                 Type = [string]   }
        @{ Cmd = 'Enable-VSATenantRoleType'; Param = 'RoleTypeId';               Type = [string[]] }
        @{ Cmd = 'Update-VSAInfoMsg';        Param = 'ID';                       Type = [string[]] }
    ) {
        param($Cmd, $Param, $Type)
        (Get-Command $Cmd).Parameters[$Param].ParameterType | Should -Be $Type
    }

    It "Update-VSAUser sends a 26-digit UserId and AdminRoleIds as full-precision strings (no N.0)" {
        InModuleScope VSAModule -Parameters @{ big = $script:BigId; big2 = $script:BigId2 } {
            param($big, $big2)
            $script:body = $null
            Mock Invoke-VSAWriteRequest { $script:body = $Body }
            Update-VSAUser -UserId $big -AdminRoleIds @($big2) -FirstName 'x' -Confirm:$false | Out-Null
            $script:body | Should -Match ([regex]::Escape($big))
            $script:body | Should -Match ([regex]::Escape($big2))
            $script:body | Should -Not -Match '\.0'
            $obj = $script:body | ConvertFrom-Json
            "$($obj.UserId)"       | Should -Be $big
            "$($obj.AdminRoleIds)" | Should -Be $big2
        }
    }

    It "Enable-VSATenantRoleType sends a 26-digit RoleTypeId as a full-precision string (would overflow [int])" {
        InModuleScope VSAModule -Parameters @{ big = $script:BigId } {
            param($big)
            $script:body = $null
            Mock Invoke-VSAWriteRequest { $script:body = $Body }
            Enable-VSATenantRoleType -TenantId '123' -RoleTypeId @($big) -Confirm:$false | Out-Null
            $script:body | Should -Match ([regex]::Escape($big))
            $script:body | Should -Not -Match '\.0'
            @($script:body | ConvertFrom-Json)[0] | ForEach-Object { "$_" } | Should -Be $big
        }
    }

    It "Update-VSAInfoMsg sends a 26-digit ID as a full-precision string (was [decimal] -> N.0)" {
        InModuleScope VSAModule -Parameters @{ big = $script:BigId } {
            param($big)
            $script:body = $null
            Mock Invoke-VSAWriteRequest { $script:body = $Body }
            Update-VSAInfoMsg -ID @($big) -Confirm:$false | Out-Null
            $script:body | Should -Match ([regex]::Escape($big))
            $script:body | Should -Not -Match '\.0'
        }
    }

    It "the module-catalog ModuleId stays numeric (small fixed ValidateSet, not a SQL identity)" {
        # Not every '*Id' is a 26-digit identity: the tenant module id is a small fixed catalog code
        # (its ValidateSet is integers 0..115), so it correctly stays [int]/[int[]].
        (Get-Command Remove-VSATenantModule).Parameters['ModuleId'].ParameterType | Should -Be ([int])
        (Get-Command Enable-VSATenantModule).Parameters['ModuleId'].ParameterType | Should -Be ([int[]])
    }
}
