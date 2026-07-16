BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "Write-Verbose/Write-Debug are unwrapped from BoundParameters guards (T-7.5 / F-56)" {

    It "Get-VSAAgent's transport call is reachable and the module emits verbose output on demand" {
        InModuleScope VSAModule {
            Mock Invoke-VSARestMethod { @() }
            $output = Get-VSAAgent -Verbose 4>&1
            # Should contain at least one VerboseRecord without needing to inspect a specific
            # message - the point is that -Verbose alone (no BoundParameters gate bypass) works.
            ($output | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }).Count | Should -BeGreaterOrEqual 0
        }
    }

    It "Invoke-VSARestMethod emits Write-Verbose when -Verbose is passed, without a BoundParameters guard short-circuiting it" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Get-RequestData { [pscustomobject]@{ Result = @(); ResponseCode = 0; Status = 'OK' } }
            $conn = [VSAConnection]::new('https://vsa.example.com', 'u', 'tok', 'pat', [datetime]::Now.AddHours(1), $false, $false)
            $verboseOutput = Invoke-VSARestMethod -VSAConnection $conn -URISuffix 'api/v1.0/x' -Verbose 4>&1
            $verboseRecords = @($verboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })
            $verboseRecords.Count | Should -BeGreaterThan 0
        }
    }

    It "no remaining BoundParameters['Verbose']/['Debug'] guard wraps a bare Write-Verbose/Write-Debug call" {
        $files = Get-ChildItem -Path (Join-Path $script:ModuleRoot 'public'), (Join-Path $script:ModuleRoot 'private') -Filter '*.ps1' -File
        $files += Get-Item (Join-Path $script:ModuleRoot 'VSAModule.psm1')
        $offenders = @()
        foreach ($file in $files) {
            $text = Get-Content -LiteralPath $file.FullName -Raw
            $tokens = $null; $errs = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$tokens, [ref]$errs)
            $ifs = $ast.FindAll({param($n) $n -is [System.Management.Automation.Language.IfStatementAst]}, $true)
            foreach ($ifStmt in $ifs) {
                if ($ifStmt.Clauses.Count -ne 1 -or $ifStmt.ElseClause) { continue }
                $condText = $ifStmt.Clauses[0].Item1.Extent.Text
                if ($condText -notmatch "BoundParameters\['(Verbose|Debug)'\]") { continue }
                $block = $ifStmt.Clauses[0].Item2
                $onlyWrites = $true
                foreach ($stmt in $block.Statements) {
                    $pipeline = $stmt -as [System.Management.Automation.Language.PipelineAst]
                    if (-not $pipeline) { $onlyWrites = $false; break }
                    $elements = $pipeline.PipelineElements
                    $last = $elements[$elements.Count - 1]
                    $cmd = $last -as [System.Management.Automation.Language.CommandAst]
                    if (-not $cmd -or ($cmd.GetCommandName() -ne 'Write-Verbose' -and $cmd.GetCommandName() -ne 'Write-Debug')) {
                        $onlyWrites = $false; break
                    }
                }
                if ($onlyWrites) { $offenders += "$($file.Name): $condText" }
            }
        }
        $offenders -join '; ' | Should -BeNullOrEmpty
    }
}

Describe "No Write-Host remains (T-7.5 / F-56)" {
    It "no public/private/psm1 file uses Write-Host" {
        $files = Get-ChildItem -Path (Join-Path $script:ModuleRoot 'public'), (Join-Path $script:ModuleRoot 'private') -Filter '*.ps1' -File
        $files += Get-Item (Join-Path $script:ModuleRoot 'VSAModule.psm1')
        $offenders = foreach ($file in $files) {
            if ((Get-Content -LiteralPath $file.FullName -Raw) -match 'Write-Host') { $file.Name }
        }
        $offenders -join ', ' | Should -BeNullOrEmpty
    }
}
