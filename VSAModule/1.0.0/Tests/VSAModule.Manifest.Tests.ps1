$ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\VSAModule.psd1'

Describe "VSAModule Manifest Validation" {
    
    It "Module manifest file exists" {
        Test-Path $ManifestPath | Should Be $true
    }

    Context "Manifest Contents" {
        BeforeEach {
            $Manifest = Test-ModuleManifest -Path $ManifestPath -ErrorAction SilentlyContinue
            $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
        }

        It "Has a valid manifest" {
            $Manifest | Should Not BeNullOrEmpty
        }

        It "Manifest is valid PowerShell" {
            { Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop } | Should Not Throw
        }

        It "Has module version" {
            $ManifestData.ModuleVersion | Should Not BeNullOrEmpty
        }

        It "Has author" {
            $ManifestData.Author | Should Not BeNullOrEmpty
        }

        It "Has description" {
            $ManifestData.Description | Should Not BeNullOrEmpty
        }

        It "Specifies PowerShell version 5.1" {
            $ManifestData.PowerShellVersion | Should Be "5.1"
        }

        It "Is a script module based on RootModule" {
            $ManifestData.RootModule | Should Not BeNullOrEmpty
        }

        It "Has RootModule" {
            $ManifestData.RootModule | Should Be "VSAModule.psm1"
        }
    }

    Context "Exports and Aliases" {
        BeforeEach {
            $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
        }

        It "Exports functions without wildcards" {
            $ManifestData.FunctionsToExport -contains "*" | Should Be $false
        }

        It "Exports aliases without wildcards" {
            $ManifestData.AliasesToExport -contains "*" | Should Be $false
        }

        It "Exports more than 100 functions" {
            $ManifestData.FunctionsToExport.Count | Should BeGreaterThan 100
        }

        It "Exports more than 75 aliases" {
            $ManifestData.AliasesToExport.Count | Should BeGreaterThan 75
        }

        It "Does not export private function Get-RequestData" {
            $ManifestData.FunctionsToExport -contains "Get-RequestData" | Should Be $false
        }

        It "Does not export private function Get-VSAItem" {
            $ManifestData.FunctionsToExport -contains "Get-VSAItem" | Should Be $false
        }

        It "Does not export private function Get-VSAItemById" {
            $ManifestData.FunctionsToExport -contains "Get-VSAItemById" | Should Be $false
        }

        It "Does not export private function Remove-VSAItem" {
            $ManifestData.FunctionsToExport -contains "Remove-VSAItem" | Should Be $false
        }
    }

    Context "Metadata Quality" {
        BeforeEach {
            $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
        }

        It "Has project URI" {
            $ManifestData.PrivateData.PSData.ProjectUri | Should Not BeNullOrEmpty
        }

        It "Has release notes" {
            $ManifestData.PrivateData.PSData.ReleaseNotes | Should Not BeNullOrEmpty
        }

        It "Has tags" {
            $ManifestData.PrivateData.PSData.Tags.Count | Should BeGreaterThan 0
        }

        It "Tags include Kaseya" {
            $ManifestData.PrivateData.PSData.Tags -contains "Kaseya" | Should Be $true
        }

        It "Tags include VSA" {
            $ManifestData.PrivateData.PSData.Tags -contains "VSA" | Should Be $true
        }
    }

    Context "File References" {
        BeforeEach {
            $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
            $ModuleRoot = Split-Path -Parent $ManifestPath
        }

        It "Root module file exists" {
            $RootModule = Join-Path -Path $ModuleRoot -ChildPath $ManifestData.RootModule
            Test-Path $RootModule | Should Be $true
        }

        It "Public directory exists" {
            Test-Path (Join-Path -Path $ModuleRoot -ChildPath "public") | Should Be $true
        }

        It "Private directory exists" {
            Test-Path (Join-Path -Path $ModuleRoot -ChildPath "private") | Should Be $true
        }

        It "Help directory exists" {
            Test-Path (Join-Path -Path $ModuleRoot -ChildPath "en-US") | Should Be $true
        }
    }
}
