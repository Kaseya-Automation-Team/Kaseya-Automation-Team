BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "Dispatch engines give an actionable error when called directly, not the opaque validator (E)" {

    It "Get-VSAItem (bare) names itself the dispatch engine and points to Get-Alias" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            $err = $null
            try { Get-VSAItem -VSAConnection $conn -ErrorAction Stop } catch { $err = $_ }
            $err | Should -Not -BeNullOrEmpty
            # NOT the opaque "not a valid value for the URISuffix variable" the assignment used to throw.
            $err.Exception.Message | Should -Not -Match 'not a valid value for the URISuffix'
            $err.Exception.Message | Should -Match 'dispatch engine'
            $err.Exception.Message | Should -Match 'Get-Alias -Definition Get-VSAItem'
        }
    }

    It "Get-VSAItemById (bare, dummy id) gives the actionable message" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            $err = $null
            try { Get-VSAItemById -VSAConnection $conn -Id '1' -ErrorAction Stop } catch { $err = $_ }
            $err | Should -Not -BeNullOrEmpty
            $err.Exception.Message | Should -Match 'dispatch engine'
            $err.Exception.Message | Should -Match 'Get-Alias -Definition Get-VSAItemById'
        }
    }

    It "Remove-VSAItem (bare, dummy id) gives the actionable message" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            $err = $null
            try { Remove-VSAItem -VSAConnection $conn -Id '1' -Confirm:$false -ErrorAction Stop } catch { $err = $_ }
            $err | Should -Not -BeNullOrEmpty
            $err.Exception.Message | Should -Match 'dispatch engine'
            $err.Exception.Message | Should -Match 'Get-Alias -Definition Remove-VSAItem'
        }
    }
}
