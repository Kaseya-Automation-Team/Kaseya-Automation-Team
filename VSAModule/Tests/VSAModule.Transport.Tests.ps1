$ModuleRoot = Split-Path -Path (Split-Path -Parent $PSScriptRoot)
$ModulePath = Join-Path -Path $ModuleRoot -ChildPath 'VSAModule.psd1'

# Installs a fake HttpMessageHandler in place of the network. See Tests/VSAFakeHttp.ps1.
. (Join-Path $PSScriptRoot 'VSAFakeHttp.ps1')

BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "Transport - value escaping and query building" {

    It "ConvertTo-ODataString doubles single quotes only (T-4.1)" {
        InModuleScope VSAModule {
            ConvertTo-ODataString "O'Brien" | Should -Be "O''Brien"
            ConvertTo-ODataString 'C:\path' | Should -Be 'C:\path'  # backslash untouched
        }
    }

    It "Format-VSAPathSegment encodes a single segment (T-4.5)" {
        InModuleScope VSAModule {
            Format-VSAPathSegment 'PC #7' | Should -Match '%23'
        }
    }

    It "Format-VSAPathSegment keeps '/' but encodes spaces (T-4.5)" {
        InModuleScope VSAModule {
            $r = Format-VSAPathSegment 'folder/sub dir'
            $r | Should -Be 'folder/sub%20dir'
        }
    }
}

Describe "Transport - Invoke-VSARestMethod query and filter" {

    BeforeEach {
        InModuleScope VSAModule {
            $script:CapturedUris = New-Object System.Collections.ArrayList
            Mock Update-VSAConnection {}
            Mock Get-RequestData {
                $null = $script:CapturedUris.Add($URI)
                [pscustomobject]@{ Result = @(); ResponseCode = 0; Status = 'OK' }
            }
        }
    }

    It "passes an OData filter through with only URL-encoding (T-4.1/T-4.5)" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new('https://vsa.example.com', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x' -Filter "Name eq 'O''Brien'" | Out-Null
            $uri = $script:CapturedUris[0]
            $uri | Should -Match '\$filter='
            # The decoded filter must equal the original, untouched, string.
            $encoded = ($uri -split '\$filter=')[1] -split '&' | Select-Object -First 1
            [uri]::UnescapeDataString($encoded) | Should -Be "Name eq 'O''Brien'"
        }
    }

    It "URL-encodes spaces and ampersands in the filter (T-4.5)" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new('https://vsa.example.com', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x' -Filter "Name eq 'A & B'" | Out-Null
            $uri = $script:CapturedUris[0]
            $uri | Should -Match '%20'
            $uri | Should -Match '%26'
        }
    }

    It "accepts a valid Sort and emits `$orderby (T-4.2)" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new('https://vsa.example.com', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x' -Sort 'Name asc' | Out-Null
            $uri = $script:CapturedUris[0]
            ($uri -split '\$orderby=')[1] -split '&' | Select-Object -First 1 | ForEach-Object { [uri]::UnescapeDataString($_) } | Should -Be 'Name asc'
        }
    }

    It "throws on an injection-style Sort (T-4.2)" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new('https://vsa.example.com', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            { Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x' -Sort 'Name; DROP' } | Should -Throw
        }
    }
}

Describe "Transport - empty-body 2xx (HTTP 204) is success, not an error (F-21)" {
    # A successful DELETE (and some PUTs) returns 204 No Content: Invoke-RestMethod yields $null on
    # PS7 and '' on some editions. Both must be treated as success. Verified live against a real VSA:
    # DELETE /system/orgs/{id} returns 204 and previously threw "Unexpected API response".

    AfterEach {
        InModuleScope VSAModule { $script:VSAHttpClients.Clear() }
    }

    It "Get-RequestData returns `$null (no throw) for a real 204 with no body" {
        InModuleScope VSAModule {
            $h = [FakeHttpMessageHandler]::new()
            $h.EnqueueResponse(204, '', 0)
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan

            $r = Get-RequestData -URI 'https://vsa.example.com/api/v1.0/x' -AuthString 'Bearer t' -Method DELETE
            $r | Should -Be $null
            $h.CallCount | Should -Be 1
        }
    }

    It "Get-RequestData normalizes a whitespace-only 200 body to `$null (no throw)" {
        InModuleScope VSAModule {
            $h = [FakeHttpMessageHandler]::new()
            $h.EnqueueResponse(200, '   ', 0)
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan

            $r = Get-RequestData -URI 'https://vsa.example.com/api/v1.0/x' -AuthString 'Bearer t' -Method DELETE
            $r | Should -Be $null
        }
    }

    It "Invoke-VSARestMethod returns without error for a DELETE that yields 204" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Get-RequestData { $null }
            $conn = [VSAConnection]::new('https://vsa.example.com', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            { Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/system/orgs/123' -Method DELETE } | Should -Not -Throw
        }
    }
}

Describe "Transport - token renewal ordering (T-4.4)" {

    It "renews the token BEFORE the request, so the request uses the fresh token" {
        InModuleScope VSAModule {
            $script:usedAuth = $null
            # Simulate renewal swapping the token on the connection object.
            Mock Update-VSAConnection { $VSAConnection.UpdateToken('NEWTOKEN') }
            Mock Get-RequestData {
                $script:usedAuth = $AuthString
                [pscustomobject]@{ Result = @(); ResponseCode = 0; Status = 'OK' }
            }
            $conn = [VSAConnection]::new('https://vsa.example.com', 'u', 'OLDTOKEN', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x' | Out-Null
            $script:usedAuth | Should -Be 'Bearer NEWTOKEN'
        }
    }
}

Describe "Transport - pagination" {

    BeforeEach {
        InModuleScope VSAModule {
            $script:PageCalls = New-Object System.Collections.ArrayList
            Mock Update-VSAConnection {}
            Mock Get-RequestData {
                $null = $script:PageCalls.Add($URI)
                $skip = 0
                if ($URI -match '\$skip=(\d+)') { $skip = [int]$Matches[1] }
                $remaining = 250 - $skip
                $count = [Math]::Max(0, [Math]::Min(100, $remaining))
                $items = if ($count -gt 0) { 1..$count | ForEach-Object { [pscustomobject]@{ n = $skip + $_ } } } else { @() }
                [pscustomobject]@{ Result = $items; TotalRecords = 250; ResponseCode = 0; Status = 'OK' }
            }
        }
    }

    It "fetches exactly 3 pages (skip 0/100/200), top=100, 250 records, no trailing empty call (T-4.3)" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new('https://vsa.example.com', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            $result = Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x'
            $script:PageCalls.Count | Should -Be 3
            $result.Count | Should -Be 250
            # every call carries $top=100
            foreach ($u in $script:PageCalls) { $u | Should -Match '\$top=100' }
            # first call has no explicit skip (=0); the next two are 100 and 200
            $script:PageCalls[0] | Should -Not -Match '\$skip='
            $script:PageCalls[1] | Should -Match '\$skip=100'
            $script:PageCalls[2] | Should -Match '\$skip=200'
        }
    }

    It "-ExtendedOutput returns the envelope with the merged Result (T-4.8)" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new('https://vsa.example.com', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            $env = Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x' -ExtendedOutput
            $env.TotalRecords | Should -Be 250
            $env.Result.Count | Should -Be 250
        }
    }
}

Describe "Get-VSAStorageContent - routes through the transport (T-6.1)" {

    It "passes the correct URISuffix and an OutFile under the user profile" {
        InModuleScope VSAModule {
            $script:capSuffix = $null
            $script:capOut = $null
            Mock Invoke-VSARestMethod { $script:capSuffix = $URISuffix; $script:capOut = $OutFile }
            Get-VSAStorageContent -FileId 12345 | Out-Null
            $script:capSuffix | Should -Be 'api/v1.0/storage/file/12345/contents'
            $script:capOut | Should -Match '12345\.webm$'
            $script:capOut | Should -Match ([regex]::Escape([Environment]::GetFolderPath('UserProfile')))
        }
    }
}

Describe "Transport - Get-RequestData error handling (dual runtime)" {

    # These exercise the REAL transport (Invoke-VSAHttp + HttpClient) against a fake
    # HttpMessageHandler, so the retry loop, status handling and Retry-After parsing are genuinely
    # executed rather than simulated (F-67).

    AfterEach {
        InModuleScope VSAModule { $script:VSAHttpClients.Clear() }
    }

    It "retries a transient 503 then succeeds (T-4.6)" {
        InModuleScope VSAModule {
            $h = [FakeHttpMessageHandler]::new()
            $h.EnqueueResponse(503, '', 0)
            $h.EnqueueResponse(200, '{"Result":[],"ResponseCode":0,"Status":"OK"}', 0)
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan

            $r = Get-RequestData -URI 'https://vsa.example.com/api/v1.0/x' -AuthString 'Bearer t' -MaxRetries 3 -WarningAction SilentlyContinue
            $h.CallCount | Should -Be 2
            $r.Status | Should -Be 'OK'
        }
    }

    It "honours Retry-After on 429 (T-4.6)" {
        InModuleScope VSAModule {
            $h = [FakeHttpMessageHandler]::new()
            $h.EnqueueResponse(429, '', 2)   # server asks for 2s; exponential backoff alone would be 1s
            $h.EnqueueResponse(200, '{"Result":[],"ResponseCode":0,"Status":"OK"}', 0)
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            Get-RequestData -URI 'https://vsa.example.com/api/v1.0/x' -AuthString 'Bearer t' -MaxRetries 3 -WarningAction SilentlyContinue | Out-Null
            $sw.Stop()
            $h.CallCount | Should -Be 2
            # Proves the server's hint won over the client's own (shorter) exponential backoff.
            $sw.Elapsed.TotalSeconds | Should -BeGreaterThan 1.5
        }
    }

    It "surfaces the VSA error body from a terminal 400, thrown once (T-4.6)" {
        InModuleScope VSAModule {
            $h = [FakeHttpMessageHandler]::new()
            $h.EnqueueResponse(400, '{"Error":"bad filter"}', 0)
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan

            { Get-RequestData -URI 'https://vsa.example.com/api/v1.0/x' -AuthString 'Bearer t' -MaxRetries 3 } |
                Should -Throw -ExpectedMessage '*bad filter*'
            # A terminal 400 is not transient: exactly one attempt, no retry storm.
            $h.CallCount | Should -Be 1
        }
    }

    It "does NOT retry a terminal 400 but DOES retry each transient status (T-4.6)" {
        InModuleScope VSAModule {
            foreach ($status in @(429, 502, 503, 504)) {
                $h = [FakeHttpMessageHandler]::new()
                $h.EnqueueResponse($status, '', 0)
                $h.EnqueueResponse(200, '{"Result":[],"ResponseCode":0,"Status":"OK"}', 0)
                $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
                $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan

                Get-RequestData -URI 'https://vsa.example.com/api/v1.0/x' -AuthString 'Bearer t' -MaxRetries 3 -WarningAction SilentlyContinue | Out-Null
                $h.CallCount | Should -Be 2 -Because "HTTP $status is transient and must be retried"
                $script:VSAHttpClients.Clear()
            }
        }
    }

    It "sends the Authorization header, method and body the caller asked for" {
        InModuleScope VSAModule {
            $h = [FakeHttpMessageHandler]::new()
            $h.EnqueueResponse(200, '{"ResponseCode":0,"Status":"OK"}', 0)
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan

            Get-RequestData -URI 'https://vsa.example.com/api/v1.0/x' -AuthString 'Bearer TOK' -Method POST -Body '{"a":1}' | Out-Null
            $h.AuthHeaders[0]   | Should -Be 'Bearer TOK'
            $h.Methods[0]       | Should -Be 'POST'
            $h.RequestBodies[0] | Should -Be '{"a":1}'
            $h.ContentTypes[0]  | Should -Be 'application/json'
        }
    }

    It "sends a byte[] body with its Content-Type verbatim, preserving a multipart boundary (F-37)" {
        InModuleScope VSAModule {
            $h = [FakeHttpMessageHandler]::new()
            $h.EnqueueResponse(200, '{"ResponseCode":0,"Status":"OK"}', 0)
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan

            [byte[]] $bytes = [System.Text.Encoding]::UTF8.GetBytes('--B123--')
            $ct = 'multipart/form-data; boundary="B123"'
            Get-RequestData -URI 'https://vsa.example.com/api/v1.0/upload' -AuthString 'Bearer t' -Method POST -Body $bytes -ContentType $ct | Out-Null
            # The boundary parameter must survive byte-for-byte -- StringContent would have appended
            # its own charset and corrupted it.
            $h.ContentTypes[0]  | Should -Be $ct
            $h.RequestBodies[0] | Should -Be '--B123--'
        }
    }

    It "writes the response body to -OutFile and returns nothing" {
        InModuleScope VSAModule {
            $h = [FakeHttpMessageHandler]::new()
            $h.EnqueueResponse(200, 'RAWFILEBYTES', 0)
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan

            $out = Join-Path ([System.IO.Path]::GetTempPath()) "vsa-outfile-$([guid]::NewGuid()).bin"
            try {
                $r = Get-RequestData -URI 'https://vsa.example.com/api/v1.0/file' -AuthString 'Bearer t' -OutFile $out
                $r | Should -BeNullOrEmpty
                Test-Path $out | Should -BeTrue
                [System.IO.File]::ReadAllText($out) | Should -Be 'RAWFILEBYTES'
            } finally {
                Remove-Item $out -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "Transport - shared retry/envelope policy is a single source of truth (F-67)" {

    # The policy functions are extracted precisely so both dispatch modes share them; testing them
    # directly is cheaper and stricter than inferring the rules through a transport.

    It "Get-VSABackoffSeconds prefers a server Retry-After over exponential backoff" {
        InModuleScope VSAModule {
            Get-VSABackoffSeconds -Attempt 1 -RetryAfterSeconds 7 | Should -Be 7
            Get-VSABackoffSeconds -Attempt 1 -RetryAfterSeconds $null | Should -Be 1
            Get-VSABackoffSeconds -Attempt 3 -RetryAfterSeconds $null | Should -Be 4
        }
    }

    It "Get-VSABackoffSeconds caps the wait at 30s from either source" {
        InModuleScope VSAModule {
            Get-VSABackoffSeconds -Attempt 10 -RetryAfterSeconds $null | Should -Be 30
            Get-VSABackoffSeconds -Attempt 1  -RetryAfterSeconds 9999  | Should -Be 30
        }
    }

    It "Resolve-VSAResponse returns a raw non-enveloped payload as-is (F-63)" {
        InModuleScope VSAModule {
            $raw = [pscustomobject]@{ '757824222824211' = 'KCB_BackupStatus_Ok' }
            (Resolve-VSAResponse -Response $raw -Method GET -Uri 'x').'757824222824211' | Should -Be 'KCB_BackupStatus_Ok'
        }
    }

    It "Resolve-VSAResponse throws typed on an app error inside a 200 envelope" {
        InModuleScope VSAModule {
            $env = [pscustomobject]@{ ResponseCode = '400'; Error = 'bad request'; Result = $null }
            { Resolve-VSAResponse -Response $env -Method POST -Uri 'x' } | Should -Throw '*bad request*'
        }
    }

    It "Resolve-VSAResponse throws on an unrecognised envelope rather than returning it silently" {
        InModuleScope VSAModule {
            $env = [pscustomobject]@{ ResponseCode = '999'; Status = 'WAT' }
            { Resolve-VSAResponse -Response $env -Method GET -Uri 'x' } | Should -Throw '*Unexpected API response*'
        }
    }

    It "Test-VSARetryable retries transient statuses for ANY method (the server said it did not process)" {
        InModuleScope VSAModule {
            foreach ($m in @('GET','POST','PUT','DELETE')) {
                foreach ($s in @(429, 502, 503, 504)) {
                    Test-VSARetryable -StatusCode $s -Method $m | Should -BeTrue -Because "HTTP $s on $m is transient"
                }
                Test-VSARetryable -StatusCode 400 -Method $m | Should -BeFalse
                Test-VSARetryable -StatusCode 404 -Method $m | Should -BeFalse
            }
        }
    }

    It "Test-VSARetryable retries a no-response ONLY for idempotent methods" {
        InModuleScope VSAModule {
            # A reset leaves us unable to know whether the server applied the request. Repeating a
            # GET is safe; repeating a POST/PUT/DELETE could apply it twice. It is also how a blocked
            # (post-2021) write endpoint answers, so retrying just burns the backoff.
            Test-VSARetryable -StatusCode 0 -Method 'GET' -NoResponse $true | Should -BeTrue
            foreach ($m in @('POST','PUT','DELETE')) {
                Test-VSARetryable -StatusCode 0 -Method $m -NoResponse $true | Should -BeFalse -Because "$m is not idempotent; a retry could duplicate the write"
            }
        }
    }

    It "a blocked write endpoint fails fast: no retry storm, ConnectionReset raised once" {
        InModuleScope VSAModule {
            $h = [FakeHttpMessageHandler]::new()
            1..4 | ForEach-Object { $h.EnqueueFault() }   # plenty available IF it wrongly retried
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan
            try {
                $err = $null
                try { Get-RequestData -URI 'https://vsa.example.com/api/v1.0/system/users/9' -AuthString 'Bearer t' -Method DELETE -MaxRetries 3 } catch { $err = $_ }
                $err.Exception.ConnectionReset | Should -BeTrue
                $h.CallCount | Should -Be 1 -Because 'a DELETE that got no response must not be retried'
            } finally { $script:VSAHttpClients.Clear() }
        }
    }

    It "a GET that gets no response IS retried (read fan-outs survive a socket blip)" {
        InModuleScope VSAModule {
            $h = [FakeHttpMessageHandler]::new()
            $h.EnqueueFault()
            $h.EnqueueResponse(200, '{"Result":[],"ResponseCode":0,"Status":"OK"}', 0)
            $script:VSAHttpClients['strict'] = [System.Net.Http.HttpClient]::new($h)
            $script:VSAHttpClients['strict'].Timeout = [System.Threading.Timeout]::InfiniteTimeSpan
            try {
                $r = Get-RequestData -URI 'https://vsa.example.com/api/v1.0/x' -AuthString 'Bearer t' -Method GET -MaxRetries 3 -WarningAction SilentlyContinue
                $h.CallCount | Should -Be 2
                $r.Status | Should -Be 'OK'
            } finally { $script:VSAHttpClients.Clear() }
        }
    }

    It "both dispatch modes share ONE retry-status set" {
        InModuleScope VSAModule {
            $script:VSARetryStatuses | Should -Be @(429, 502, 503, 504)
            # Guard against a second, drifting copy being reintroduced in either path.
            # private/ is a SIBLING of Tests/, not a child: the old path (Join-Path $PSScriptRoot
            # 'private/...') resolved to Tests/private/... which does not exist, so Get-Content
            # returned $null and `$null | Should -Not -Match` passed VACUOUSLY -- the drift guard
            # never actually read the file (F-74, caught by the 5.1 pass).
            $src = Get-Content (Join-Path (Split-Path -Parent $PSScriptRoot) 'private/Invoke-VSAParallelRequest.ps1') -Raw
            $src | Should -Not -BeNullOrEmpty -Because 'the guard must actually read the file, not pass on a null'
            $src | Should -Not -Match '(?m)^\s*\$retryStatuses\s*='
        }
    }
}

Describe "Transport - URISuffix that already has a query, and status-only responses (F-22 / F-23)" {

    It "on a GET, joins OData params with '&' (not a 2nd '?') when the URISuffix already has a query (F-22)" {
        InModuleScope VSAModule {
            $script:capturedUri = $null
            Mock Update-VSAConnection {}
            Mock Get-RequestData { $script:capturedUri = $URI; [pscustomobject]@{ Result = @(); ResponseCode = 0; Status = 'OK' } }
            $conn = [VSAConnection]::new('https://vsa.example.com', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x?flag=true' -Method GET | Out-Null
            # exactly one '?' in the whole URL, and $top is appended with '&'
            (($script:capturedUri.ToCharArray() | Where-Object { $_ -eq '?' }).Count) | Should -Be 1
            $script:capturedUri | Should -Match 'flag=true&\$top='
        }
    }

    It "does NOT append `$top/OData params to a WRITE (paging options are read-only)" {
        InModuleScope VSAModule {
            $script:capturedUri = $null
            Mock Update-VSAConnection {}
            Mock Get-RequestData { $script:capturedUri = $URI; [pscustomobject]@{ ResponseCode = 0; Status = 'OK' } }
            $conn = [VSAConnection]::new('https://vsa.example.com', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x/true?flag=true' -Method PUT | Out-Null
            $script:capturedUri | Should -Not -Match '\$top'
            $script:capturedUri | Should -Not -Match '\$skip'
            # the URISuffix's own query is left intact, still exactly one '?'
            (($script:capturedUri.ToCharArray() | Where-Object { $_ -eq '?' }).Count) | Should -Be 1
            $script:capturedUri | Should -Match 'flag=true'
        }
    }

    It "does not throw when a (write) response envelope has no 'Result' property (F-23)" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Get-RequestData { [pscustomobject]@{ ResponseCode = 0; Status = 'OK' } }   # status-only, no Result
            $conn = [VSAConnection]::new('https://vsa.example.com', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            { Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x/true?flag=true' -Method PUT } | Should -Not -Throw
        }
    }
}

Describe "Sequential path recovers from a server-side session invalidation (F-77)" {

    # A VSA session can die long before its client-tracked expiry (SaaS early cut-off, or
    # Close-VSAUserSession logging the current session out). Update-VSAConnection only compares the
    # client-side SessionExpiration to the clock, so it cannot detect this; before F-77 every
    # subsequent call failed 401 forever despite the module holding the PAT. Found live: after
    # Close-VSAUserSession, a connection expiring two days later 401'd permanently. The parallel
    # pump already recovered (single forced renewal per 401); the sequential path now mirrors it.

    It "renews ONCE on a 401 and retries with the fresh token" {
        InModuleScope VSAModule {
            $script:calls = 0
            $script:seenAuth = @()
            Mock Get-RequestData {
                $script:calls++
                $script:seenAuth += $AuthString
                if ($script:calls -eq 1) { throw (New-VSAApiError -Message 'dead session' -StatusCode 401 -Method GET -Uri 'https://h/x') }
                [pscustomobject]@{ Result = @(1,2); ResponseCode = 0; Status = 'OK' }
            }
            Mock Update-VSAConnection { if ($Force) { $VSAConnection.UpdateToken('RENEWED') } }

            $conn = [VSAConnection]::new('https://vsa.example/', 'u', 'OLDTOK', 'pat', [datetime]::Now.AddDays(2), $false, $false)
            $out = @(Invoke-VSARestMethod -URISuffix 'api/v1.0/x' -VSAConnection $conn)

            $out.Count | Should -Be 2
            Should -Invoke Get-RequestData -Times 2 -Exactly
            Should -Invoke Update-VSAConnection -ParameterFilter { [bool]$Force } -Times 1 -Exactly
            # The retry must actually carry the renewed token, not the dead one.
            $script:seenAuth[1] | Should -Be 'Bearer RENEWED'
        }
    }

    It "does NOT loop: a second 401 (genuinely bad credentials) surfaces typed after exactly one retry" {
        InModuleScope VSAModule {
            $script:calls = 0
            Mock Get-RequestData {
                $script:calls++
                throw (New-VSAApiError -Message 'still unauthorized' -StatusCode 401 -Method GET -Uri 'https://h/x')
            }
            Mock Update-VSAConnection { }

            $conn = [VSAConnection]::new('https://vsa.example/', 'u', 'tok', 'pat', [datetime]::Now.AddDays(2), $false, $false)
            $err = $null
            try { Invoke-VSARestMethod -URISuffix 'api/v1.0/x' -VSAConnection $conn } catch { $err = $_ }

            $err.Exception | Should -BeOfType ([VSAApiException])
            $err.Exception.StatusCode | Should -Be 401
            $script:calls | Should -Be 2 -Because 'one initial attempt + exactly one post-renewal retry, never a loop'
        }
    }

    It "a non-401 error triggers NO forced renewal (behaviour for 403/404/500 unchanged)" {
        InModuleScope VSAModule {
            Mock Get-RequestData { throw (New-VSAApiError -Message 'forbidden' -StatusCode 403 -Method GET -Uri 'https://h/x') }
            Mock Update-VSAConnection { }

            $conn = [VSAConnection]::new('https://vsa.example/', 'u', 'tok', 'pat', [datetime]::Now.AddDays(2), $false, $false)
            { Invoke-VSARestMethod -URISuffix 'api/v1.0/x' -VSAConnection $conn } | Should -Throw
            Should -Invoke Get-RequestData -Times 1 -Exactly
            Should -Invoke Update-VSAConnection -ParameterFilter { [bool]$Force } -Times 0 -Exactly
        }
    }
}
