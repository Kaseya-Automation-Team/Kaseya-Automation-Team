$ModuleRoot = Split-Path -Path (Split-Path -Parent $PSScriptRoot)
$ModulePath = Join-Path -Path $ModuleRoot -ChildPath 'VSAModule.psd1'

Describe "VSAModule Import and Function Availability" {
    
    Context "Module Import" {
        It "Module imports without errors" {
            { Import-Module -Path $ModulePath -Force -ErrorAction Stop } | Should Not Throw
        }

        It "Module is loaded after import" {
            $Module = Get-Module -Name VSAModule -ErrorAction SilentlyContinue
            $Module | Should Not BeNullOrEmpty
        }

        It "Module type is Script" {
            $Module = Get-Module -Name VSAModule
            $Module.ModuleType | Should Be "Script"
        }
    }

    Context "Exported Functions Availability" {
        BeforeEach {
            Import-Module -Path $ModulePath -Force -ErrorAction SilentlyContinue
            $ManifestData = Import-PowerShellDataFile -Path $ModulePath
            $ExportedFunctions = $ManifestData.FunctionsToExport
        }

        It "Module exports more than 100 functions" {
            $ExportedFunctions.Count | Should BeGreaterThan 100
        }

        It "New-VSAConnection function is available" {
            Get-Command -Name "New-VSAConnection" -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "New-VSAConnection is a function" {
            (Get-Command -Name "New-VSAConnection").CommandType | Should Be "Function"
        }

        It "Private function Get-VSAItem is not accessible" {
            { Get-Command -Name "Get-VSAItem" -CommandType Function -ErrorAction Stop } | Should Throw
        }

        It "Private function Get-VSAItemById is not accessible" {
            { Get-Command -Name "Get-VSAItemById" -CommandType Function -ErrorAction Stop } | Should Throw
        }

        It "Private function Remove-VSAItem is not accessible" {
            { Get-Command -Name "Remove-VSAItem" -CommandType Function -ErrorAction Stop } | Should Throw
        }
    }

    Context "Exported Aliases Availability" {
        BeforeEach {
            Import-Module -Path $ModulePath -Force -ErrorAction SilentlyContinue
            $ManifestData = Import-PowerShellDataFile -Path $ModulePath
            $ExportedAliases = $ManifestData.AliasesToExport
        }

        It "Module exports more than 75 aliases" {
            $ExportedAliases.Count | Should BeGreaterThan 75
        }

        It "Get-VSAActivityType alias is available" {
            Get-Alias -Name "Get-VSAActivityType" -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Get-VSAAgent alias is available" {
            Get-Alias -Name "Get-VSAAgent" -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Get-VSAOrganization alias is available" {
            Get-Alias -Name "Get-VSAOrganization" -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Remove-VSAAsset alias is available" {
            Get-Alias -Name "Remove-VSAAsset" -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Remove-VSAOrganization alias is available" {
            Get-Alias -Name "Remove-VSAOrganization" -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }

    Context "Module Classes" {
        BeforeEach {
            Import-Module -Path $ModulePath -Force -ErrorAction SilentlyContinue
        }

        It "VSAConnection class exists" {
            { [VSAConnection] } | Should Not Throw
        }

        It "TrustAllCertsPolicy class exists" {
            { [TrustAllCertsPolicy] } | Should Not Throw
        }

        It "Can create VSAConnection instance" {
            { $conn = New-Object VSAConnection } | Should Not Throw
        }

        It "Can create TrustAllCertsPolicy instance" {
            { $policy = New-Object TrustAllCertsPolicy } | Should Not Throw
        }
    }

    Context "Help System Integration" {
        BeforeEach {
            Import-Module -Path $ModulePath -Force -ErrorAction SilentlyContinue
        }

        It "Help file exists" {
            $HelpPath = Join-Path -Path $ModuleRoot -ChildPath 'en-US\VSAModule-help.xml'
            Test-Path $HelpPath | Should Be $true
        }

        It "Help file is valid XML" {
            $HelpPath = Join-Path -Path $ModuleRoot -ChildPath 'en-US\VSAModule-help.xml'
            { [xml](Get-Content -Path $HelpPath -Raw) } | Should Not Throw
        }

        It "Can get help for New-VSAConnection" {
            $Help = Get-Help -Name "New-VSAConnection" -ErrorAction SilentlyContinue
            $Help | Should Not BeNullOrEmpty
        }
    }

    Context "Function File Organization" {
        It "Public folder contains function files" {
            $PublicFunctions = Get-ChildItem -Path "$ModuleRoot\public" -Filter "*.ps1" -ErrorAction SilentlyContinue
            $PublicFunctions | Should Not BeNullOrEmpty
        }

        It "Private folder contains helper functions" {
            $PrivateFunctions = Get-ChildItem -Path "$ModuleRoot\private" -Filter "*.ps1" -ErrorAction SilentlyContinue
            $PrivateFunctions | Should Not BeNullOrEmpty
        }

        It "Public functions include Get functions" {
            $GetFunctions = @(Get-ChildItem -Path "$ModuleRoot\public" -Filter "Get-*.ps1" -ErrorAction SilentlyContinue)
            $GetFunctions.Count | Should BeGreaterThan 0
        }

        It "Public functions include New functions" {
            $NewFunctions = @(Get-ChildItem -Path "$ModuleRoot\public" -Filter "New-*.ps1" -ErrorAction SilentlyContinue)
            $NewFunctions.Count | Should BeGreaterThan 0
        }

        It "Public functions include Update functions" {
            $UpdateFunctions = @(Get-ChildItem -Path "$ModuleRoot\public" -Filter "Update-*.ps1" -ErrorAction SilentlyContinue)
            $UpdateFunctions.Count | Should BeGreaterThan 0
        }

        It "Public functions include Remove functions" {
            $RemoveFunctions = @(Get-ChildItem -Path "$ModuleRoot\public" -Filter "Remove-*.ps1" -ErrorAction SilentlyContinue)
            $RemoveFunctions.Count | Should BeGreaterThan 0
        }
    }

    Context "Module Metadata" {
        BeforeEach {
            Import-Module -Path $ModulePath -Force -ErrorAction SilentlyContinue
            $Module = Get-Module -Name VSAModule
        }

        It "Module has version" {
            $Module.Version | Should Not BeNullOrEmpty
        }

        It "Module version is semantic" {
            $Module.Version.ToString() -match '^\d+\.\d+\.\d+' | Should Be $true
        }

        It "Module has author" {
            $Module.Author | Should Not BeNullOrEmpty
        }
    }
}
