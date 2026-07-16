BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "ConvertTo-VSARequestBody assembles bodies from bound parameters" {

    It "includes only bound parameters" {
        InModuleScope VSAModule {
            $bound = @{ OrgName = 'Acme'; OrgRef = 'acme' }   # Website not bound
            $ht = ConvertTo-VSARequestBody -BoundParameters $bound -Include @('OrgName','OrgRef','Website')
            $ht.Keys | Should -Contain 'OrgName'
            $ht.Keys | Should -Contain 'OrgRef'
            $ht.Keys | Should -Not -Contain 'Website'
        }
    }

    It "includes an explicitly-bound 0 / \$false (ContainsKey, not truthiness)" {
        InModuleScope VSAModule {
            $bound = @{ NoOfEmployees = 0; TimeSheetFlag = $false }
            $ht = ConvertTo-VSARequestBody -BoundParameters $bound -Include @('NoOfEmployees','TimeSheetFlag')
            $ht['NoOfEmployees'] | Should -Be 0
            $ht['TimeSheetFlag'] | Should -Be $false
            $ht.Keys | Should -Contain 'NoOfEmployees'
            $ht.Keys | Should -Contain 'TimeSheetFlag'
        }
    }

    It "renames parameters to body fields via -NameMap" {
        InModuleScope VSAModule {
            $bound = @{ OrganizationName = 'Acme'; OrgIdNumber = 0 }
            $ht = ConvertTo-VSARequestBody -BoundParameters $bound -Include @('OrganizationName','OrgIdNumber') `
                -NameMap @{ OrganizationName = 'OrgName'; OrgIdNumber = 'OrgId' }
            $ht.Keys | Should -Contain 'OrgName'
            $ht.Keys | Should -Contain 'OrgId'
            $ht['OrgId'] | Should -Be 0
            $ht.Keys | Should -Not -Contain 'OrganizationName'
        }
    }
}

Describe "Invoke-VSAWriteRequest is the shared write dispatch tail" {

    It "serializes a hashtable body and forwards it to the transport" {
        InModuleScope VSAModule {
            $script:body = $null; $script:method = $null; $script:suffix = $null
            Mock Invoke-VSARestMethod { $script:body = $Body; $script:method = $Method; $script:suffix = $URISuffix }
            Invoke-VSAWriteRequest -Body @{ Name = 'X' } -Method POST -URISuffix 'api/v1.0/things' | Out-Null
            $script:method | Should -Be 'POST'
            $script:suffix | Should -Be 'api/v1.0/things'
            ($script:body | ConvertFrom-Json).Name | Should -Be 'X'
        }
    }

    It "prunes \$null and empty-string but KEEPS an explicit 0 / \$false (F-52)" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Invoke-VSAWriteRequest -Method PUT -URISuffix 'api/v1.0/x' -Body @{
                Keep0 = 0; KeepFalse = $false; DropNull = $null; DropEmpty = ''
            } | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.PSObject.Properties.Name | Should -Contain 'Keep0'
            $obj.PSObject.Properties.Name | Should -Contain 'KeepFalse'
            $obj.Keep0 | Should -Be 0
            $obj.KeepFalse | Should -Be $false
            $obj.PSObject.Properties.Name | Should -Not -Contain 'DropNull'
            $obj.PSObject.Properties.Name | Should -Not -Contain 'DropEmpty'
        }
    }

    It "-KeepEmpty transmits null/empty fields unpruned" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Invoke-VSAWriteRequest -Method PUT -URISuffix 'api/v1.0/x' -KeepEmpty -Body @{ Empty = '' } | Out-Null
            ($script:body | ConvertFrom-Json).PSObject.Properties.Name | Should -Contain 'Empty'
        }
    }

    It "serializes nested bodies deep enough (default depth 10, not the old truncating 2)" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Invoke-VSAWriteRequest -Method POST -URISuffix 'api/v1.0/x' -Body @{
                L1 = @{ L2 = @{ L3 = @{ L4 = 'deep' } } }
            } | Out-Null
            ($script:body | ConvertFrom-Json).L1.L2.L3.L4 | Should -Be 'deep'
        }
    }

    It "passes a pre-serialized string body through unchanged" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            $json = '[{"key":"a","value":"b"}]'
            Invoke-VSAWriteRequest -Method PUT -URISuffix 'api/v1.0/x' -Body $json | Out-Null
            $script:body | Should -Be $json
        }
    }

    It "sends no body when -Body is omitted (templated-URI write)" {
        InModuleScope VSAModule {
            $script:body = 'SENTINEL'
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Invoke-VSAWriteRequest -Method PUT -URISuffix 'api/v1.0/agents/1/rename/foo' | Out-Null
            [string]::IsNullOrEmpty($script:body) | Should -Be $true
        }
    }

    It "forwards -VSAConnection only when non-null (F-31)" {
        # Assert on the received parameter VALUE, not $PSBoundParameters.ContainsKey -- the latter
        # is unreliable for splatted params inside a Pester mock.
        InModuleScope VSAModule {
            $script:conn = 'SENTINEL'
            Mock Invoke-VSARestMethod { $script:conn = $VSAConnection }

            Invoke-VSAWriteRequest -Method POST -URISuffix 'api/v1.0/x' -Body @{ a = 1 } -VSAConnection $null | Out-Null
            $script:conn | Should -Be $null

            $conn = [VSAConnection]::new(); $conn.URI = 'https://x'
            Invoke-VSAWriteRequest -Method POST -URISuffix 'api/v1.0/x' -Body @{ a = 1 } -VSAConnection $conn | Out-Null
            $script:conn | Should -Not -Be $null
            $script:conn.URI | Should -Be 'https://x'
        }
    }

    It "with -ExtendedOutput forwards the switch and expands .Result" {
        InModuleScope VSAModule {
            $script:extended = $null
            Mock Invoke-VSARestMethod {
                $script:extended = [bool]$ExtendedOutput
                [pscustomobject]@{ Result = 12345; ResponseCode = 0 }   # full envelope
            }
            $r = Invoke-VSAWriteRequest -Method POST -URISuffix 'api/v1.0/x' -Body @{ a = 1 } -ExtendedOutput
            $script:extended | Should -Be $true
            $r | Should -Be 12345
        }
    }

    It "without -ExtendedOutput does not expand (returns transport result as-is)" {
        InModuleScope VSAModule {
            Mock Invoke-VSARestMethod { $true }
            $r = Invoke-VSAWriteRequest -Method POST -URISuffix 'api/v1.0/x' -Body @{ a = 1 }
            $r | Should -Be $true
        }
    }
}

Describe "Uniform ShouldProcess: -WhatIf gates the transport across converted write cmdlets" {

    It "-WhatIf blocks the request (no transport call)" {
        InModuleScope VSAModule {
            $script:calls = 0
            Mock Invoke-VSARestMethod { $script:calls++ }
            New-VSANotification -Title 'T' -Text 'B' -WhatIf | Out-Null
            $script:calls | Should -Be 0
        }
    }

    It "without -WhatIf the request goes through" {
        InModuleScope VSAModule {
            $script:calls = 0
            Mock Invoke-VSARestMethod { $script:calls++ }
            New-VSANotification -Title 'T' -Text 'B' | Out-Null
            $script:calls | Should -Be 1
        }
    }

    It "-WhatIf also gates a no-body templated write (Disable-VSAUser)" {
        InModuleScope VSAModule {
            $script:calls = 0
            Mock Invoke-VSARestMethod { $script:calls++ }
            Disable-VSAUser -UserId 100 -WhatIf | Out-Null
            $script:calls | Should -Be 0
        }
    }
}
