# The module has a single HTTP stack (HttpClient) since v1.5.1, so terminal failures are simulated
# with a fake HttpMessageHandler rather than by mocking Invoke-RestMethod (F-67).
. (Join-Path $PSScriptRoot "VSAFakeHttp.ps1")
BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "New-VSAApiError classifies failures into typed, branchable errors" {

    It "maps HTTP status to StatusCode, ErrorCategory, and errorId" -ForEach @(
        @{ Status = 401; Category = 'AuthenticationError'; Id = 'VSAHttp401' }
        @{ Status = 403; Category = 'PermissionDenied';    Id = 'VSAHttp403' }
        @{ Status = 404; Category = 'ObjectNotFound';      Id = 'VSAHttp404' }
        @{ Status = 500; Category = 'InvalidOperation';    Id = 'VSAHttp500' }
    ) {
        InModuleScope VSAModule -Parameters @{ Status = $Status; Category = $Category; Id = $Id } {
            param($Status, $Category, $Id)
            $rec = New-VSAApiError -Message 'x' -StatusCode $Status -Method 'PUT' -Uri 'https://h/api'
            $rec | Should -BeOfType ([System.Management.Automation.ErrorRecord])
            $rec.Exception | Should -BeOfType ([VSAApiException])
            $rec.Exception.StatusCode | Should -Be $Status
            $rec.Exception.ConnectionReset | Should -Be $false
            $rec.CategoryInfo.Category | Should -Be $Category
            $rec.FullyQualifiedErrorId | Should -BeLike "$Id*"
        }
    }

    It "flags a connection reset (StatusCode 0) as ConnectionError" {
        InModuleScope VSAModule {
            $rec = New-VSAApiError -Message 'reset' -StatusCode 0 -Method 'DELETE' -Uri 'https://h/api' -ConnectionReset
            $rec.Exception.StatusCode | Should -Be 0
            $rec.Exception.ConnectionReset | Should -Be $true
            $rec.CategoryInfo.Category | Should -Be 'ConnectionError'
            $rec.FullyQualifiedErrorId | Should -BeLike 'VSAConnectionReset*'
        }
    }
}

Describe "Get-RequestData throws typed VSAApiException" {

    AfterEach {
        InModuleScope VSAModule { $script:VSAHttpClients.Clear() }
    }

    It "surfaces an HTTP 404 as StatusCode 404 / ObjectNotFound" {
        InModuleScope VSAModule {
            $h = [FakeHttpMessageHandler]::new()
            $h.EnqueueResponse(404, '{"Error":"Org does not exist"}', 0)
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan

            $err = $null
            try { Get-RequestData -URI 'https://vsa.example.com/api/v1.0/system/orgs/9' -AuthString 'Bearer t' -Method DELETE }
            catch { $err = $_ }
            $err.Exception | Should -BeOfType ([VSAApiException])
            $err.Exception.StatusCode | Should -Be 404
            $err.Exception.ConnectionReset | Should -Be $false
            $err.CategoryInfo.Category | Should -Be 'ObjectNotFound'
            $err.Exception.VSAError | Should -Be 'Org does not exist'
        }
    }

    It "surfaces a connection reset (no HTTP response) as ConnectionReset / StatusCode 0" {
        InModuleScope VSAModule {
            # Deterministic: the handler faults with no response at all, which is what a hardened
            # (post-2021) VSA does to user-mutation endpoints. Retries are disabled so the terminal
            # classification is what is under test, not the retry loop.
            $h = [FakeHttpMessageHandler]::new()
            $h.EnqueueFault()
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan

            $err = $null
            try { Get-RequestData -URI 'https://vsa.example.com/api/v1.0/system/users/9' -AuthString 'Bearer t' -Method DELETE -MaxRetries 0 }
            catch { $err = $_ }
            $err.Exception | Should -BeOfType ([VSAApiException])
            $err.Exception.StatusCode | Should -Be 0
            $err.Exception.ConnectionReset | Should -Be $true
            $err.CategoryInfo.Category | Should -Be 'ConnectionError'
            $err.Exception.Message | Should -BeLike '*blocked or*restricted*'
        }
    }

    It "surfaces an application-level error inside an HTTP 200 envelope as typed" {
        InModuleScope VSAModule {
            $h = [FakeHttpMessageHandler]::new()
            $h.EnqueueResponse(200, '{"ResponseCode":"400","Error":"bad request","Result":null}', 0)
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan

            $err = $null
            try { Get-RequestData -URI 'https://vsa.example.com/api/v1.0/x' -AuthString 'Bearer t' -Method POST -Body '{}' }
            catch { $err = $_ }
            $err.Exception | Should -BeOfType ([VSAApiException])
            $err.Exception.StatusCode | Should -Be 400
            $err.Exception.ConnectionReset | Should -Be $false
            $err.Exception.VSAError | Should -Be 'bad request'
        }
    }

    It "a -Parallel caller receives the SAME typed error a sequential caller would (F-67)" {
        InModuleScope VSAModule {
            # The regression this guards: the parallel path used to re-throw the raw transport
            # exception, so .StatusCode / .ConnectionReset branching silently stopped working under
            # -Parallel. Both paths now build the error through New-VSATransportError.
            $reset = New-VSATransportError -StatusCode 0 -Method 'GET' -Uri 'https://h/x' -InnerException ([Exception]::new('socket reset'))
            $reset.Exception | Should -BeOfType ([VSAApiException])
            $reset.Exception.ConnectionReset | Should -Be $true
            $reset.Exception.StatusCode | Should -Be 0

            $notFound = New-VSATransportError -StatusCode 404 -Method 'GET' -Uri 'https://h/x' -Body '{"Error":"nope"}'
            $notFound.Exception | Should -BeOfType ([VSAApiException])
            $notFound.Exception.ConnectionReset | Should -Be $false
            $notFound.Exception.VSAError | Should -Be 'nope'
            $notFound.CategoryInfo.Category | Should -Be 'ObjectNotFound'
        }
    }
}

Describe "Invoke-VSARestMethod preserves the typed error (does not flatten to string)" {

    It "re-throws the VSAApiException with StatusCode/Category intact" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Get-RequestData { throw (New-VSAApiError -Message 'boom' -StatusCode 403 -Method 'PUT' -Uri 'https://h/api/v1.0/system/users/9') }
            $conn = [VSAConnection]::new(); $conn.URI = 'https://h'; $conn.Token = 't'
            $err = $null
            try { Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/system/users/9' -Method PUT -Body '{}' } catch { $err = $_ }
            $err.Exception | Should -BeOfType ([VSAApiException])
            $err.Exception.StatusCode | Should -Be 403
            $err.CategoryInfo.Category | Should -Be 'PermissionDenied'
        }
    }
}
