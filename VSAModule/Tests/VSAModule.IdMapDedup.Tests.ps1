BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "Hoisted ID maps are single-sourced and match their ValidateSet literals (T-7.6 / F-53)" {

    It "TenantModuleIdMap exists exactly once, in private/VSAEndpointMaps.ps1; TenantRoleTypeIdMap is gone (F-64)" {
        # The maps were extracted from the .psm1 into a dot-sourced private data file for readability;
        # TenantModuleIdMap must still be single-sourced there. TenantRoleTypeIdMap was removed in F-64
        # (role types are now resolved dynamically via Get-VSARoleType) and must not exist anywhere.
        $mapsFile = Join-Path $script:ModuleRoot 'private/VSAEndpointMaps.ps1'
        Test-Path $mapsFile | Should -Be $true
        $maps = Get-Content -Path $mapsFile -Raw
        ([regex]::Matches($maps, '\$(?:script:)?TenantModuleIdMap\s*=\s*@\{')).Count | Should -Be 1

        # TenantModuleIdMap not redefined elsewhere; TenantRoleTypeIdMap not defined anywhere at all.
        $allFiles = @(Get-ChildItem -Path (Join-Path $script:ModuleRoot 'public'), (Join-Path $script:ModuleRoot 'private') -Filter '*.ps1' -File)
        $allFiles += Get-Item (Join-Path $script:ModuleRoot 'VSAModule.psm1')
        foreach ($f in $allFiles) {
            $content = Get-Content -LiteralPath $f.FullName -Raw
            if ($f.Name -ne 'VSAEndpointMaps.ps1') {
                $content | Should -Not -Match '\$(?:script:)?TenantModuleIdMap\s*=\s*@\{'
            }
            $content | Should -Not -Match '\$(?:script:)?TenantRoleTypeIdMap\s*=\s*@\{'
        }
    }

    It "Enable-VSATenantModule's ModuleName/ModuleId ValidateSets match the module-scope map's keys/values" {
        InModuleScope VSAModule {
            $cmd = Get-Command Enable-VSATenantModule
            $namesInSet = [string[]](($cmd.Parameters['ModuleName'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues)
            $idsInSet = [int[]](($cmd.Parameters['ModuleId'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues)
            @(Compare-Object $namesInSet ([string[]]$TenantModuleIdMap.Keys)) | Should -BeNullOrEmpty
            @(Compare-Object $idsInSet ([int[]]$TenantModuleIdMap.Values)) | Should -BeNullOrEmpty
        }
    }

    It "Remove-VSATenantModule's ModuleName/ModuleId ValidateSets match the module-scope map's keys/values" {
        InModuleScope VSAModule {
            $cmd = Get-Command Remove-VSATenantModule
            $namesInSet = [string[]](($cmd.Parameters['ModuleName'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues)
            $idsInSet = [int[]](($cmd.Parameters['ModuleId'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues)
            @(Compare-Object $namesInSet ([string[]]$TenantModuleIdMap.Keys)) | Should -BeNullOrEmpty
            @(Compare-Object $idsInSet ([int[]]$TenantModuleIdMap.Values)) | Should -BeNullOrEmpty
        }
    }

    It "Enable/Clear-VSATenantRoleType no longer hardcode a role-type ValidateSet (F-64: resolved at runtime)" {
        # The stale ValidateSet + static map were replaced by live Get-VSARoleType resolution, so an
        # instance's custom / multi-tenant role types are reachable. Assert the ValidateSet is gone.
        InModuleScope VSAModule {
            foreach ($pair in @(@('Enable-VSATenantRoleType','RoleType'), @('Clear-VSATenantRoleType','RoleTypeName'))) {
                $cmd = Get-Command $pair[0]
                $vs = $cmd.Parameters[$pair[1]].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
                $vs | Should -BeNullOrEmpty -Because "$($pair[0]) -$($pair[1]) should resolve dynamically, not via a hardcoded ValidateSet"
            }
        }
    }

    It "Enable-VSATenantModule resolves a multi-select ModuleName correctly (F-35-style array-key bug fixed)" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Enable-VSATenantModule -TenantId 10001 -ModuleName 'Agent', 'Backup' | Out-Null
            $arr = $script:body | ConvertFrom-Json
            $arr | Should -Contain 9
            $arr | Should -Contain 12
        }
    }

    It "Remove-VSATenantModule resolves ModuleName to the correct Id" {
        InModuleScope VSAModule {
            $script:capturedSuffix = $null
            Mock Invoke-VSARestMethod { $script:capturedSuffix = $URISuffix }
            Remove-VSATenantModule -TenantId 10001 -ModuleName 'Backup' | Out-Null
            $script:capturedSuffix | Should -Match 'moduleId=12'
        }
    }

    It "Enable-VSATenantRoleType resolves RoleType names to Ids via live Get-VSARoleType (incl. instance-specific ones)" {
        InModuleScope VSAModule {
            $script:body = $null
            # A live role-type set that includes types the OLD hardcoded map never had.
            Mock Get-VSARoleType {
                @(
                    [pscustomobject]@{ RoleTypeId = 4;    RoleTypeName = 'VSA Admin' }
                    [pscustomobject]@{ RoleTypeId = 90;   RoleTypeName = 'Multi-Tenant' }
                    [pscustomobject]@{ RoleTypeId = 1234; RoleTypeName = 'Multi-Tenant Admin' }
                )
            }
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Enable-VSATenantRoleType -TenantId 10001 -RoleType 'Multi-Tenant', 'Multi-Tenant Admin' | Out-Null
            $arr = $script:body | ConvertFrom-Json
            $arr | Should -Contain 90
            $arr | Should -Contain 1234
        }
    }

    It "Enable-VSATenantRoleType throws a clear error for a role type that does not exist on the instance" {
        InModuleScope VSAModule {
            Mock Get-VSARoleType { @([pscustomobject]@{ RoleTypeId = 4; RoleTypeName = 'VSA Admin' }) }
            Mock Invoke-VSARestMethod {}
            { Enable-VSATenantRoleType -TenantId 10001 -RoleType 'No Such Role' } |
                Should -Throw -ExpectedMessage '*No role type found with name ''No Such Role''*'
        }
    }

    It "Clear-VSATenantRoleType resolves RoleTypeName to the correct Id via live Get-VSARoleType" {
        InModuleScope VSAModule {
            $script:capturedSuffix = $null
            Mock Get-VSATenants { [pscustomobject]@{ Id = '99'; Ref = 'Acme' } }
            Mock Get-VSARoleType { @([pscustomobject]@{ RoleTypeId = 1234; RoleTypeName = 'Multi-Tenant Admin' }) }
            Mock Invoke-VSARestMethod { $script:capturedSuffix = $URISuffix }
            Clear-VSATenantRoleType -TenantName 'Acme' -RoleTypeName 'Multi-Tenant Admin' | Out-Null
            $script:capturedSuffix | Should -Match 'roleTypeId=1234'
        }
    }
}
