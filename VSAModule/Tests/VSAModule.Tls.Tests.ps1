Describe "TLS 1.2 pin on Windows PowerShell / .NET Framework only (T-5.3 / F-27)" {

    It "pins strong protocols outright (TLS 1.2 floor + TLS 1.3 when available), never OR-in against the host's value" {
        $content = Get-Content -Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'VSAModule.psm1') -Raw
        # TLS 1.2 is always the floor of the pinned set.
        $content | Should -Match '\$strongProtocols\s*=\s*\[Net\.SecurityProtocolType\]::Tls12'
        # TLS 1.3 is added only when the enum defines it (4.8+), probed without an exception.
        $content | Should -Match "\[enum\]::IsDefined\(\[Net\.SecurityProtocolType\],\s*'Tls13'\)"
        # The pinned set is assigned OUTRIGHT to the computed value...
        $content | Should -Match '\[Net\.ServicePointManager\]::SecurityProtocol\s*=\s*\$strongProtocols'
        # ...and the OR-in-against-the-host form (which preserved SSL3/TLS1.0) must be gone.
        $content | Should -Not -Match '::SecurityProtocol\s*=\s*\[Net\.ServicePointManager\]::SecurityProtocol\s*-bor'
    }

    It "on .NET Framework, the pinned SecurityProtocol includes TLS 1.2 and excludes SSL3/TLS1.0/TLS1.1" {
        if ((Get-Command Invoke-RestMethod).Parameters.ContainsKey('SkipCertificateCheck')) {
            Set-ItResult -Skipped -Because 'Framework-only: PowerShell 7 / Core leaves SecurityProtocol to the OS'
            return
        }
        Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'VSAModule.psd1') -Force
        $sp = [Net.ServicePointManager]::SecurityProtocol
        ($sp -band [Net.SecurityProtocolType]::Tls12) | Should -Not -Be 0
        ($sp -band [Net.SecurityProtocolType]::Ssl3)  | Should -Be 0
        ($sp -band [Net.SecurityProtocolType]::Tls)   | Should -Be 0   # TLS 1.0
        ($sp -band [Net.SecurityProtocolType]::Tls11) | Should -Be 0
    }

    It "importing the module on PowerShell 7 (Core) does not change SecurityProtocol" {
        if ($PSVersionTable.PSEdition -ne 'Core') {
            Set-ItResult -Skipped -Because 'this check only applies when running on PowerShell 7 (Core)'
            return
        }
        $before = [Net.ServicePointManager]::SecurityProtocol
        Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'VSAModule.psd1') -Force
        $after = [Net.ServicePointManager]::SecurityProtocol
        $after | Should -Be $before
    }
}
