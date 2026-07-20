BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "ConvertFrom-VSAScExport parses the VSA 9 agent-procedure XML (F-72)" {

    BeforeAll {
        # A minimal but faithful ScExport document (namespace + Records + Procedure attributes,
        # including the folderId the field survey confirmed, and a <Body> that must be ignored).
        $script:Xml = @'
<?xml version="1.0" encoding="utf-8"?>
<ScExport xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.kaseya.com/vsa/2008/12/Scripting">
  <Records name="TotalRecords" totalRecords="2" startingRecordIndex="0" currentNumRecords="2" />
  <Procedure name="Proc A" treePres="3" id="659091963" folderId="546051318732114" treeFullPath="Core\Windows\A" shared="true">
    <Body description="ignore me"><Statement name="GetVariable" /></Body>
  </Procedure>
  <Procedure name="Proc B" treePres="2" id="12" folderId="34" treeFullPath="Core\B" shared="false" />
</ScExport>
'@
    }

    It "reads the paging totals from <Records>" {
        InModuleScope VSAModule -Parameters @{ xml = $script:Xml } {
            param($xml)
            $r = ConvertFrom-VSAScExport -Body $xml
            $r.TotalRecords | Should -Be 2
            $r.StartingRecordIndex | Should -Be 0
            $r.CurrentNumRecords | Should -Be 2
        }
    }

    It "projects one object per <Procedure> with the summary fields, not the body" {
        InModuleScope VSAModule -Parameters @{ xml = $script:Xml } {
            param($xml)
            $r = ConvertFrom-VSAScExport -Body $xml
            @($r.Procedures).Count | Should -Be 2
            $a = $r.Procedures[0]
            $a.Id       | Should -Be '659091963'
            $a.Name     | Should -Be 'Proc A'
            $a.Path     | Should -Be 'Core\Windows\A'
            $a.FolderId | Should -Be '546051318732114'
            $a.TreePres | Should -Be '3'
            # No Body leaks into the projection.
            $a.PSObject.Properties.Name | Should -Not -Contain 'Body'
        }
    }

    It "keeps ids as strings (folderId overflows Int32) and Shared as a real boolean" {
        InModuleScope VSAModule -Parameters @{ xml = $script:Xml } {
            param($xml)
            $r = ConvertFrom-VSAScExport -Body $xml
            $r.Procedures[0].Id       | Should -BeOfType ([string])
            $r.Procedures[0].FolderId | Should -BeOfType ([string])
            $r.Procedures[0].Shared   | Should -BeOfType ([bool])
            $r.Procedures[0].Shared   | Should -BeTrue
            $r.Procedures[1].Shared   | Should -BeFalse
        }
    }
}

Describe "Get-VSAAPList fetches the whole XML procedure tree by paging" {

    It "pages via $skip/$top until TotalRecords are retrieved, and accumulates every procedure" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            # Two pages of a 3-record tree: skip 0 -> two procedures, skip 2 -> the last one.
            Mock Invoke-VSAHttp {
                $skip = 0
                if ($Uri -match '(?:\$|%24)skip=(\d+)') { $skip = [int]$Matches[1] }
                $body = if ($skip -eq 0) {
@'
<ScExport xmlns="http://www.kaseya.com/vsa/2008/12/Scripting">
  <Records totalRecords="3" startingRecordIndex="0" currentNumRecords="2" />
  <Procedure id="1" name="A" treeFullPath="p\A" folderId="10" shared="true" treePres="3" />
  <Procedure id="2" name="B" treeFullPath="p\B" folderId="11" shared="false" treePres="3" />
</ScExport>
'@
                } else {
@'
<ScExport xmlns="http://www.kaseya.com/vsa/2008/12/Scripting">
  <Records totalRecords="3" startingRecordIndex="2" currentNumRecords="1" />
  <Procedure id="3" name="C" treeFullPath="p\C" folderId="12" shared="true" treePres="3" />
</ScExport>
'@
                }
                [pscustomobject]@{ StatusCode = 200; Body = $body }
            }

            $conn = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            $procs = @(Get-VSAAPList -VSAConnection $conn -RecordsPerPage 2)

            $procs.Count | Should -Be 3
            ($procs.Id | Sort-Object) -join ',' | Should -Be '1,2,3'
            Should -Invoke Invoke-VSAHttp -Times 2 -Exactly
        }
    }

    It "makes exactly one request for a tree that fits in a single page" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Invoke-VSAHttp {
                [pscustomobject]@{ StatusCode = 200; Body = @'
<ScExport xmlns="http://www.kaseya.com/vsa/2008/12/Scripting">
  <Records totalRecords="1" startingRecordIndex="0" currentNumRecords="1" />
  <Procedure id="9" name="Solo" treeFullPath="p\Solo" folderId="1" shared="false" treePres="1" />
</ScExport>
'@ }
            }
            $conn = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            (@(Get-VSAAPList -VSAConnection $conn)).Count | Should -Be 1
            Should -Invoke Invoke-VSAHttp -Times 1 -Exactly
        }
    }
}

Describe "Get-VSAAPList is a dedicated XML function, not a JSON dispatcher alias (F-72)" {

    It "is exported as a Function" {
        (Get-Command Get-VSAAPList).CommandType | Should -Be 'Function'
    }

    It "is in FunctionsToExport, not AliasesToExport" {
        $m = Import-PowerShellDataFile (Join-Path $script:ModuleRoot 'VSAModule.psd1')
        $m.FunctionsToExport | Should -Contain 'Get-VSAAPList'
        $m.AliasesToExport   | Should -Not -Contain 'Get-VSAAPList'
    }

    It "is NOT in the JSON dispatcher endpoint map" {
        InModuleScope VSAModule {
            $URISuffixGetMap.ContainsKey('Get-VSAAPList') | Should -BeFalse -Because 'the JSON read path cannot parse its XML body'
        }
    }
}

Describe "Get-VSAAPList routes through the shared read engine with the XML decoder (inherits F-77/retry/progress)" {

    It "calls Invoke-VSARestMethod with the ScExport decoder and the proclist endpoint" {
        InModuleScope VSAModule {
            # Capture the bound values directly, not the $PSBoundParameters reference (Pester reuses
            # and clears that dictionary after the mock returns).
            $script:decoder = $null; $script:suffix = $null
            Mock Invoke-VSARestMethod { $script:decoder = $Decoder; $script:suffix = $URISuffix }
            Get-VSAAPList | Out-Null
            $script:decoder | Should -Be 'ConvertFrom-VSAScExportResponse'
            $script:suffix  | Should -Be 'api/v1.0/automation/agentprocs/proclist'
        }
    }

    It "forwards an explicit VSAConnection through to the engine" {
        InModuleScope VSAModule {
            $script:conn = $null
            Mock Invoke-VSARestMethod { $script:conn = $VSAConnection }
            $c = [VSAConnection]::new('https://h', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            Get-VSAAPList -VSAConnection $c | Out-Null
            $script:conn                | Should -Not -BeNullOrEmpty
            "$($script:conn.URI)"       | Should -Be 'https://h'
        }
    }

    It "forwards -Parallel (and throttle) to the engine alongside the ScExport decoder (A)" {
        InModuleScope VSAModule {
            $script:par = $null; $script:dec = $null; $script:thr = $null
            Mock Invoke-VSARestMethod { $script:par = [bool]$Parallel; $script:dec = $Decoder; $script:thr = $ThrottleLimit }
            Get-VSAAPList -Parallel -ThrottleLimit 4 | Out-Null
            $script:par | Should -BeTrue
            $script:dec | Should -Be 'ConvertFrom-VSAScExportResponse'
            $script:thr | Should -Be 4
        }
    }

    It "does NOT forward -Parallel when it is not requested (stays sequential)" {
        InModuleScope VSAModule {
            $script:par = $null
            Mock Invoke-VSARestMethod { $script:par = [bool]$Parallel }
            Get-VSAAPList | Out-Null
            $script:par | Should -BeFalse
        }
    }

    It "no longer hand-rolls its own transport: it does not call Invoke-VSAHttp directly" {
        # The F-77 gap existed precisely because the old implementation called Invoke-VSAHttp below the
        # session-recovery wrapper. Routing through Invoke-VSARestMethod is what fixes that by
        # construction; guard against a regression back to a direct transport call.
        InModuleScope VSAModule {
            Mock Invoke-VSARestMethod {}
            Mock Invoke-VSAHttp { throw 'Get-VSAAPList must not call Invoke-VSAHttp directly' }
            { Get-VSAAPList } | Should -Not -Throw
            Should -Invoke Invoke-VSAHttp -Times 0 -Exactly
        }
    }
}
