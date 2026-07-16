# $ModuleRoot is resolved at script scope so it is available during Pester DISCOVERY (the -ForEach
# blocks below are evaluated then, before any BeforeAll runs).
$ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
$script:PublicFiles = Get-ChildItem -Path (Join-Path $ModuleRoot 'public') -Filter '*.ps1' |
    ForEach-Object { @{ File = $_.FullName; Name = $_.BaseName } }

BeforeAll {
    $ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $ModuleRoot 'VSAModule.psd1') -Force
}

Describe "VSAModule comment-based help" {

    # The module ships help as comment-based help embedded in every public function -- there is no
    # external MAML (en-US) help file (it was inert: comment-based help always shadows it). These
    # tests validate the help mechanism that is actually surfaced by Get-Help.

    Context "Every public function has comment-based help" {
        It "declares a non-empty .SYNOPSIS in source: <Name>" -ForEach $script:PublicFiles {
            $content = Get-Content -Path $File -Raw
            $content | Should -Match '\.SYNOPSIS|\.Synopsis'
        }

        It "exposes a prose Synopsis via Get-Help: <Name>" -ForEach $script:PublicFiles {
            $help = Get-Help -Name $Name -ErrorAction SilentlyContinue
            # A function without comment-based help yields an auto-generated synopsis equal to its
            # syntax line (starts with the command name); a real synopsis is prose.
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Synopsis.Trim() | Should -Not -Match "^$Name\b"
        }
    }

    Context "Key function documentation" {
        It "Get-Help works for New-VSAConnection" {
            { Get-Help -Name 'New-VSAConnection' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "New-VSAConnection has a description" {
            $help = Get-Help -Name 'New-VSAConnection' -Full -ErrorAction SilentlyContinue
            ($help.description | Out-String).Trim() | Should -Not -BeNullOrEmpty
        }

        It "New-VSAConnection documents examples" {
            $help = Get-Help -Name 'New-VSAConnection' -Examples -ErrorAction SilentlyContinue
            $help.examples.example | Should -Not -BeNullOrEmpty
        }

        It "Get-Help -Full does not throw" {
            { Get-Help -Name 'New-VSAConnection' -Full -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Alias help resolves to its target function" {
        # Aliases (e.g. Get-VSAAgentNote -> Get-VSAItem) resolve to the target's comment-based help.
        It "Get-Help works for an exported alias" {
            $alias = Get-Command -Module VSAModule -CommandType Alias | Select-Object -First 1
            $alias | Should -Not -BeNullOrEmpty
            { Get-Help -Name $alias.Name -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}
