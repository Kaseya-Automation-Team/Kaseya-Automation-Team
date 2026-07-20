BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "ConvertFrom-VSAResponseBody: the single JSON decode step (body -> resolved object)" {

    It "normalizes an empty or whitespace body to `$null (F-21, HTTP 204 success)" {
        InModuleScope VSAModule {
            ConvertFrom-VSAResponseBody -Body ''    -Method 'DELETE' -Uri 'https://h/x' | Should -BeNullOrEmpty
            ConvertFrom-VSAResponseBody -Body '   ' -Method 'PUT'    -Uri 'https://h/x' | Should -BeNullOrEmpty
        }
    }

    It "decodes a success envelope and returns the resolved object" {
        InModuleScope VSAModule {
            $r = ConvertFrom-VSAResponseBody -Body '{"ResponseCode":0,"Result":[1,2,3],"TotalRecords":3}' -Method 'GET' -Uri 'https://h/x'
            @($r.Result).Count | Should -Be 3
            $r.TotalRecords    | Should -Be 3
        }
    }

    It "returns a raw non-enveloped payload as-is (F-63, e.g. Cloud Backup's flat map)" {
        InModuleScope VSAModule {
            $r = ConvertFrom-VSAResponseBody -Body '{"12345":"BackedUp"}' -Method 'GET' -Uri 'https://h/kcb'
            $r.'12345' | Should -Be 'BackedUp'
        }
    }

    It "throws typed for an application-level error inside an HTTP 200 envelope" {
        InModuleScope VSAModule {
            $err = $null
            try { ConvertFrom-VSAResponseBody -Body '{"ResponseCode":400,"Error":"boom"}' -Method 'GET' -Uri 'https://h/x' } catch { $err = $_ }
            $err | Should -Not -BeNullOrEmpty
            $err.Exception.GetType().Name | Should -Be 'VSAApiException'
            $err.Exception.StatusCode     | Should -Be 400
            $err.Exception.VSAError       | Should -Be 'boom'
        }
    }

    It "throws a typed VSAApiException naming XML for an XML body (F-72)" {
        InModuleScope VSAModule {
            $err = $null
            try { ConvertFrom-VSAResponseBody -Body '<?xml version="1.0"?><ScExport/>' -StatusCode 200 -Method 'GET' -Uri 'https://h/proclist' } catch { $err = $_ }
            $err | Should -Not -BeNullOrEmpty
            $err.Exception.GetType().Name | Should -Be 'VSAApiException'
            $err.Exception.Message        | Should -Match 'XML'
            $err.Exception.StatusCode     | Should -Be 200
        }
    }

    It "throws a typed VSAApiException for a non-JSON text body (F-72)" {
        InModuleScope VSAModule {
            $err = $null
            try { ConvertFrom-VSAResponseBody -Body 'Service Unavailable' -StatusCode 200 -Method 'GET' -Uri 'https://h/x' } catch { $err = $_ }
            $err | Should -Not -BeNullOrEmpty
            $err.Exception.GetType().Name | Should -Be 'VSAApiException'
            $err.Exception.Message        | Should -Match 'not JSON'
        }
    }
}

Describe "ConvertFrom-VSAScExportResponse: the XML decoder shaped like the JSON one" {

    BeforeAll {
        $script:Xml = @'
<ScExport xmlns="http://www.kaseya.com/vsa/2008/12/Scripting">
  <Records totalRecords="2" startingRecordIndex="0" currentNumRecords="2" />
  <Procedure id="659091963" name="A" treeFullPath="p\A" folderId="546051318732114" shared="true" treePres="3" />
  <Procedure id="12" name="B" treeFullPath="p\B" folderId="34" shared="false" treePres="2" />
</ScExport>
'@
    }

    It "shapes ScExport into { Result = procedures; TotalRecords } so the engine can page it" {
        InModuleScope VSAModule -Parameters @{ xml = $script:Xml } {
            param($xml)
            $r = ConvertFrom-VSAScExportResponse -Body $xml -Method 'GET' -Uri 'https://h/proclist'
            $r.TotalRecords    | Should -Be 2
            @($r.Result).Count | Should -Be 2
            $r.Result[0].Id    | Should -Be '659091963'
            $r.Result[0].Path  | Should -Be 'p\A'
        }
    }

    It "normalizes an empty body to `$null (F-21), like every other read" {
        InModuleScope VSAModule {
            ConvertFrom-VSAScExportResponse -Body '' -Method 'GET' -Uri 'https://h/proclist' | Should -BeNullOrEmpty
        }
    }

    It "shares the JSON decoder's parameter signature (interchangeable as -Decoder)" {
        InModuleScope VSAModule {
            $json = (Get-Command ConvertFrom-VSAResponseBody).Parameters.Keys | Where-Object { $_ -in 'Body','StatusCode','Method','Uri' } | Sort-Object
            $xml  = (Get-Command ConvertFrom-VSAScExportResponse).Parameters.Keys | Where-Object { $_ -in 'Body','StatusCode','Method','Uri' } | Sort-Object
            ($xml -join ',') | Should -Be ($json -join ',')
        }
    }
}

Describe "Expand-VSAEnvelope: the single envelope classification (resolved object -> engine facts)" {

    It "classifies `$null as IsNull (F-21): the engine returns nothing rather than expand '.Result'" {
        InModuleScope VSAModule {
            $p = Expand-VSAEnvelope -Response $null
            $p.IsNull     | Should -BeTrue
            $p.IsEnvelope | Should -BeFalse
        }
    }

    It "classifies an object with no envelope fields as non-envelope (F-63 raw payload)" {
        InModuleScope VSAModule {
            $p = Expand-VSAEnvelope -Response ([pscustomobject]@{ '12345' = 'BackedUp'; '678' = 'Failed' })
            $p.IsNull     | Should -BeFalse
            $p.IsEnvelope | Should -BeFalse
        }
    }

    It "classifies a status-only envelope (ResponseCode/Status, no Result) as an envelope with `$null Result (F-23)" {
        InModuleScope VSAModule {
            $p = Expand-VSAEnvelope -Response ([pscustomobject]@{ ResponseCode = 200; Status = 'OK' })
            $p.IsEnvelope | Should -BeTrue
            $p.Result     | Should -BeNullOrEmpty
            $p.Paginated  | Should -BeFalse
        }
    }

    It "preserves the Result array exactly, including a single-element array" {
        InModuleScope VSAModule {
            $p = Expand-VSAEnvelope -Response ([pscustomobject]@{ ResponseCode = 0; Result = @([pscustomobject]@{ Id = '1' }) })
            @($p.Result).Count | Should -Be 1
            $p.Result[0].Id    | Should -Be '1'
        }
    }

    It "signals pagination on the PRESENCE of TotalRecords: TotalRecords=0 is still paginated (locks historical behaviour)" {
        InModuleScope VSAModule {
            $p = Expand-VSAEnvelope -Response ([pscustomobject]@{ ResponseCode = 0; Result = @(); TotalRecords = 0 })
            $p.Paginated    | Should -BeTrue
            $p.TotalRecords | Should -Be 0
        }
    }

    It "does not signal pagination when TotalRecords is absent" {
        InModuleScope VSAModule {
            $p = Expand-VSAEnvelope -Response ([pscustomobject]@{ ResponseCode = 0; Result = @(1, 2) })
            $p.Paginated | Should -BeFalse
        }
    }
}

Describe "The engine consumes the decoder: end-to-end equivalence through Invoke-VSARestMethod" {

    It "returns `$null for an empty-body 204 success (F-21)" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Get-RequestData { $null }
            $conn = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x' -Method DELETE | Should -BeNullOrEmpty
        }
    }

    It "returns a raw non-enveloped payload untouched (F-63)" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Get-RequestData { [pscustomobject]@{ '12345' = 'BackedUp' } }
            $conn = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            $r = Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/kcb'
            $r.'12345' | Should -Be 'BackedUp'
        }
    }

    It "returns an empty result for a status-only envelope (F-23)" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Get-RequestData { [pscustomobject]@{ ResponseCode = 200; Status = 'OK' } }
            $conn = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x' -Method PUT | Should -BeNullOrEmpty
        }
    }

    It "pages a multi-page collection to completion through the decoder (later pages included)" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            $script:calls = 0
            Mock Get-RequestData {
                $script:calls++
                # 3 pages of 100 for a 250-record collection; page size tracked via $skip.
                $count = if ($script:calls -lt 3) { 100 } else { 50 }
                [pscustomobject]@{ ResponseCode = 0; TotalRecords = 250; Result = @(1..$count) }
            }
            $conn = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            $r = @(Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x')
            $r.Count | Should -Be 250
            $script:calls | Should -Be 3
        }
    }

    It "ExtendedOutput still returns the envelope with the fully-merged Result (F-57)" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Get-RequestData { [pscustomobject]@{ ResponseCode = 0; TotalRecords = 150; Result = @(1..100) } }
            $conn = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            $r = Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x' -ExtendedOutput
            $r.TotalRecords | Should -Be 150
            @($r.Result).Count | Should -Be 200   # page 1 (100) + page 2 (100 from the same mock)
        }
    }
}
