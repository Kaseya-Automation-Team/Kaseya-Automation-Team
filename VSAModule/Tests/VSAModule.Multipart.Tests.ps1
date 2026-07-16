BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force

    # A 256-byte payload covering every possible byte value, including bytes that are not valid
    # UTF-8 on their own (e.g. 0x80-0xFF) - this is exactly the data a naive byte->string->byte
    # round trip would corrupt.
    $script:PayloadBytes = [byte[]](0..255)
    $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "vsamodule-multipart-test-$([guid]::NewGuid()).bin"
    [System.IO.File]::WriteAllBytes($script:TempFile, $script:PayloadBytes)
}

AfterAll {
    Remove-Item -Path $script:TempFile -Force -ErrorAction SilentlyContinue
}

Describe "Multipart uploads build a byte[] body without corrupting binary data (T-6.5 / F-37)" {

    It "Publish-VSADocument embeds the file bytes verbatim" {
        InModuleScope VSAModule -Parameters @{ TempFile = $script:TempFile; PayloadBytes = $script:PayloadBytes } {
            param($TempFile, $PayloadBytes)
            $script:capturedBody = $null
            $script:capturedContentType = $null
            Mock Invoke-VSARestMethod {
                $script:capturedBody = $Body
                $script:capturedContentType = $ContentType
            }
            Publish-VSADocument -AgentId 10001 -SourceFilePath $TempFile | Out-Null

            # Note: never pipe an array into Should - PowerShell unrolls it and Should sees
            # individual elements instead of the array itself.
            ,$script:capturedBody | Should -BeOfType [byte[]]
            $script:capturedContentType | Should -Match 'multipart/form-data'

            [bool]$found = $false
            for ($i = 0; $i -le ($script:capturedBody.Length - $PayloadBytes.Length); $i++) {
                if ($script:capturedBody[$i] -ne $PayloadBytes[0]) { continue }
                [bool]$match = $true
                for ($j = 1; $j -lt $PayloadBytes.Length; $j++) {
                    if ($script:capturedBody[$i + $j] -ne $PayloadBytes[$j]) { $match = $false; break }
                }
                if ($match) { $found = $true; break }
            }
            $found | Should -BeTrue
        }
    }

    It "Publish-VSACustomExtensionFile embeds the file bytes verbatim" {
        InModuleScope VSAModule -Parameters @{ TempFile = $script:TempFile; PayloadBytes = $script:PayloadBytes } {
            param($TempFile, $PayloadBytes)
            $script:capturedBody = $null
            $script:capturedContentType = $null
            Mock Invoke-VSARestMethod {
                $script:capturedBody = $Body
                $script:capturedContentType = $ContentType
            }
            Publish-VSACustomExtensionFile -AgentId 10001 -SourceFilePath $TempFile | Out-Null

            ,$script:capturedBody | Should -BeOfType [byte[]]
            $script:capturedContentType | Should -Match 'multipart/form-data'

            [bool]$found = $false
            for ($i = 0; $i -le ($script:capturedBody.Length - $PayloadBytes.Length); $i++) {
                if ($script:capturedBody[$i] -ne $PayloadBytes[0]) { continue }
                [bool]$match = $true
                for ($j = 1; $j -lt $PayloadBytes.Length; $j++) {
                    if ($script:capturedBody[$i + $j] -ne $PayloadBytes[$j]) { $match = $false; break }
                }
                if ($match) { $found = $true; break }
            }
            $found | Should -BeTrue
        }
    }

    It "The transport (Invoke-VSARestMethod -> Get-RequestData) accepts a byte[] Body without coercing it to a string" {
        InModuleScope VSAModule -Parameters @{ PayloadBytes = $script:PayloadBytes } {
            param($PayloadBytes)
            $script:capturedBody = $null
            Mock Update-VSAConnection {}
            Mock Get-RequestData {
                $script:capturedBody = $Body
                [pscustomobject]@{ Result = @(); ResponseCode = 0; Status = 'OK' }
            }
            $conn = [VSAConnection]::new('https://vsa.example.com', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x' -Method PUT -Body $PayloadBytes -ContentType 'application/octet-stream' | Out-Null

            ,$script:capturedBody | Should -BeOfType [byte[]]
            $script:capturedBody.Length | Should -Be $PayloadBytes.Length
            [System.Convert]::ToBase64String($script:capturedBody) | Should -Be ([System.Convert]::ToBase64String($PayloadBytes))
        }
    }
}
