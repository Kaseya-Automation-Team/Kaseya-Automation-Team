BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "Parallel paging threshold (Invoke-VSARestMethod)" {

    # A page-1 envelope with a large TotalRecords, and no-op token renewal.
    BeforeEach {
        InModuleScope VSAModule {
            Mock Update-VSAConnection { }
            Mock Get-RequestData { [pscustomobject]@{ Result = @(1..100); TotalRecords = 5000; ResponseCode = '0'; Status = 'OK' } }
            Mock Invoke-VSAParallelRequest {
                # One canned 100-record page per requested skip.
                foreach ($r in $Request) { [pscustomobject]@{ Id = $r.Id; Response = [pscustomobject]@{ Result = @(1..100) }; Error = $null } }
            }
        }
    }

    It "engages the pump when TotalRecords >= auto threshold (2*throttle*pageSize)" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new(); $conn.URI = 'https://vsa.example/'; $conn.Token = 't'
            $out = Invoke-VSARestMethod -URISuffix 'api/v1.0/things' -VSAConnection $conn -Parallel -ThrottleLimit 8
            Assert-MockCalled Invoke-VSAParallelRequest -Times 1 -Exactly
            $out.Count | Should -Be 5000   # page1 (100) + 49 parallel pages * 100
        }
    }

    It "stays sequential when below an explicit ParallelThreshold" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new(); $conn.URI = 'https://vsa.example/'; $conn.Token = 't'
            Invoke-VSARestMethod -URISuffix 'api/v1.0/things' -VSAConnection $conn -Parallel -ParallelThreshold 999999 | Out-Null
            Assert-MockCalled Invoke-VSAParallelRequest -Times 0 -Exactly
            # Sequential path fetches the remaining 49 pages one by one via Get-RequestData.
            Assert-MockCalled Get-RequestData -Times 50 -Exactly
        }
    }

    It "never engages the pump without -Parallel (default behaviour unchanged)" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new(); $conn.URI = 'https://vsa.example/'; $conn.Token = 't'
            Invoke-VSARestMethod -URISuffix 'api/v1.0/things' -VSAConnection $conn | Out-Null
            Assert-MockCalled Invoke-VSAParallelRequest -Times 0 -Exactly
        }
    }

    It "does not engage the pump for a single-page collection, even below an explicit threshold" {
        InModuleScope VSAModule {
            # Regression: -ParallelThreshold 1 on a collection that fits in one page used to pass the
            # threshold test, build an EMPTY pages-2..N list, and hand it to the pump -- which failed
            # its own ValidateNotNullOrEmpty on -Request. Page 1 is already in hand, so there is
            # nothing left to parallelise. Found live with `Get-VSAAgent -Parallel -ParallelThreshold 1`
            # against 14 agents.
            Mock Get-RequestData { [pscustomobject]@{ Result = @(1..14); TotalRecords = 14; ResponseCode = '0'; Status = 'OK' } }
            $conn = [VSAConnection]::new(); $conn.URI = 'https://vsa.example/'; $conn.Token = 't'
            # Called directly rather than inside a { } | Should -Not -Throw: that runs the scriptblock
            # in a child scope, so the assignment would not escape. A throw fails the test regardless.
            $out = Invoke-VSARestMethod -URISuffix 'api/v1.0/things' -VSAConnection $conn -Parallel -ParallelThreshold 1
            Assert-MockCalled Invoke-VSAParallelRequest -Times 0 -Exactly
            @($out).Count | Should -Be 14
        }
    }

    It "engages the pump when there IS a second page and the threshold is met" {
        InModuleScope VSAModule {
            # Boundary partner to the test above: 101 records = page 1 + one remaining page.
            Mock Get-RequestData { [pscustomobject]@{ Result = @(1..100); TotalRecords = 101; ResponseCode = '0'; Status = 'OK' } }
            Mock Invoke-VSAParallelRequest {
                foreach ($r in $Request) { [pscustomobject]@{ Id = $r.Id; Response = [pscustomobject]@{ Result = @(1) }; Error = $null } }
            }
            $conn = [VSAConnection]::new(); $conn.URI = 'https://vsa.example/'; $conn.Token = 't'
            $out = Invoke-VSARestMethod -URISuffix 'api/v1.0/things' -VSAConnection $conn -Parallel -ParallelThreshold 1
            Assert-MockCalled Invoke-VSAParallelRequest -Times 1 -Exactly
            @($out).Count | Should -Be 101
        }
    }
}

Describe "Get-VSAItemById id-array / -Parallel routing" {

    It "a single id (no -Parallel) calls the transport once and returns its result directly" {
        InModuleScope VSAModule {
            Mock Invoke-VSARestMethod { 'single-result' }
            $r = Get-VSAItemById -URISuffix 'api/v1.0/x/{0}/notes' -Id 42
            $r | Should -Be 'single-result'
            Assert-MockCalled Invoke-VSARestMethod -Times 1 -Exactly
            Assert-MockCalled Invoke-VSARestMethod -ParameterFilter { $URISuffix -eq 'api/v1.0/x/42/notes' } -Times 1
        }
    }

    It "a single id + -Parallel forwards page-parallel controls to the transport" {
        InModuleScope VSAModule {
            # Capture the mocked command's bound args as named variables (Pester does not populate
            # $PSBoundParameters for SPLATTED arguments).
            $script:seen = $null
            Mock Invoke-VSARestMethod { $script:seen = @{ Parallel = $Parallel; ThrottleLimit = $ThrottleLimit; ParallelThreshold = $ParallelThreshold } }
            Get-VSAItemById -URISuffix 'api/v1.0/x/{0}/notes' -Id 42 -Parallel -ThrottleLimit 12 -ParallelThreshold 500 | Out-Null
            [bool]$script:seen['Parallel'] | Should -Be $true
            $script:seen['ThrottleLimit'] | Should -Be 12
            $script:seen['ParallelThreshold'] | Should -Be 500
        }
    }

    It "multiple ids + -Parallel routes to the fan-out helper" {
        InModuleScope VSAModule {
            Mock Invoke-VSABatchGet { 'fanned' }
            $r = Get-VSAItemById -URISuffix 'api/v1.0/x/{0}/notes' -Id 1, 2, 3 -Parallel
            $r | Should -Be 'fanned'
            Assert-MockCalled Invoke-VSABatchGet -ParameterFilter { $Id.Count -eq 3 } -Times 1
        }
    }

    It "multiple ids without -Parallel loops sequentially and concatenates" {
        InModuleScope VSAModule {
            Mock Invoke-VSARestMethod { , @("r-$($URISuffix.Split('/')[-2])") }
            $r = @(Get-VSAItemById -URISuffix 'api/v1.0/x/{0}/notes' -Id 7, 8)
            $r.Count | Should -Be 2
            Assert-MockCalled Invoke-VSARestMethod -Times 2 -Exactly
        }
    }
}

Describe "Invoke-VSABatchGet merge + follow-up rounds" {

    It "flattens per-id results in id order and issues a follow-up round for >1-page ids" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new(); $conn.URI = 'https://vsa.example/'; $conn.Token = 't'
            $script:round = 0
            Mock Invoke-VSAParallelRequest {
                $script:round++
                if ($script:round -eq 1) {
                    # id 1 -> 250 records (needs skip 100 & 200); id 2 -> 1 record (single page)
                    @(
                        [pscustomobject]@{ Id = '1'; Response = [pscustomobject]@{ Result = @('a', 'b'); TotalRecords = 250 }; Error = $null }
                        [pscustomobject]@{ Id = '2'; Response = [pscustomobject]@{ Result = @('z');      TotalRecords = 1 };   Error = $null }
                    )
                } else {
                    # follow-up pages for id 1
                    @(
                        [pscustomobject]@{ Id = '1|100'; Response = [pscustomobject]@{ Result = @('c', 'd') }; Error = $null }
                        [pscustomobject]@{ Id = '1|200'; Response = [pscustomobject]@{ Result = @('e') };      Error = $null }
                    )
                }
            }
            $out = Invoke-VSABatchGet -URISuffixTemplate 'api/v1.0/x/{0}/notes' -Id '1', '2' -VSAConnection $conn
            Assert-MockCalled Invoke-VSAParallelRequest -Times 2 -Exactly
            # id 1's five records precede id 2's single record (id order preserved).
            @($out) | Should -Be @('a', 'b', 'c', 'd', 'e', 'z')
        }
    }

    It "throws the first error when any request fails" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new(); $conn.URI = 'https://vsa.example/'; $conn.Token = 't'
            Mock Invoke-VSAParallelRequest {
                @([pscustomobject]@{ Id = '1'; Response = $null; Error = (New-VSAApiError -Message 'boom' -StatusCode 500 -Method GET -Uri 'u' -VSAError 'boom') })
            }
            { Invoke-VSABatchGet -URISuffixTemplate 'api/v1.0/x/{0}/notes' -Id '1' -VSAConnection $conn } | Should -Throw
        }
    }
}
