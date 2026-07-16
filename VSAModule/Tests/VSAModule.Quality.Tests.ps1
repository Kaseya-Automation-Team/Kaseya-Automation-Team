BeforeAll {
    $ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    $ModulePath = Join-Path -Path $ModuleRoot -ChildPath 'VSAModule.psd1'
    $PublicPath = Join-Path -Path $ModuleRoot -ChildPath 'public'
    $PrivatePath = Join-Path -Path $ModuleRoot -ChildPath 'private'
}

Describe "VSAModule Code Quality" {

    Context "Directory Structure" {
        It "Module has PSM1 file" {
            Test-Path (Join-Path $ModuleRoot 'VSAModule.psm1') | Should -Be $true
        }

        It "Module has PSD1 file" {
            Test-Path (Join-Path $ModuleRoot 'VSAModule.psd1') | Should -Be $true
        }

        It "Module has public functions directory" {
            Test-Path $PublicPath | Should -Be $true
        }

        It "Module has private functions directory" {
            Test-Path $PrivatePath | Should -Be $true
        }

        It "Module has Tests directory" {
            Test-Path (Join-Path $ModuleRoot 'Tests') | Should -Be $true
        }

        It "Module has README" {
            Test-Path (Join-Path $ModuleRoot 'README.md') | Should -Be $true
        }

        It "Module has LICENSE" {
            Test-Path (Join-Path $ModuleRoot 'LICENSE.txt') | Should -Be $true
        }
    }

    Context "Function File Naming" {
        It "Public functions follow Verb-VSANoun naming" {
            $PublicFunctions = Get-ChildItem -Path $PublicPath -Filter "*.ps1" -ErrorAction SilentlyContinue
            foreach ($func in $PublicFunctions) {
                $func.BaseName -match "^[A-Z][a-z]+-VSA[A-Za-z0-9]+$" | Should -Be $true
            }
        }

        It "Private function files follow Verb-Noun naming" {
            # Only files that actually define a function are held to Verb-Noun; data-only files
            # (e.g. VSAEndpointMaps.ps1, which holds the dispatch/id hashtables) are exempt.
            $PrivateFunctions = Get-ChildItem -Path $PrivatePath -Filter "*.ps1" -ErrorAction SilentlyContinue |
                Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match '(?im)^\s*function\s+' }
            foreach ($func in $PrivateFunctions) {
                $func.BaseName -match "^[A-Z][a-z]+-[A-Z][A-Za-z0-9]+$" | Should -Be $true
            }
        }

        It "Public function names start with approved verb" {
            $PublicFunctions = Get-ChildItem -Path $PublicPath -Filter "*.ps1" -ErrorAction SilentlyContinue
            # Validate against PowerShell's actual approved-verb set (Get-Verb) rather than a
            # hand-maintained subset that silently drifts as new (approved) verbs are adopted.
            $ValidVerbs = (Get-Verb).Verb
            foreach ($func in $PublicFunctions) {
                $verb = $func.BaseName.Split('-')[0]
                $ValidVerbs -contains $verb | Should -Be $true -Because $func.BaseName
            }
        }
    }

    Context "Function Content Quality" {
        It "Public functions are not empty" {
            $PublicFunctions = Get-ChildItem -Path $PublicPath -Filter "*.ps1" -ErrorAction SilentlyContinue | Select-Object -First 5
            foreach ($func in $PublicFunctions) {
                (Get-Content -Path $func.FullName -Raw).Trim().Length | Should -BeGreaterThan 0
            }
        }

        It "Private functions are not empty" {
            $PrivateFunctions = Get-ChildItem -Path $PrivatePath -Filter "*.ps1" -ErrorAction SilentlyContinue
            foreach ($func in $PrivateFunctions) {
                (Get-Content -Path $func.FullName -Raw).Trim().Length | Should -BeGreaterThan 0
            }
        }

        It "Functions have function declaration" {
            $PublicFunctions = Get-ChildItem -Path $PublicPath -Filter "*.ps1" -ErrorAction SilentlyContinue | Select-Object -First 5
            foreach ($func in $PublicFunctions) {
                (Get-Content -Path $func.FullName -Raw) -match "function\s+\w+-\w+" | Should -Be $true
            }
        }
    }

    Context "Root Module Content" {
        It "Root module exists and has content" {
            $RootModule = Get-Content -Path (Join-Path $ModuleRoot 'VSAModule.psm1') -Raw
            $RootModule.Length | Should -BeGreaterThan 0
        }

        It "Root module defines classes" {
            $RootModule = Get-Content -Path (Join-Path $ModuleRoot 'VSAModule.psm1') -Raw
            $RootModule -match "class\s+\w+" | Should -Be $true
        }

        It "Root module has VSAConnection class" {
            $RootModule = Get-Content -Path (Join-Path $ModuleRoot 'VSAModule.psm1') -Raw
            $RootModule -match "class\s+VSAConnection" | Should -Be $true
        }

        It "Module defines URI mappings (in the dot-sourced maps file)" {
            # The URI/id maps were extracted from the .psm1 into private/VSAEndpointMaps.ps1 for
            # readability; they are dot-sourced into module scope by the loader.
            $Maps = Get-Content -Path (Join-Path $ModuleRoot 'private/VSAEndpointMaps.ps1') -Raw
            $Maps -match '\$(?:script:)?URISuffix.*=\s*@\{' | Should -Be $true
        }

        It "Root module creates aliases dynamically" {
            $RootModule = Get-Content -Path (Join-Path $ModuleRoot 'VSAModule.psm1') -Raw
            $RootModule -match "New-Alias" | Should -Be $true
        }
    }

    Context "Module Syntax Validation" {
        It "PSM1 file is valid PowerShell" {
            { [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path (Join-Path $ModuleRoot 'VSAModule.psm1') -Raw), [ref]$null) } | Should -Not -Throw
        }

        It "PSD1 file is valid PowerShell data" {
            { Import-PowerShellDataFile -Path (Join-Path $ModuleRoot 'VSAModule.psd1') -ErrorAction Stop } | Should -Not -Throw
        }

        It "Public functions are valid PowerShell" {
            Get-ChildItem -Path $PublicPath -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
                { [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $_.FullName -Raw), [ref]$null) } | Should -Not -Throw
            }
        }

        It "Private functions are valid PowerShell" {
            Get-ChildItem -Path $PrivatePath -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
                { [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $_.FullName -Raw), [ref]$null) } | Should -Not -Throw
            }
        }
    }

    Context "Documentation Standards" {
        It "New-VSAConnection has comment-based help" {
            $Content = Get-Content -Path (Join-Path $ModuleRoot 'VSAModule.psm1') -Raw
            $Content -match "<#" | Should -Be $true
        }

        It "Help includes SYNOPSIS" {
            $Content = Get-Content -Path (Join-Path $ModuleRoot 'VSAModule.psm1') -Raw
            $Content -match "\.SYNOPSIS" | Should -Be $true
        }

        It "Help includes DESCRIPTION" {
            $Content = Get-Content -Path (Join-Path $ModuleRoot 'VSAModule.psm1') -Raw
            $Content -match "\.DESCRIPTION" | Should -Be $true
        }

        It "Help includes PARAMETER documentation" {
            $Content = Get-Content -Path (Join-Path $ModuleRoot 'VSAModule.psm1') -Raw
            $Content -match "\.PARAMETER" | Should -Be $true
        }

        It "Help includes EXAMPLE" {
            $Content = Get-Content -Path (Join-Path $ModuleRoot 'VSAModule.psm1') -Raw
            $Content -match "\.EXAMPLE" | Should -Be $true
        }
    }

    Context "Best Practices" {
        BeforeEach {
            Import-Module $ModulePath -Force
        }

        It "Module does not export wildcards" {
            $ManifestData = Import-PowerShellDataFile -Path $ModulePath
            $ManifestData.FunctionsToExport -contains "*" | Should -Be $false
            $ManifestData.AliasesToExport -contains "*" | Should -Be $false
        }

        It "Private functions not exposed in global scope" {
            Get-Item -Path Function:\Get-RequestData -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            Get-Item -Path Function:\Invoke-VSARestMethod -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It "Module version follows semantic versioning" {
            $ManifestData = Import-PowerShellDataFile -Path $ModulePath
            $ManifestData.ModuleVersion -match '^\d+\.\d+\.\d+' | Should -Be $true
        }
    }

    Context "Organization Consistency" {
        It "Test files follow naming convention" {
            Get-ChildItem -Path (Join-Path $ModuleRoot 'Tests') -Filter "*Tests.ps1" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "The module version has a single source of truth: the manifest" {

    # The version used to be restated by hand in the psm1 banner and in New-VSAConnection's .NOTES,
    # and 9 functions carried their own private ".NOTES Version" (seven said 1.0.0, one 1.1.0, one
    # 1.2.0) that tracked nothing and had already gone stale. A per-function version is meaningless
    # in a module that ships as one unit, and every hand-maintained copy is a future lie.
    # ModuleVersion in the .psd1 is the only place the version may live.

    It "declares ModuleVersion in the manifest" {
        (Import-PowerShellDataFile "$ModuleRoot/VSAModule.psd1").ModuleVersion | Should -Match '^\d+\.\d+\.\d+$'
    }

    It "does not restate a version anywhere in shipped code" {
        $offenders = @()
        $files = @(Get-ChildItem "$ModuleRoot/public", "$ModuleRoot/private" -Filter *.ps1 -File) +
                 @(Get-Item "$ModuleRoot/VSAModule.psm1")
        foreach ($f in $files) {
            $hits = Select-String -Path $f.FullName -Pattern '(?m)^\s*Version\s+\d+\.\d+\.\d+\s*$'
            foreach ($h in $hits) { $offenders += "$($f.Name):$($h.LineNumber)" }
        }
        $offenders | Should -BeNullOrEmpty -Because 'the version belongs only in the .psd1 ModuleVersion; hand-maintained copies rot'
    }

    It "exposes the manifest version at runtime, which is how callers should read it" {
        Import-Module "$ModuleRoot/VSAModule.psd1" -Force
        $expected = (Import-PowerShellDataFile "$ModuleRoot/VSAModule.psd1").ModuleVersion
        (Get-Module VSAModule).Version.ToString() | Should -Be $expected
    }
}

Describe "ShouldProcess discipline is complete and uniform across the write surface" {

    BeforeAll {
        Import-Module "$ModuleRoot/VSAModule.psd1" -Force
        # Read-only despite their verbs: Test-VSASSL performs a GET diagnostic.
        $script:ReadOnlyExceptions = @('Test-VSASSL')
    }

    It "every mutating public function declares SupportsShouldProcess" {
        $offenders = @()
        foreach ($f in Get-ChildItem "$ModuleRoot/public" -Filter *.ps1) {
            if ($f.BaseName -like 'Get-*' -or $f.BaseName -in $script:ReadOnlyExceptions) { continue }
            if ((Get-Content $f.FullName -Raw) -notmatch 'SupportsShouldProcess') { $offenders += $f.BaseName }
        }
        $offenders | Should -BeNullOrEmpty -Because 'a mutating cmdlet without -WhatIf support is a safety gap; Copy-VSAOrgStructure/Copy-VSAMGStructure were the last two (fixed)'
    }

    It "the Copy-* orchestrators gate creation with a direct ShouldProcess call" {
        # They compose public cmdlets rather than the write chokepoint, so the central -Caller
        # pattern does not cover them; they must call ShouldProcess themselves. The gate wraps the
        # whole create-and-verify block: under -WhatIf the 60s read-back wait must not spin.
        foreach ($n in @('Copy-VSAOrgStructure', 'Copy-VSAMGStructure')) {
            $src = Get-Content "$ModuleRoot/public/$n.ps1" -Raw
            $src | Should -Match '\$PSCmdlet\.ShouldProcess\(' -Because "$n mass-creates on a destination VSA"
        }
    }

    It "every delegating write cmdlet carries the justified PSShouldProcess suppression" {
        # The IDE analyzer cannot see that ShouldProcess is invoked centrally by
        # Invoke-VSAWriteRequest via -Caller; the justification attribute makes the tooling agree
        # with the architecture and documents the pattern in place. A new write cmdlet that
        # delegates must carry it too.
        $offenders = @()
        foreach ($f in Get-ChildItem "$ModuleRoot/public" -Filter *.ps1) {
            $src = Get-Content $f.FullName -Raw
            if ($src -notmatch 'SupportsShouldProcess') { continue }
            if ($src -match '\$PSCmdlet\.ShouldProcess\(') { continue }   # calls it directly
            if ($src -notmatch "SuppressMessageAttribute\('PSShouldProcess'") { $offenders += $f.BaseName }
        }
        $offenders | Should -BeNullOrEmpty
    }
}
