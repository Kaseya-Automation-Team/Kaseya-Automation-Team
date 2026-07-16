BeforeAll {
    $ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    $ModulePath = Join-Path -Path $ModuleRoot -ChildPath 'VSAModule.psd1'
}

Describe "HTTP transport assembly is loaded at import (Windows PowerShell 5.1 regression)" {

    # Regression guard for a real 5.1 failure: New-VSAConnection threw
    #   "Unable to find type [System.Net.Http.HttpClient]"
    # The module transports over HttpClient (F-67). On .NET Core that assembly is part of the shared
    # framework, so the bug is invisible there; on .NET Framework it is a separate assembly that is
    # not loaded by default. It cannot be loaded lazily inside the transport functions: PowerShell
    # compiles a function body on first invocation and resolves every type literal in it at that
    # point, so an Add-Type in the same function always runs too late.

    It "System.Net.Http.HttpClient resolves once the module is imported" {
        Import-Module $ModulePath -Force
        ('System.Net.Http.HttpClient' -as [type]) | Should -Not -BeNullOrEmpty
    }

    It "the assembly is loaded at module load, not lazily inside a transport function" {
        # The source guard is what actually protects 5.1, since on Core the first assertion above
        # would pass even with the bug present.
        $psm1 = Get-Content (Join-Path $ModuleRoot 'VSAModule.psm1') -Raw
        $psm1 | Should -Match 'Add-Type\s+-AssemblyName\s+System\.Net\.Http'

        foreach ($file in Get-ChildItem (Join-Path $ModuleRoot 'private') -Filter '*.ps1') {
            (Get-Content $file.FullName -Raw) |
                Should -Not -Match 'Add-Type\s+-AssemblyName\s+System\.Net\.Http' -Because "$($file.Name) must rely on the module-load Add-Type; a lazy one is too late to satisfy its own type literals"
        }
    }
}

Describe "VSAModule Import and Function Availability" {

    Context "Module Import" {
        It "Module imports without errors" {
            { Import-Module $ModulePath -Force -ErrorAction Stop } | Should -Not -Throw
        }

        It "Module is loaded after import" {
            $Module = Get-Module -Name VSAModule
            $Module | Should -Not -BeNullOrEmpty
        }

        It "Module type is Script" {
            $Module = Get-Module -Name VSAModule
            $Module.ModuleType | Should -Be "Script"
        }
    }

    Context "Exported Functions Availability" {
        BeforeEach {
            Import-Module $ModulePath -Force
            $ManifestData = Import-PowerShellDataFile -Path $ModulePath
            $ExportedFunctions = $ManifestData.FunctionsToExport
        }

        It "Module exports more than 100 functions" {
            $ExportedFunctions.Count | Should -BeGreaterThan 100
        }

        It "New-VSAConnection function is available" {
            Get-Command -Name "New-VSAConnection" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "New-VSAConnection is a function" {
            (Get-Command -Name "New-VSAConnection").CommandType | Should -Be "Function"
        }

        # F-20: these dispatch wrappers must be reachable from the caller's scope, else their
        # aliases (~89 commands) cannot resolve. Get-RequestData stays private (no alias targets it).
        It "Dispatch wrapper Get-VSAItem is accessible (its aliases resolve to it)" {
            { Get-Command -Name "Get-VSAItem" -CommandType Function -ErrorAction Stop } | Should -Not -Throw
        }

        It "Dispatch wrapper Get-VSAItemById is accessible" {
            { Get-Command -Name "Get-VSAItemById" -CommandType Function -ErrorAction Stop } | Should -Not -Throw
        }

        It "Dispatch wrapper Remove-VSAItem is accessible" {
            { Get-Command -Name "Remove-VSAItem" -CommandType Function -ErrorAction Stop } | Should -Not -Throw
        }

        It "Genuinely private helper Get-RequestData is NOT accessible" {
            { Get-Command -Name "Get-RequestData" -CommandType Function -ErrorAction Stop } | Should -Throw
        }

        # Regression guard for F-20: an exported alias must resolve to a real command on a NORMAL
        # import (not InModuleScope). This is the coverage whose absence let the D-3 break ship.
        It "Alias-dispatched commands resolve to a command on a normal import" {
            foreach ($name in 'Get-VSATenant','Get-VSAAgentPackage','Get-VSAAgentSettings','Remove-VSAAsset') {
                $cmd = Get-Command -Name $name -ErrorAction Stop
                $cmd.ResolvedCommand | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Exported Aliases Availability" {
        BeforeEach {
            Import-Module $ModulePath -Force
            $ManifestData = Import-PowerShellDataFile -Path $ModulePath
            $ExportedAliases = $ManifestData.AliasesToExport
        }

        It "Module exports more than 75 aliases" {
            $ExportedAliases.Count | Should -BeGreaterThan 75
        }

        It "Get-VSAActivityType alias is available" {
            Get-Alias -Name "Get-VSAActivityType" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Get-VSATenants alias is available" {
            Get-Alias -Name "Get-VSATenants" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Get-VSAAgentNote alias is available" {
            Get-Alias -Name "Get-VSAAgentNote" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Remove-VSAAsset alias is available" {
            Get-Alias -Name "Remove-VSAAsset" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Remove-VSAOrganization alias is available" {
            Get-Alias -Name "Remove-VSAOrganization" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Module Classes" {
        BeforeEach {
            Import-Module $ModulePath -Force
        }

        It "VSAConnection class exists" {
            { [VSAConnection] } | Should -Not -Throw
        }

        It "Can create VSAConnection instance" {
            { $conn = New-Object VSAConnection } | Should -Not -Throw
        }

        It "TrustAllCertsPolicy class is removed (F-26)" {
            ('TrustAllCertsPolicy' -as [type]) | Should -BeNullOrEmpty
        }
    }

    Context "Help System Integration" {
        BeforeEach {
            Import-Module $ModulePath -Force
        }

        It "Comment-based help is available for exported functions" {
            $Help = Get-Help -Name "Get-VSAAgent" -ErrorAction SilentlyContinue
            $Help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "Can get help for New-VSAConnection" {
            $Help = Get-Help -Name "New-VSAConnection" -ErrorAction SilentlyContinue
            $Help | Should -Not -BeNullOrEmpty
        }
    }

    Context "Function File Organization" {
        It "Public folder contains function files" {
            $PublicFunctions = Get-ChildItem -Path (Join-Path $ModuleRoot 'public') -Filter "*.ps1" -ErrorAction SilentlyContinue
            $PublicFunctions | Should -Not -BeNullOrEmpty
        }

        It "Private folder contains helper functions" {
            $PrivateFunctions = Get-ChildItem -Path (Join-Path $ModuleRoot 'private') -Filter "*.ps1" -ErrorAction SilentlyContinue
            $PrivateFunctions | Should -Not -BeNullOrEmpty
        }

        It "Public functions include Get functions" {
            $GetFunctions = @(Get-ChildItem -Path (Join-Path $ModuleRoot 'public') -Filter "Get-*.ps1" -ErrorAction SilentlyContinue)
            $GetFunctions.Count | Should -BeGreaterThan 0
        }

        It "Public functions include New functions" {
            $NewFunctions = @(Get-ChildItem -Path (Join-Path $ModuleRoot 'public') -Filter "New-*.ps1" -ErrorAction SilentlyContinue)
            $NewFunctions.Count | Should -BeGreaterThan 0
        }

        It "Public functions include Update functions" {
            $UpdateFunctions = @(Get-ChildItem -Path (Join-Path $ModuleRoot 'public') -Filter "Update-*.ps1" -ErrorAction SilentlyContinue)
            $UpdateFunctions.Count | Should -BeGreaterThan 0
        }

        It "Public functions include Remove functions" {
            $RemoveFunctions = @(Get-ChildItem -Path (Join-Path $ModuleRoot 'public') -Filter "Remove-*.ps1" -ErrorAction SilentlyContinue)
            $RemoveFunctions.Count | Should -BeGreaterThan 0
        }
    }

    Context "Module Metadata" {
        BeforeEach {
            Import-Module $ModulePath -Force
            $Module = Get-Module -Name VSAModule
        }

        It "Module has version" {
            $Module.Version | Should -Not -BeNullOrEmpty
        }

        It "Module version is semantic" {
            $Module.Version.ToString() -match '^\d+\.\d+\.\d+' | Should -Be $true
        }

        It "Module has author" {
            $Module.Author | Should -Not -BeNullOrEmpty
        }
    }
}
