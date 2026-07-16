BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    $script:Mod = Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force -PassThru
    $script:Manifest = Import-PowerShellDataFile (Join-Path $script:ModuleRoot 'VSAModule.psd1')
}

Describe "Endpoint-map integrity (data-driven dispatchers)" {

    # Pull the three maps out of module scope so the tests operate on the live data.
    BeforeAll {
        $script:GetMap    = & $script:Mod { $URISuffixGetMap }
        $script:GetByIdMap = & $script:Mod { $URISuffixGetByIdMap }
        $script:RemoveMap = & $script:Mod { $URISuffixRemoveMap }
    }

    It "every collection-GET alias resolves to Get-VSAItem" {
        foreach ($k in $script:GetMap.Keys) {
            (Get-Alias $k -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Get-VSAItem' -Because $k
        }
    }

    It "every by-Id GET alias resolves to Get-VSAItemById and its endpoint has a {0} placeholder" {
        foreach ($k in $script:GetByIdMap.Keys) {
            (Get-Alias $k -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Get-VSAItemById' -Because $k
            $script:GetByIdMap[$k] | Should -Match '\{0\}' -Because "$k is a by-Id endpoint"
        }
    }

    It "every remove alias resolves to Remove-VSAItem and its endpoint has a {0} placeholder" {
        foreach ($k in $script:RemoveMap.Keys) {
            (Get-Alias $k -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Remove-VSAItem' -Because $k
            $script:RemoveMap[$k] | Should -Match '\{0\}' -Because $k
        }
    }

    It "every map key is declared in the manifest AliasesToExport (else it is filtered out on import)" {
        # This is the invariant that silently drops new aliases if forgotten: Export-ModuleMember must
        # be matched by an AliasesToExport entry or the alias never reaches the caller.
        $allKeys = @($script:GetMap.Keys) + @($script:GetByIdMap.Keys) + @($script:RemoveMap.Keys)
        $declared = $script:Manifest.AliasesToExport
        $missing = $allKeys | Where-Object { $_ -notin $declared }
        ($missing -join ', ') | Should -BeNullOrEmpty
    }

    It "every map endpoint targets the REST API base path" {
        foreach ($map in $script:GetMap, $script:GetByIdMap, $script:RemoveMap) {
            foreach ($v in $map.Values) { $v | Should -Match '^api/v[0-9.]+/' }
        }
    }
}
