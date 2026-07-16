# Persistent-connection encryption is platform-sensitive (F-60): ConvertTo-/ConvertFrom-SecureString
# with no -Key is Windows DPAPI, but on Linux/macOS (no DPAPI) that same no-key form "succeeds" while
# being trivially reversible -- obfuscation, not encryption. The fix selects a protect/unprotect
# strategy once at module load: DPAPI on Windows, AES with a runtime-derived, never-stored key
# elsewhere. This mirrors the F-27 cert-bypass load-time strategy-selection pattern.

# Computed during Discovery, independently of the module, so the -Skip conditions below resolve to
# the running platform's path even before Import-Module has run.
$script:IsWindowsPlatform = if (Test-Path -Path Variable:IsWindows) { $IsWindows } else { $true }

BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "Persistent-connection encryption strategy is platform-detected (F-60)" {

    AfterEach {
        [Environment]::SetEnvironmentVariable('VSAConnection', $null)
    }

    Context "source guarantees (platform-independent)" {

        It "detects the platform once at import via a script-scope flag" {
            $psm1 = Get-Content -Path (Join-Path $script:ModuleRoot 'VSAModule.psm1') -Raw
            $psm1 | Should -Match '\$script:VSAIsWindows\s*='
        }

        It "the Windows branch uses ConvertTo-/ConvertFrom-SecureString with no -Key (DPAPI)" {
            $psm1 = Get-Content -Path (Join-Path $script:ModuleRoot 'VSAModule.psm1') -Raw
            $psm1 | Should -Match 'ConvertFrom-SecureString\s+-SecureString\s+\$secureString\s*\)'
        }

        It "the non-Windows branch uses ConvertTo-/ConvertFrom-SecureString with a derived -Key" {
            $psm1 = Get-Content -Path (Join-Path $script:ModuleRoot 'VSAModule.psm1') -Raw
            $psm1 | Should -Match 'ConvertFrom-SecureString\s+-SecureString\s+\$secureString\s+-Key\s+\$key'
            $psm1 | Should -Match 'ConvertTo-SecureString\s+-String\s+\$Protected\s+-Key\s+\$key'
        }

        It "the derived key is never persisted (no Set-Content/env-var write of the key material)" {
            $psm1 = Get-Content -Path (Join-Path $script:ModuleRoot 'VSAModule.psm1') -Raw
            $psm1 | Should -Not -Match 'SetEnvironmentVariable\([^)]*\$key'
            $psm1 | Should -Not -Match 'Set-Content[^\n]*\$key'
        }
    }

    Context "load-time selection" {

        It "exposes the two strategy scriptblocks" {
            InModuleScope VSAModule {
                $script:VSAProtectData   | Should -BeOfType ([scriptblock])
                $script:VSAUnprotectData | Should -BeOfType ([scriptblock])
            }
        }
    }

    Context "protect/unprotect round-trip on the current platform" {

        It "Protect-VSAConnectionData / Unprotect-VSAConnectionData round-trip a sample serial blob" {
            InModuleScope VSAModule {
                $serial = @('https://vsa.example.com', 'TOK123', 'PAT456', 'alice', '2030-01-01T00:00:00.0000000Z', 'False', 'True') -join "`t"
                $plainB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($serial))

                $protected = Protect-VSAConnectionData -Data $plainB64
                $protected | Should -Not -BeNullOrEmpty

                $roundTripped = Unprotect-VSAConnectionData -EncryptedData $protected
                $roundTripped | Should -Be $plainB64
            }
        }

        It "Set-VSAPersistentConnection / Get-VSAPersistent* round-trip a full VSAConnection" {
            InModuleScope VSAModule {
                $c = [VSAConnection]::new('https://vsa.example.com', 'alice', 'TOK123', 'PAT456', [datetime]'2030-01-01T00:00:00Z', $true, $true)
                Set-VSAPersistentConnection -Connection $c
                Get-VSAPersistentURI              | Should -Be 'https://vsa.example.com'
                Get-VSAPersistentUserName         | Should -Be 'alice'
                Get-VSAPersistentToken            | Should -Be 'TOK123'
                Get-VSAPersistentPAT              | Should -Be 'PAT456'
                Get-VSAPersistentIgnoreCertErrors | Should -BeTrue
            }
        }
    }

    Context "Windows / DPAPI behavior" -Skip:(-not $script:IsWindowsPlatform) {

        It "the persisted blob decrypts with the platform's no-key ConvertFrom-SecureString (DPAPI)" {
            InModuleScope VSAModule {
                $c = [VSAConnection]::new('https://vsa.example.com', 'alice', 'TOK123', 'PAT456', [datetime]'2030-01-01T00:00:00Z', $false, $true)
                Set-VSAPersistentConnection -Connection $c
                $raw = [Environment]::GetEnvironmentVariable('VSAConnection')
                { ConvertTo-SecureString -String $raw -ErrorAction Stop } | Should -Not -Throw
            }
        }
    }

    Context "Linux/macOS / derived-key AES behavior" -Skip:$script:IsWindowsPlatform {

        It "the derived key is 32 bytes and re-derives identically across calls" {
            InModuleScope VSAModule {
                $k1 = & $script:VSADeriveLocalKey
                $k2 = & $script:VSADeriveLocalKey
                $k1.Length | Should -Be 32
                [System.BitConverter]::ToString($k1) | Should -Be ([System.BitConverter]::ToString($k2))
            }
        }

        It "the persisted blob does NOT decrypt via a plain no-key ConvertTo-SecureString" {
            InModuleScope VSAModule {
                $c = [VSAConnection]::new('https://vsa.example.com', 'alice', 'TOK123', 'PAT456', [datetime]'2030-01-01T00:00:00Z', $false, $true)
                Set-VSAPersistentConnection -Connection $c
                $raw = [Environment]::GetEnvironmentVariable('VSAConnection')
                { ConvertTo-SecureString -String $raw -ErrorAction Stop } | Should -Throw
            }
        }
    }
}
