$ModuleRoot = Split-Path -Path (Split-Path -Parent $PSScriptRoot)
$ModulePath = Join-Path -Path $ModuleRoot -ChildPath 'VSAModule.psd1'
$PublicPath = Join-Path -Path $ModuleRoot -ChildPath 'public'

BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    $script:ModulePath = Join-Path -Path $script:ModuleRoot -ChildPath 'VSAModule.psd1'
    $script:PublicPath = Join-Path -Path $script:ModuleRoot -ChildPath 'public'
    Import-Module $script:ModulePath -Force
    $script:Manifest = Import-PowerShellDataFile -Path $script:ModulePath
    $script:PublicFiles = Get-ChildItem -Path $script:PublicPath -Filter '*.ps1' -File
}

Describe "VSAModule Structure Regression" {

    Context "Manifest functions all exist" {
        It "Every name in FunctionsToExport resolves to a command in the module" {
            $missing = @()
            foreach ($name in $script:Manifest.FunctionsToExport) {
                if (-not (Get-Command -Name $name -Module VSAModule -ErrorAction SilentlyContinue)) {
                    $missing += $name
                }
            }
            $missing -join ', ' | Should -BeNullOrEmpty
        }
    }

    Context "Every public file is exported" {
        It "The function defined by each public/*.ps1 is in FunctionsToExport" {
            $notExported = @()
            foreach ($file in $script:PublicFiles) {
                if ($script:Manifest.FunctionsToExport -notcontains $file.BaseName) {
                    $notExported += $file.BaseName
                }
            }
            $notExported -join ', ' | Should -BeNullOrEmpty
        }
    }

    Context "File name equals defined function" {
        It "The first 'function <Name>' in each public file equals the file base name" {
            $mismatched = @()
            foreach ($file in $script:PublicFiles) {
                $content = Get-Content -Path $file.FullName -Raw
                $m = [regex]::Match($content, '(?im)^\s*function\s+([A-Za-z0-9\-]+)')
                $definedName = if ($m.Success) { $m.Groups[1].Value } else { '<none>' }
                if ($definedName -ne $file.BaseName) {
                    $mismatched += "$($file.Name): defines '$definedName'"
                }
            }
            $mismatched -join '; ' | Should -BeNullOrEmpty
        }
    }

    Context "Aliases reconcile" {
        It "The set of aliases created by module code equals AliasesToExport" {
            $created = (Get-Module VSAModule).ExportedAliases.Keys | Sort-Object
            $declared = $script:Manifest.AliasesToExport | Sort-Object
            ($created -join ', ') | Should -Be ($declared -join ', ')
        }
    }

    Context "Genuinely internal functions are NOT exported" {
        # F-20: Get-VSAItem/Get-VSAItemById/Remove-VSAItem were removed from this list -- they MUST
        # be exported so their ~89 aliases resolve on a normal import. The transport-layer helpers
        # below have no aliases pointing at them and correctly stay private.
        It "<Name> is not a command in the VSAModule" -ForEach @(
            @{ Name = 'Get-RequestData' }
            @{ Name = 'Invoke-VSARestMethod' }
            @{ Name = 'Update-VSAConnection' }
        ) {
            Get-Command -Name $Name -Module VSAModule -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }

    Context "No mandatory VSAConnection" {
        It "The VSAConnection parameter is not mandatory on any public function" {
            $mandatory = @()
            foreach ($name in $script:Manifest.FunctionsToExport) {
                $cmd = Get-Command -Name $name -Module VSAModule -ErrorAction SilentlyContinue
                if ($null -eq $cmd) { continue }
                $param = $cmd.Parameters['VSAConnection']
                if ($null -eq $param) { continue }
                foreach ($set in $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }) {
                    if ($set.Mandatory) { $mandatory += $name }
                }
            }
            $mandatory -join ', ' | Should -BeNullOrEmpty
        }
    }

    Context "Clean import" {
        It "Import-Module writes zero warnings" {
            Import-Module $script:ModulePath -Force -WarningVariable w -WarningAction SilentlyContinue | Out-Null
            $w.Count | Should -Be 0
        }
    }

    Context "Encoding (F-59 / T-8.2)" {
        It "Every .ps1 file containing a non-ASCII byte begins with a UTF-8 BOM" {
            $badFiles = @()
            $allPs1 = Get-ChildItem -Path $script:ModuleRoot -Filter '*.ps1' -Recurse -File |
                Where-Object { $_.FullName -notmatch '[\\/](Tests|Tools)[\\/]' }
            foreach ($file in $allPs1) {
                $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
                $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
                $body = if ($hasBom) { $bytes[3..($bytes.Length - 1)] } else { $bytes }
                $hasNonAscii = $body | Where-Object { $_ -gt 0x7F } | Select-Object -First 1
                if ($hasNonAscii -and -not $hasBom) {
                    $badFiles += $file.FullName.Substring($script:ModuleRoot.Length + 1)
                }
            }
            $badFiles -join ', ' | Should -BeNullOrEmpty
        }
    }
}
