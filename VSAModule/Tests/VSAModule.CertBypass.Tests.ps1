# Certificate-error bypass is edition-sensitive and was the source of a PS 5.1 regression (F-27b):
# a PowerShell scriptblock assigned to ServerCertificateValidationCallback cannot run on the TLS
# handshake thread, aborting the send ("An unexpected error occurred on a send"). The fix selects a
# compiled strategy once at module load, feature-detected on -SkipCertificateCheck.

# Computed during Discovery so the -Skip conditions below resolve to the running edition's path.
$script:SupportsSkip = (Get-Command Invoke-RestMethod).Parameters.ContainsKey('SkipCertificateCheck')

BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "Certificate-bypass strategy is compiled, feature-detected, and edition-correct (F-27b)" {

    Context "source guarantees (platform-independent)" {

        It "no transport file assigns a PowerShell scriptblock to ServerCertificateValidationCallback" {
            foreach ($file in @('private/Get-RequestData.ps1', 'private/Invoke-VSAHttp.ps1', 'private/Invoke-VSAParallelRequest.ps1')) {
                $src = Get-Content -Path (Join-Path $script:ModuleRoot $file) -Raw
                $src | Should -Not -Match 'ServerCertificateValidationCallback\s*=\s*\{' -Because "$file must not hand a scriptblock to the TLS handshake thread (F-27b)"
            }
        }

        It "the Core path carries the bypass on the HttpClientHandler, not a request switch (F-67)" {
            $src = Get-Content -Path (Join-Path $script:ModuleRoot 'private/Invoke-VSAHttp.ps1') -Raw
            $src | Should -Match 'ServerCertificateCustomValidationCallback'
            $src | Should -Match 'DangerousAcceptAnyServerCertificateValidator'
        }

        It "the Framework path uses a compiled ICertificatePolicy type, not a scriptblock" {
            $psm1 = Get-Content -Path (Join-Path $script:ModuleRoot 'VSAModule.psm1') -Raw
            $psm1 | Should -Match 'class VSATrustAllCertificatePolicy\s*:\s*ICertificatePolicy'
        }

        It "the strategy is feature-detected on -SkipCertificateCheck, not an edition/version label" {
            $psm1 = Get-Content -Path (Join-Path $script:ModuleRoot 'VSAModule.psm1') -Raw
            $psm1 | Should -Match "Parameters\.ContainsKey\('SkipCertificateCheck'\)"
        }
    }

    Context "load-time selection" {

        It "exposes the two push/pop strategy scriptblocks" {
            InModuleScope VSAModule {
                $script:VSAPushCertBypass | Should -BeOfType ([scriptblock])
                $script:VSAPopCertBypass  | Should -BeOfType ([scriptblock])
            }
        }

        It "no longer carries the retired request-splat strategy (F-67)" {
            # VSAAddSkipCertCheck existed only to add -SkipCertificateCheck to an Invoke-RestMethod
            # splat. The module transports over HttpClient now, so it is dead and was removed.
            InModuleScope VSAModule {
                Get-Variable -Name 'VSAAddSkipCertCheck' -Scope Script -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
        }
    }

    Context "PowerShell 7 / .NET Core runtime (handler validator)" -Skip:(-not $script:SupportsSkip) {

        It "push/pop are no-ops: Core ignores the process-global policy, so nothing is touched" {
            InModuleScope VSAModule {
                $before = [System.Net.ServicePointManager]::CertificatePolicy
                & $script:VSAPushCertBypass
                [System.Net.ServicePointManager]::CertificatePolicy | Should -Be $before
                & $script:VSAPopCertBypass
                [System.Net.ServicePointManager]::CertificatePolicy | Should -Be $before
            }
        }

        It "does not compile the Framework-only trust-all policy type" {
            ('VSATrustAllCertificatePolicy' -as [type]) | Should -BeNullOrEmpty
        }
    }

    Context "Windows PowerShell 5.1 / .NET Framework runtime (compiled policy)" -Skip:$script:SupportsSkip {

        It "push installs the compiled trust-all policy and pop restores the previous one" {
            InModuleScope VSAModule {
                ('VSATrustAllCertificatePolicy' -as [type]) | Should -Not -BeNullOrEmpty
                $before = [System.Net.ServicePointManager]::CertificatePolicy
                & $script:VSAPushCertBypass
                [System.Net.ServicePointManager]::CertificatePolicy | Should -BeOfType ([VSATrustAllCertificatePolicy])
                & $script:VSAPopCertBypass
                [System.Net.ServicePointManager]::CertificatePolicy | Should -Be $before
            }
        }
    }
}
