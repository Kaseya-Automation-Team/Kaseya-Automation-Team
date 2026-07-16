$ModuleRoot = Split-Path -Path (Split-Path -Parent $PSScriptRoot)
$ModulePath = Join-Path -Path $ModuleRoot -ChildPath 'VSAModule.psd1'

BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
    $script:Cred = New-Object System.Management.Automation.PSCredential('alice', (ConvertTo-SecureString 'PAT456' -AsPlainText -Force))
}

AfterAll {
    [Environment]::SetEnvironmentVariable('VSAConnection', $null)
}

Describe "New-VSAConnection - URL scheme validation (T-5.4)" {

    It "rejects an http:// server at parameter validation" {
        { New-VSAConnection -VSAServer 'http://vsa.example.com' -Credential $script:Cred -ErrorAction Stop } | Should -Throw
    }

    It "accepts an https:// server (fails later at auth, not at validation)" {
        InModuleScope VSAModule {
            $cred = New-Object System.Management.Automation.PSCredential('alice', (ConvertTo-SecureString 'PAT456' -AsPlainText -Force))
            Mock Get-RequestData { throw 'network down' }
            # Should reach the auth call (and throw the auth error), not the validation error.
            { New-VSAConnection -VSAServer 'https://vsa.example.com' -Credential $cred -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Authentication failed*'
        }
    }
}

Describe "New-VSAConnection - auth failure is terminating with context (T-5.4)" {

    It "throws a terminating error naming the server and user on a bad PAT" {
        InModuleScope VSAModule {
            $cred = New-Object System.Management.Automation.PSCredential('alice', (ConvertTo-SecureString 'WRONGPAT' -AsPlainText -Force))
            Mock Get-RequestData { throw 'HTTP 401 Unauthorized' }
            $err = $null
            try { New-VSAConnection -VSAServer 'https://vsa.example.com' -Credential $cred -ErrorAction Stop }
            catch { $err = $_ }
            $err | Should -Not -BeNullOrEmpty
            $err.Exception.Message | Should -Match 'vsa\.example\.com'
            $err.Exception.Message | Should -Match 'alice'
        }
    }
}

Describe "ConvertTo-VSALocalExpiration - shared parser (T-5.4 / F-24)" {

    It "produces identical results regardless of the calling path" {
        InModuleScope VSAModule {
            $a = ConvertTo-VSALocalExpiration -SessionExpiration '2030-06-17T07:14:20Z' -OffSetInMinutes 30
            $b = ConvertTo-VSALocalExpiration -SessionExpiration '2030-06-17T07:14:20Z' -OffSetInMinutes 30
            $a | Should -Be $b
        }
    }

    It "applies the offset in minutes" {
        InModuleScope VSAModule {
            $base   = ConvertTo-VSALocalExpiration -SessionExpiration '2030-06-17T07:14:20Z' -OffSetInMinutes 0
            $offset = ConvertTo-VSALocalExpiration -SessionExpiration '2030-06-17T07:14:20Z' -OffSetInMinutes 30
            ($offset - $base).TotalMinutes | Should -Be 30
        }
    }
}

Describe "Persistent connection storage - platform-detected encryption (T-5.1 / F-60)" {

    AfterEach {
        [Environment]::SetEnvironmentVariable('VSAConnection', $null)
    }

    It "stores a blob that does not leak credentials via plain Base64 decode" {
        InModuleScope VSAModule {
            $c = [VSAConnection]::new('https://vsa.example.com', 'alice', 'TOK123', 'PAT456', [datetime]'2030-01-01T00:00:00Z', $false, $true)
            Set-VSAPersistentConnection -Connection $c
            $raw = [Environment]::GetEnvironmentVariable('VSAConnection')
            $leaked = $false
            try {
                $txt = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($raw))
                if ($txt -match 'TOK123|PAT456') { $leaked = $true }
            } catch { $leaked = $false }
            $leaked | Should -BeFalse
        }
    }

    It "round-trips all connection fields" {
        InModuleScope VSAModule {
            $c = [VSAConnection]::new('https://vsa.example.com', 'alice', 'TOK123', 'PAT456', [datetime]'2030-01-01T00:00:00Z', $true, $true)
            Set-VSAPersistentConnection -Connection $c
            Get-VSAPersistentURI      | Should -Be 'https://vsa.example.com'
            Get-VSAPersistentUserName | Should -Be 'alice'
            Get-VSAPersistentToken    | Should -Be 'TOK123'
            Get-VSAPersistentPAT      | Should -Be 'PAT456'
            Get-VSAPersistentIgnoreCertErrors | Should -BeTrue
        }
    }

    It "updates a single field in place" {
        InModuleScope VSAModule {
            $c = [VSAConnection]::new('https://vsa.example.com', 'alice', 'TOK123', 'PAT456', [datetime]'2030-01-01T00:00:00Z', $false, $true)
            Set-VSAPersistentConnection -Connection $c
            Update-VSAPersistentField -Index 1 -Value 'RENEWED'
            Get-VSAPersistentToken | Should -Be 'RENEWED'
            Get-VSAPersistentPAT   | Should -Be 'PAT456'
        }
    }
}
