BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "Pipeline correctness - process{} wrapping (T-7.1)" {

    It "piping two objects with an AgentId property into Get-VSAAgentLog yields two transport calls" {
        InModuleScope VSAModule {
            $script:calls = 0
            Mock Invoke-VSARestMethod { $script:calls++ }
            @(
                [pscustomobject]@{ AgentId = '111' }
                [pscustomobject]@{ AgentId = '222' }
            ) | Get-VSAAgentLog | Out-Null
            $script:calls | Should -Be 2
        }
    }

    It "piping two objects into a public Get- cmdlet (Get-VSAAgentUptime) yields two transport calls" {
        InModuleScope VSAModule {
            $script:calls = 0
            Mock Invoke-VSARestMethod { $script:calls++ }
            @(
                [pscustomobject]@{ Since = '2024-01-01' }
                [pscustomobject]@{ Since = '2024-02-01' }
            ) | Get-VSAAgentUptime | Out-Null
            $script:calls | Should -Be 2
        }
    }

    It "URISuffix on a piped object does not override the internally computed URISuffix" {
        InModuleScope VSAModule {
            $script:suffixes = New-Object System.Collections.ArrayList
            Mock Invoke-VSARestMethod { $null = $script:suffixes.Add($URISuffix) }
            [pscustomobject]@{ AgentId = '333'; URISuffix = 'evil/override' } | Get-VSAAgentLog | Out-Null
            $script:suffixes[0] | Should -Not -Match 'evil/override'
        }
    }
}
