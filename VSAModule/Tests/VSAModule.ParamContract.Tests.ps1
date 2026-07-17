BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "Parameter mandatoriness matches the server contract" {

    It "New-VSALCAuditLog -Message is mandatory (server 400s without it; help says 'Required') (F-65)" {
        InModuleScope VSAModule {
            $p = (Get-Command New-VSALCAuditLog).Parameters['Message']
            $mandatory = ($p.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory
            $mandatory | Should -Contain $true
        }
    }

    It "New-VSALCAuditLog sends the LogMessage when -Message is supplied" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSALCAuditLog -AgentId 100 -Message 'hello' | Out-Null
            ($script:body | ConvertFrom-Json).LogMessage | Should -Be 'hello'
        }
    }

    It "Send-VSAEmail -UniqueTag is optional (body already omits it when absent) (F-66)" {
        InModuleScope VSAModule {
            $p = (Get-Command Send-VSAEmail).Parameters['UniqueTag']
            $mandatory = ($p.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory
            $mandatory | Should -Not -Contain $true
        }
    }

    It "Send-VSAEmail succeeds without -UniqueTag and auto-generates one (F-80, corrects F-66)" {
        InModuleScope VSAModule {
            # F-66 made -UniqueTag optional and omitted it from the body when absent. Live testing
            # proved that wrong: the server rejects a missing tag with HTTP 400 "UniqueTag can't be
            # null". The module now always sends one -- the caller's value, or a generated default --
            # so the optional-parameter call actually works (F-80).
            $script:body = $null
            Mock Invoke-VSAWriteRequest { $script:body = $Body }
            Send-VSAEmail -FromAddress 'a@b.com' -ToAddress 'c@d.com' -Subject 'Sub' -Body 'Body' | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.FromAddress | Should -Be 'a@b.com'
            $obj.UniqueTag   | Should -Not -BeNullOrEmpty -Because 'the server requires a UniqueTag; the module fills one in'
        }
    }

    It "Set-VSATenantModuleUsageType parameter sets are consistent: ById={TenantId,ModuleId}, ByName={TenantName,ModuleName} (F-67)" {
        # The Id/Name params were cross-wired (TenantId in ById but ModuleId in ByName, etc.), so the
        # natural '-TenantId -ModuleId' and '-TenantName -ModuleName' calls could not be satisfied.
        InModuleScope VSAModule {
            $cmd = Get-Command Set-VSATenantModuleUsageType
            function SetOf($param) { ($cmd.Parameters[$param].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -ne '__AllParameterSets' }).ParameterSetName }
            SetOf 'TenantId'   | Should -Be 'ById'
            SetOf 'ModuleId'   | Should -Be 'ById'
            SetOf 'TenantName' | Should -Be 'ByName'
            SetOf 'ModuleName' | Should -Be 'ByName'
        }
    }

    It "Send-VSAEmail includes UniqueTag in the body when supplied" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Send-VSAEmail -FromAddress 'a@b.com' -ToAddress 'c@d.com' -Subject 'Sub' -Body 'Body' -UniqueTag 'tag1' | Out-Null
            ($script:body | ConvertFrom-Json).UniqueTag | Should -Be 'tag1'
        }
    }

    It "New-VSASDTicketNote -Hidden and -SystemFlag are optional switches (F-68)" {
        InModuleScope VSAModule {
            foreach ($name in 'Hidden', 'SystemFlag') {
                $p = (Get-Command New-VSASDTicketNote).Parameters[$name]
                $p.ParameterType | Should -Be ([switch])
                $mandatory = ($p.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory
                $mandatory | Should -Not -Contain $true
            }
        }
    }

    It "New-VSASDTicketNote sends Hidden/SystemFlag = false when the switches are omitted" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSASDTicketNote -ServiceDeskTicketId 100 -Text 'note text' | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.Text | Should -Be 'note text'
            $obj.Hidden | Should -Be $false
            $obj.SystemFlag | Should -Be $false
        }
    }
}

Describe "Multipart upload cmdlets honor -WhatIf/-Confirm (F-69)" {

    BeforeAll {
        $script:TmpFile = New-TemporaryFile
        Set-Content -Path $script:TmpFile -Value 'whatif upload test'
    }
    AfterAll { Remove-Item $script:TmpFile -Force -ErrorAction SilentlyContinue }

    It "Publish-VSADocument and Publish-VSACustomExtensionFile expose -WhatIf/-Confirm" {
        foreach ($n in 'Publish-VSADocument', 'Publish-VSACustomExtensionFile') {
            (Get-Command $n).Parameters.Keys | Should -Contain 'WhatIf'
            (Get-Command $n).Parameters.Keys | Should -Contain 'Confirm'
        }
    }

    It "Publish-VSADocument -WhatIf does not upload" {
        InModuleScope VSAModule -Parameters @{ TmpFile = $script:TmpFile } {
            param($TmpFile)
            $script:calls = 0
            Mock Invoke-VSARestMethod { $script:calls++ }
            Publish-VSADocument -AgentId 100 -SourceFilePath $TmpFile.FullName -WhatIf | Out-Null
            $script:calls | Should -Be 0
        }
    }

    It "Publish-VSACustomExtensionFile -WhatIf does not upload" {
        InModuleScope VSAModule -Parameters @{ TmpFile = $script:TmpFile } {
            param($TmpFile)
            $script:calls = 0
            Mock Invoke-VSARestMethod { $script:calls++ }
            Publish-VSACustomExtensionFile -AgentId 100 -SourceFilePath $TmpFile.FullName -WhatIf | Out-Null
            $script:calls | Should -Be 0
        }
    }

    It "Publish-VSADocument uploads (one transport call) without -WhatIf" {
        InModuleScope VSAModule -Parameters @{ TmpFile = $script:TmpFile } {
            param($TmpFile)
            $script:calls = 0
            Mock Invoke-VSARestMethod { $script:calls++ }
            Publish-VSADocument -AgentId 100 -SourceFilePath $TmpFile.FullName | Out-Null
            $script:calls | Should -Be 1
        }
    }
}
