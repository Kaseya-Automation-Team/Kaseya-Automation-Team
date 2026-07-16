BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "v1.4.0 write functions" {

    $script:WriteFns = @(
        'New-VSATemporaryAgent', 'Set-VSATemporaryAgentName', 'New-VSATemporaryAgentNote', 'Send-VSATemporaryAgentEmail',
        'New-VSARCService', 'Set-VSARCService', 'Remove-VSARCService', 'Set-VSAAssetProxy', 'Set-VSAAssetService',
        'Suspend-VSAAgent', 'Start-VSAAgentUpgrade', 'Convert-VSAAssetToDevice', 'Convert-VSADeviceToAsset', 'Publish-VSADevice',
        'Set-VSAAgentAlert', 'Set-VSASystemAlert', 'Start-VSAAPReturnId', 'Stop-VSAPatchSchedule',
        'New-VSASDTicket', 'Set-VSAUserPassword', 'Reset-VSAUserPassword', 'Close-VSAUserSession'
    ) | ForEach-Object { @{ Name = $_ } }

    It "<Name> is exported and supports -WhatIf/-Confirm" -ForEach $script:WriteFns {
        $cmd = Get-Command $Name -Module VSAModule -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
        $cmd.Parameters.Keys | Should -Contain 'WhatIf'
    }

    Context "Requests route through the shared write path with the right verb and URL" {
        It "New-VSARCService POSTs the rcservice endpoint with the body" {
            InModuleScope VSAModule {
                $script:seen = $null
                Mock Invoke-VSARestMethod { $script:seen = @{ Method = $Method; URISuffix = $URISuffix; Body = $Body } }
                New-VSARCService -ServiceName 'rdp' -Port 3389 -ClientApp 'tunnelonly' | Out-Null
                $script:seen.Method | Should -Be 'POST'
                $script:seen.URISuffix | Should -Be 'api/v1.0/assetmgmt/assets/rcservice'
                ($script:seen.Body | ConvertFrom-Json).ServiceName | Should -Be 'rdp'
            }
        }

        It "Set-VSARCService PUTs with the serviceid/force query string" {
            InModuleScope VSAModule {
                $script:seen = $null
                Mock Invoke-VSARestMethod { $script:seen = @{ Method = $Method; URISuffix = $URISuffix } }
                Set-VSARCService -ServiceId 'abc' -ServiceName 'rdp' -Port 3389 -ClientApp 'tunnelonly' -Force | Out-Null
                $script:seen.Method | Should -Be 'PUT'
                $script:seen.URISuffix | Should -Match 'updatercservice\?serviceid=abc&force=true'
            }
        }

        It "Remove-VSARCService DELETEs with the serviceId/force query string" {
            InModuleScope VSAModule {
                $script:seen = $null
                Mock Invoke-VSARestMethod { $script:seen = @{ Method = $Method; URISuffix = $URISuffix } }
                Remove-VSARCService -ServiceId 'abc' | Out-Null
                $script:seen.Method | Should -Be 'DELETE'
                $script:seen.URISuffix | Should -Match 'deletercservice\?serviceId=abc&force=false'
            }
        }

        It "Suspend-VSAAgent sends AgentGuids and preserves SuspendAgent = \$false" {
            InModuleScope VSAModule {
                $script:seen = $null
                Mock Invoke-VSARestMethod { $script:seen = $Body }
                Suspend-VSAAgent -AgentGuids 100, 200 -SuspendAgent $false | Out-Null
                $obj = $script:seen | ConvertFrom-Json
                $obj.AgentGuids | Should -Be @(100, 200)
                $obj.SuspendAgent | Should -Be $false
            }
        }

        It "New-VSASDTicket resolves a Priority NAME to its Id in the body" {
            InModuleScope VSAModule {
                $script:seen = $null
                Mock Invoke-VSARestMethod { $script:seen = $Body }
                Mock Get-VSASDPriority { [pscustomobject]@{ PriorityName = 'High'; PriorityId = '999' } }
                New-VSASDTicket -ServiceDeskId 100 -Summary 's' -Priority 'High' | Out-Null
                ($script:seen | ConvertFrom-Json).Priority | Should -Be '999'
            }
        }

        It "New-VSATemporaryAgent POSTs the temporaryagent endpoint with no body" {
            InModuleScope VSAModule {
                $script:seen = $null
                Mock Invoke-VSARestMethod { $script:seen = @{ Method = $Method; URISuffix = $URISuffix; HasBody = $PSBoundParameters.ContainsKey('Body') } }
                New-VSATemporaryAgent | Out-Null
                $script:seen.Method | Should -Be 'POST'
                $script:seen.URISuffix | Should -Be 'api/v1.0/temporaryagent'
                $script:seen.HasBody | Should -BeFalse
            }
        }
    }

    Context "Parameter contracts match the server" {
        It "New-VSARCService -ClientApp only accepts the API's allowed values" {
            $vs = (Get-Command New-VSARCService).Parameters['ClientApp'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $vs.ValidValues | Should -Be @('http', 'https', 'ssh', 'telnet', 'tunnelonly')
        }

        It "New-VSASDTicket -Priority is mandatory (server rejects a ticket without it)" {
            $p = (Get-Command New-VSASDTicket).Parameters['Priority']
            ($p.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory |
                Should -Contain $true
        }

        It "Get-VSAAlertTracking and Get-VSAOrgNetwork are reads (no ShouldProcess)" {
            (Get-Command Get-VSAAlertTracking).Parameters.Keys | Should -Not -Contain 'WhatIf'
            (Get-Command Get-VSAOrgNetwork).Parameters.Keys   | Should -Not -Contain 'WhatIf'
        }
    }
}
