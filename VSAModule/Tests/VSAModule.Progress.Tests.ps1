BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "New-VSAProgressId issues an isolated bar id" {

    It "returns a non-zero, positive Int32 (never progress id 0, which collides with a caller's bar)" {
        InModuleScope VSAModule {
            $id = New-VSAProgressId
            $id | Should -BeOfType ([int])
            $id | Should -BeGreaterThan 0
        }
    }

    It "returns distinct ids across operations" {
        InModuleScope VSAModule {
            $ids = 1..50 | ForEach-Object { New-VSAProgressId }
            ($ids | Sort-Object -Unique).Count | Should -Be 50
        }
    }
}

Describe "Write-VSAProgress: the module's single progress policy" {

    It "throttles rapid updates to one redraw, but -Completed always draws" {
        InModuleScope VSAModule {
            Mock Write-Progress {}
            $id = New-VSAProgressId
            Write-VSAProgress -Id $id -Activity 'T' -Current 1 -Total 100   # first: draws
            Write-VSAProgress -Id $id -Activity 'T' -Current 2 -Total 100   # <200ms: coalesced
            Write-VSAProgress -Id $id -Activity 'T' -Current 3 -Total 100   # <200ms: coalesced
            Should -Invoke Write-Progress -Times 1 -Exactly -ParameterFilter { -not $Completed }
            Write-VSAProgress -Id $id -Activity 'T' -Completed
            Should -Invoke Write-Progress -Times 1 -Exactly -ParameterFilter { $Completed }
        }
    }

    It "draws again once the throttle window (~200ms) has elapsed" {
        InModuleScope VSAModule {
            Mock Write-Progress {}
            $id = New-VSAProgressId
            Write-VSAProgress -Id $id -Activity 'T' -Current 1 -Total 100
            # Backdate the last-draw stamp past the window instead of sleeping.
            $script:VSAProgressLastDraw[$id] = [datetime]::UtcNow.AddSeconds(-1)
            Write-VSAProgress -Id $id -Activity 'T' -Current 2 -Total 100
            Should -Invoke Write-Progress -Times 2 -Exactly -ParameterFilter { -not $Completed }
            Write-VSAProgress -Id $id -Activity 'T' -Completed
        }
    }

    It "-Completed clears the operation's throttle state (the map does not grow across operations)" {
        InModuleScope VSAModule {
            Mock Write-Progress {}
            $id = New-VSAProgressId
            Write-VSAProgress -Id $id -Activity 'T' -Current 1 -Total 10
            $script:VSAProgressLastDraw.ContainsKey($id) | Should -BeTrue
            Write-VSAProgress -Id $id -Activity 'T' -Completed
            $script:VSAProgressLastDraw.ContainsKey($id) | Should -BeFalse
        }
    }

    It "shows a percentage when the total is known" {
        InModuleScope VSAModule {
            Mock Write-Progress {}
            Write-VSAProgress -Id (New-VSAProgressId) -Activity 'T' -Current 25 -Total 100
            Should -Invoke Write-Progress -Times 1 -Exactly -ParameterFilter { $PercentComplete -eq 25 }
        }
    }

    It "omits the percentage when the total is unknown (0) instead of dividing by zero" {
        InModuleScope VSAModule {
            Mock Write-Progress {}
            { Write-VSAProgress -Id (New-VSAProgressId) -Activity 'T' -Current 5 -Total 0 } | Should -Not -Throw
            Should -Invoke Write-Progress -Times 1 -Exactly -ParameterFilter { -not $PSBoundParameters.ContainsKey('PercentComplete') }
        }
    }

    It "is not coupled to -Verbose/-Debug: it draws with both off (suppression is via `$ProgressPreference)" {
        InModuleScope VSAModule {
            Mock Write-Progress {}
            $VerbosePreference = 'SilentlyContinue'
            $DebugPreference   = 'SilentlyContinue'
            Write-VSAProgress -Id (New-VSAProgressId) -Activity 'T' -Current 1 -Total 10
            Should -Invoke Write-Progress -Times 1 -Exactly
        }
    }
}

Describe "The read paths drive progress through the shared helper" {

    It "a multi-page SEQUENTIAL read updates the bar per page and completes it once" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Write-VSAProgress {}
            # 250 records at 100/page => page 1 (pre-loop) + pages 2 and 3 in the loop.
            Mock Get-RequestData { [pscustomobject]@{ TotalRecords = 250; Result = @(1..100) } }

            $conn = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/test' | Out-Null

            Should -Invoke Write-VSAProgress -Times 2 -Exactly -ParameterFilter { -not $Completed }
            Should -Invoke Write-VSAProgress -Times 1 -Exactly -ParameterFilter { $Completed }
        }
    }

    It "a single-page SEQUENTIAL read draws no intermediate bar (nothing to page)" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Write-VSAProgress {}
            Mock Get-RequestData { [pscustomobject]@{ TotalRecords = 10; Result = @(1..10) } }

            $conn = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/test' | Out-Null

            Should -Invoke Write-VSAProgress -Times 0 -Exactly -ParameterFilter { -not $Completed }
        }
    }

    It "the PARALLEL pump completes its bar exactly once (finally), on a fresh bar id" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Write-VSAProgress {}
            Mock Test-VSARetryable { $false }                       # no retry: the item resolves terminally
            Mock New-VSATransportError { [pscustomobject]@{ msg = 'x' } }
            # A client whose SendAsync returns a FAULTED task: the pump catches it, records a terminal
            # error for the item, and runs to completion -- so we can assert the finally -Completed.
            $faulting = [pscustomobject]@{}
            $faulting | Add-Member -MemberType ScriptMethod -Name SendAsync -Value {
                $tcs = [System.Threading.Tasks.TaskCompletionSource[System.Net.Http.HttpResponseMessage]]::new()
                $tcs.SetException([System.InvalidOperationException]::new('boom'))
                return $tcs.Task
            }
            Mock Get-VSAHttpClient { $faulting }

            $conn = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            { Invoke-VSAParallelRequest -Request @(@{ Id = 0; Uri = 'https://h/x' }) -VSAConnection $conn } | Should -Not -Throw

            Should -Invoke Write-VSAProgress -Times 1 -Exactly -ParameterFilter { $Completed }
        }
    }
}
