. (Join-Path $PSScriptRoot 'VSAFakeHttp.ps1')

BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "Non-enveloped (raw) API payloads are returned, not treated as errors (F-63)" {

    # Cloud Backup endpoints (kcb/servers, kcb/workstations, kcb/virtualmachines) return a bare
    # JSON object -- a flat { <agentId>: <statusString> } map -- with NONE of the standard envelope
    # fields (Result/ResponseCode/Status/Error). Before F-63 the parser threw "Unexpected API
    # response" on these, so the four Get-VSACB* cmdlets could never return data.

    It "Get-RequestData returns a flat non-enveloped object as-is" {
        InModuleScope VSAModule {
            # Exercises the real transport against a fake handler serving the exact JSON Cloud Backup
            # returns, so the raw-payload rule is proven end-to-end from bytes on the wire (F-67).
            $h = [FakeHttpMessageHandler]::new()
            $h.EnqueueResponse(200, '{"183024726869488":"KCB_BackupStatus_NotScheduled","757824222824211":"KCB_BackupStatus_Ok"}', 0)
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan
            try {
                $r = Get-RequestData -URI 'https://vsa.example.com/api/v1.0/kcb/servers' -AuthString 'Bearer t' -Method GET
                $r | Should -Not -BeNullOrEmpty
                $r.'183024726869488' | Should -Be 'KCB_BackupStatus_NotScheduled'
                $r.'757824222824211' | Should -Be 'KCB_BackupStatus_Ok'
            } finally {
                $script:VSAHttpClients.Clear()
            }
        }
    }

    It "Invoke-VSARestMethod returns the raw payload as-is (no .Result unwrap, no paging)" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Get-RequestData {
                [pscustomobject]@{ '183024726869488' = 'KCB_BackupStatus_NotScheduled'; '757824222824211' = 'KCB_BackupStatus_Ok' }
            }
            $conn = [VSAConnection]::new(); $conn.URI = 'https://h'; $conn.Token = 't'
            $r = Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/kcb/servers' -Method GET
            @($r.PSObject.Properties).Count | Should -Be 2
            $r.'757824222824211' | Should -Be 'KCB_BackupStatus_Ok'
        }
    }

    It "a status-only envelope (ResponseCode/Status but no Result) still yields an empty result (F-23 unchanged)" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Get-RequestData { [pscustomobject]@{ ResponseCode = 0; Status = 'OK' } }   # no Result property
            $conn = [VSAConnection]::new(); $conn.URI = 'https://h'; $conn.Token = 't'
            $r = Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x' -Method PUT
            # A status-only envelope has no data; the transport yields an empty result (null), NOT the
            # envelope object itself -- this is the F-23 behaviour my raw-payload change must preserve.
            $r | Should -BeNullOrEmpty
        }
    }

    It "a normal enveloped response still unwraps .Result (regression guard)" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Get-RequestData { [pscustomobject]@{ ResponseCode = 0; Status = 'OK'; Result = @(1, 2, 3) } }
            $conn = [VSAConnection]::new(); $conn.URI = 'https://h'; $conn.Token = 't'
            $r = Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x' -Method GET
            @($r).Count | Should -Be 3
            $r[0] | Should -Be 1
        }
    }
}
