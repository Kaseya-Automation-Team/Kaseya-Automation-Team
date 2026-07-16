BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
    # Contains a double quote, a backslash, and a newline - exactly what naive string
    # interpolation into a JSON literal corrupts.
    $script:TrickyValue = "line1`nline2 with `"quotes`" and a \backslash"
}

Describe "Hand-rolled JSON replaced with ConvertTo-Json (T-6.8 / F-40, F-43)" {

    It "New-VSANotification produces valid, round-tripping JSON" {
        InModuleScope VSAModule -Parameters @{ TrickyValue = $script:TrickyValue } {
            param($TrickyValue)
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSANotification -Title $TrickyValue -Text $TrickyValue | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.Title | Should -Be $TrickyValue
            $obj.Body | Should -Be $TrickyValue
        }
    }

    It "New-VSAAgentInstallLink produces valid, round-tripping JSON" {
        InModuleScope VSAModule -Parameters @{ TrickyValue = $script:TrickyValue } {
            param($TrickyValue)
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSAAgentInstallLink -PartitionId 1 -MachineGroupName $TrickyValue | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.MachineGroupName | Should -Be $TrickyValue
        }
    }

    It "Rename-VSAMachineGroup produces valid, round-tripping JSON" {
        InModuleScope VSAModule -Parameters @{ TrickyValue = $script:TrickyValue } {
            param($TrickyValue)
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Rename-VSAMachineGroup -MachineGroupId 100 -MachineGroupName $TrickyValue -Confirm:$false | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.MachineGroupName | Should -Be $TrickyValue
        }
    }

    It "Update-VSAAgentProfile produces valid, round-tripping JSON" {
        InModuleScope VSAModule -Parameters @{ TrickyValue = $script:TrickyValue } {
            param($TrickyValue)
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Update-VSAAgentProfile -AgentId 100 -AdminEmail $TrickyValue -UserName $TrickyValue -UserEmail $TrickyValue -UserPhone $TrickyValue -Notes $TrickyValue -ShowToolTip 1 | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.Notes | Should -Be $TrickyValue
        }
    }

    It "Update-VSAWarrantyExpiration produces valid, round-tripping JSON" {
        InModuleScope VSAModule -Parameters @{ TrickyValue = $script:TrickyValue } {
            param($TrickyValue)
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Update-VSAWarrantyExpiration -AgentID 100 -PurchaseDate $TrickyValue -WarrantyExpireDate $TrickyValue | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.PurchaseDate | Should -Be $TrickyValue
        }
    }

    It "New-VSAAgentNote produces valid, round-tripping JSON with exactly one transport call (T-6.10)" {
        InModuleScope VSAModule -Parameters @{ TrickyValue = $script:TrickyValue } {
            param($TrickyValue)
            $script:body = $null
            $script:calls = 0
            Mock Invoke-VSARestMethod { $script:calls++; $script:body = $Body }
            New-VSAAgentNote -AgentId 100 -Note $TrickyValue | Out-Null
            $script:calls | Should -Be 1
            ($script:body | ConvertFrom-Json) | Should -Be $TrickyValue
        }
    }

    It "Update-VSAAgentNote produces valid, round-tripping JSON with exactly one transport call (T-6.10)" {
        InModuleScope VSAModule -Parameters @{ TrickyValue = $script:TrickyValue } {
            param($TrickyValue)
            $script:body = $null
            $script:calls = 0
            Mock Invoke-VSARestMethod { $script:calls++; $script:body = $Body }
            Update-VSAAgentNote -NoteId 5 -Note $TrickyValue | Out-Null
            $script:calls | Should -Be 1
            $obj = $script:body | ConvertFrom-Json
            $obj.'5' | Should -Be $TrickyValue
        }
    }

    It "Update-VSAAgentTempDir produces valid JSON for a path with regex-special characters" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            $trickyPath = 'C:\Program Files (x86)\Temp+Dir[1]'
            Update-VSAAgentTempDir -AgentId 100 -TempDir $trickyPath | Out-Null
            $arr = $script:body | ConvertFrom-Json
            $arr[0].value | Should -Be $trickyPath
        }
    }

    It "Get-VSACustomExtensionFSItem makes exactly one transport call (T-6.10)" {
        InModuleScope VSAModule {
            $script:calls = 0
            Mock Invoke-VSARestMethod { $script:calls++ }
            Get-VSACustomExtensionFSItem -AgentId 100 | Out-Null
            $script:calls | Should -Be 1
        }
    }

    It "Remove-VSACustomExtensionFolder makes exactly one transport call (T-6.10)" {
        InModuleScope VSAModule {
            $script:calls = 0
            Mock Invoke-VSARestMethod { $script:calls++ }
            Remove-VSACustomExtensionFolder -AgentId 100 -Folder 'SomeFolder' | Out-Null
            $script:calls | Should -Be 1
        }
    }

    It "New-VSACustomField produces valid JSON with exactly one transport call (T-6.10)" {
        InModuleScope VSAModule -Parameters @{ TrickyValue = $script:TrickyValue } {
            param($TrickyValue)
            $script:body = $null
            $script:calls = 0
            Mock Invoke-VSARestMethod { $script:calls++; $script:body = $Body }
            New-VSACustomField -FieldName $TrickyValue -Confirm:$false | Out-Null
            $script:calls | Should -Be 1
            $arr = $script:body | ConvertFrom-Json
            ($arr | Where-Object key -eq 'FieldName').value | Should -Be $TrickyValue
        }
    }
}
