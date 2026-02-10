$ModuleRoot = Split-Path -Path (Split-Path -Parent $PSScriptRoot)
$ModulePath = Join-Path -Path $ModuleRoot -ChildPath 'VSAModule.psd1'

Describe "VSAModule Code Quality" {
    
    Context "Directory Structure" {
        It "Module has PSM1 file" {
            Test-Path "$ModuleRoot\VSAModule.psm1" | Should Be $true
        }

        It "Module has PSD1 file" {
            Test-Path "$ModuleRoot\VSAModule.psd1" | Should Be $true
        }

        It "Module has public functions directory" {
            Test-Path "$ModuleRoot\public" | Should Be $true
        }

        It "Module has private functions directory" {
            Test-Path "$ModuleRoot\private" | Should Be $true
        }

        It "Module has help directory" {
            Test-Path "$ModuleRoot\en-US" | Should Be $true
        }

        It "Module has Tests directory" {
            Test-Path "$ModuleRoot\Tests" | Should Be $true
        }

        It "Module has README" {
            Test-Path "$ModuleRoot\README.md" | Should Be $true
        }

        It "Module has LICENSE" {
            Test-Path "$ModuleRoot\LICENSE.txt" | Should Be $true
        }
    }

    Context "Function File Naming" {
        It "Public functions follow Verb-Noun naming" {
            $PublicFunctions = Get-ChildItem -Path "$ModuleRoot\public" -Filter "*.ps1" -ErrorAction SilentlyContinue
            foreach ($func in $PublicFunctions) {
                $func.BaseName -match "^[A-Z][a-z]+-[A-Z][a-z]+" | Should Be $true
            }
        }

        It "Private functions follow Verb-Noun naming" {
            $PrivateFunctions = Get-ChildItem -Path "$ModuleRoot\private" -Filter "*.ps1" -ErrorAction SilentlyContinue
            foreach ($func in $PrivateFunctions) {
                $func.BaseName -match "^[A-Z][a-z]+-[A-Z][a-z]+" | Should Be $true
            }
        }

        It "Public function names start with approved verb" {
            $PublicFunctions = Get-ChildItem -Path "$ModuleRoot\public" -Filter "*.ps1" -ErrorAction SilentlyContinue
            $ValidVerbs = @('Get', 'New', 'Update', 'Remove', 'Set', 'Enable', 'Disable', 'Add', 'Copy', 'Rename', 'Publish', 'Start', 'Stop', 'Test', 'Send', 'Move', 'Invoke', 'Close', 'Open')
            foreach ($func in $PublicFunctions) {
                $verb = $func.BaseName.Split('-')[0]
                $ValidVerbs -contains $verb | Should Be $true
            }
        }
    }

    Context "Function Content Quality" {
        It "Public functions are not empty" {
            $PublicFunctions = Get-ChildItem -Path "$ModuleRoot\public" -Filter "*.ps1" -ErrorAction SilentlyContinue | Select-Object -First 5
            foreach ($func in $PublicFunctions) {
                (Get-Content -Path $func.FullName -Raw).Trim().Length | Should BeGreaterThan 0
            }
        }

        It "Private functions are not empty" {
            $PrivateFunctions = Get-ChildItem -Path "$ModuleRoot\private" -Filter "*.ps1" -ErrorAction SilentlyContinue
            foreach ($func in $PrivateFunctions) {
                (Get-Content -Path $func.FullName -Raw).Trim().Length | Should BeGreaterThan 0
            }
        }

        It "Functions have function declaration" {
            $PublicFunctions = Get-ChildItem -Path "$ModuleRoot\public" -Filter "*.ps1" -ErrorAction SilentlyContinue | Select-Object -First 5
            foreach ($func in $PublicFunctions) {
                (Get-Content -Path $func.FullName -Raw) -match "function\s+\w+-\w+" | Should Be $true
            }
        }
    }

    Context "Root Module Content" {
        It "Root module exists and has content" {
            $RootModule = Get-Content -Path "$ModuleRoot\VSAModule.psm1" -Raw
            $RootModule.Length | Should BeGreaterThan 0
        }

        It "Root module defines classes" {
            $RootModule = Get-Content -Path "$ModuleRoot\VSAModule.psm1" -Raw
            $RootModule -match "class\s+\w+" | Should Be $true
        }

        It "Root module has VSAConnection class" {
            $RootModule = Get-Content -Path "$ModuleRoot\VSAModule.psm1" -Raw
            $RootModule -match "class\s+VSAConnection" | Should Be $true
        }

        It "Root module has TrustAllCertsPolicy class" {
            $RootModule = Get-Content -Path "$ModuleRoot\VSAModule.psm1" -Raw
            $RootModule -match "class\s+TrustAllCertsPolicy" | Should Be $true
        }

        It "Root module defines URI mappings" {
            $RootModule = Get-Content -Path "$ModuleRoot\VSAModule.psm1" -Raw
            $RootModule -match '\$URISuffix.*=\s*@\{' | Should Be $true
        }

        It "Root module creates aliases dynamically" {
            $RootModule = Get-Content -Path "$ModuleRoot\VSAModule.psm1" -Raw
            $RootModule -match "New-Alias" | Should Be $true
        }
    }

    Context "Module Syntax Validation" {
        It "PSM1 file is valid PowerShell" {
            { [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path "$ModuleRoot\VSAModule.psm1" -Raw), [ref]$null) } | Should Not Throw
        }

        It "PSD1 file is valid PowerShell data" {
            { Import-PowerShellDataFile -Path "$ModuleRoot\VSAModule.psd1" -ErrorAction Stop } | Should Not Throw
        }

        It "Public functions are valid PowerShell" {
            Get-ChildItem -Path "$ModuleRoot\public" -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
                { [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $_.FullName -Raw), [ref]$null) } | Should Not Throw
            }
        }

        It "Private functions are valid PowerShell" {
            Get-ChildItem -Path "$ModuleRoot\private" -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
                { [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $_.FullName -Raw), [ref]$null) } | Should Not Throw
            }
        }
    }

    Context "Documentation Standards" {
        It "New-VSAConnection has comment-based help" {
            $Content = Get-Content -Path "$ModuleRoot\public\New-VSAConnection.ps1" -Raw
            $Content -match "<#" | Should Be $true
        }

        It "Help includes SYNOPSIS" {
            $Content = Get-Content -Path "$ModuleRoot\public\New-VSAConnection.ps1" -Raw
            $Content -match "\.SYNOPSIS" | Should Be $true
        }

        It "Help includes DESCRIPTION" {
            $Content = Get-Content -Path "$ModuleRoot\public\New-VSAConnection.ps1" -Raw
            $Content -match "\.DESCRIPTION" | Should Be $true
        }

        It "Help includes PARAMETER documentation" {
            $Content = Get-Content -Path "$ModuleRoot\public\New-VSAConnection.ps1" -Raw
            $Content -match "\.PARAMETER" | Should Be $true
        }

        It "Help includes EXAMPLE" {
            $Content = Get-Content -Path "$ModuleRoot\public\New-VSAConnection.ps1" -Raw
            $Content -match "\.EXAMPLE" | Should Be $true
        }
    }

    Context "Best Practices" {
        BeforeEach {
            Import-Module -Path $ModulePath -Force -ErrorAction SilentlyContinue
        }

        It "Module does not export wildcards" {
            $ManifestData = Import-PowerShellDataFile -Path $ModulePath
            $ManifestData.FunctionsToExport -contains "*" | Should Be $false
            $ManifestData.AliasesToExport -contains "*" | Should Be $false
        }

        It "Private functions not exposed in global scope" {
            Get-Item -Path Function:\Get-RequestData -ErrorAction SilentlyContinue | Should BeNullOrEmpty
            Get-Item -Path Function:\Invoke-VSARestMethod -ErrorAction SilentlyContinue | Should BeNullOrEmpty
        }

        It "Module version follows semantic versioning" {
            $ManifestData = Import-PowerShellDataFile -Path $ModulePath
            $ManifestData.ModuleVersion -match '^\d+\.\d+\.\d+' | Should Be $true
        }
    }

    Context "Organization Consistency" {
        It "Help file exists" {
            Test-Path "$ModuleRoot\en-US\VSAModule-help.xml" | Should Be $true
        }

        It "Help file is valid XML" {
            { [xml](Get-Content -Path "$ModuleRoot\en-US\VSAModule-help.xml" -Raw) } | Should Not Throw
        }

        It "Test files follow naming convention" {
            Get-ChildItem -Path "$ModuleRoot\Tests" -Filter "*Tests.ps1" -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }
}
