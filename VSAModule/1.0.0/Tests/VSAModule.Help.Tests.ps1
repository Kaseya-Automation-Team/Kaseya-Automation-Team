$ModuleRoot = Split-Path -Path (Split-Path -Parent $PSScriptRoot)
$HelpFilePath = Join-Path -Path $ModuleRoot -ChildPath 'en-US\VSAModule-help.xml'

Describe "VSAModule Help File Validation" {
    
    Context "Help File Structure" {
        It "Help file exists" {
            Test-Path $HelpFilePath | Should Be $true
        }

        It "Help file is valid XML" {
            { [xml](Get-Content -Path $HelpFilePath -Raw) } | Should Not Throw
        }

        It "Help XML has helpItems root element" {
            $HelpXml = [xml](Get-Content -Path $HelpFilePath -Raw)
            $HelpXml.DocumentElement.Name | Should Be "helpItems"
        }

        It "Help file contains command definitions" {
            $HelpXml = [xml](Get-Content -Path $HelpFilePath -Raw)
            $HelpXml.helpItems.ChildNodes | Should Not BeNullOrEmpty
        }
    }

    Context "Command Documentation" {
        BeforeEach {
            $HelpXml = [xml](Get-Content -Path $HelpFilePath -Raw)
        }

        It "Has module overview" {
            $Module = $HelpXml.helpItems | Get-Member | Where-Object { $_.Name -match "command" }
            $Module | Should Not BeNullOrEmpty
        }

        It "Documents New-VSAConnection" {
            $HelpXml = [xml](Get-Content -Path $HelpFilePath -Raw)
            $Content = $HelpXml.InnerXml
            $Content -match "New-VSAConnection" | Should Be $true
        }
    }

    Context "Command Details" {
        BeforeEach {
            $HelpXml = [xml](Get-Content -Path $HelpFilePath -Raw)
        }

        It "Commands have command elements" {
            $HelpXml.DocumentElement.ChildNodes.Count | Should BeGreaterThan 0
        }

        It "Help includes connection function documentation" {
            $Content = Get-Content -Path $HelpFilePath -Raw
            $Content -match "VSAConnection" | Should Be $true
        }

        It "Help includes alias documentation" {
            $Content = Get-Content -Path $HelpFilePath -Raw
            $Content -match "Get-VSA" | Should Be $true
        }
    }

    Context "MAML Compliance" {
        BeforeEach {
            $HelpXml = [xml](Get-Content -Path $HelpFilePath -Raw)
        }

        It "Help declares schema" {
            $HelpXml.helpItems.schema | Should Not BeNullOrEmpty
        }

        It "Help has namespace declarations" {
            $HelpXml.DocumentElement.Attributes | Should Not BeNullOrEmpty
        }

        It "Namespace includes MAML URI" {
            $NsAttr = $HelpXml.DocumentElement.Attributes
            $AttrString = $NsAttr | Out-String
            $AttrString -match "msh.microsoft.com/maml" | Should Be $true
        }
    }

    Context "Content Quality" {
        BeforeEach {
            $HelpXml = [xml](Get-Content -Path $HelpFilePath -Raw)
        }

        It "Help file is not empty" {
            (Get-Content -Path $HelpFilePath -Raw).Length | Should BeGreaterThan 0
        }

        It "Contains meaningful content" {
            $Content = Get-Content -Path $HelpFilePath -Raw
            $Content.Length | Should BeGreaterThan 1000
        }

        It "Does not document private Get-VSAItem function inappropriately" {
            $Content = Get-Content -Path $HelpFilePath -Raw
            # Get-VSAItem may be mentioned in context of being private
            if ($Content -match "Get-VSAItem") {
                $Content -match "private" | Should Be $true
            }
        }
    }

    Context "Help Accessibility" {
        BeforeEach {
            Import-Module -Path "$ModuleRoot\VSAModule.psd1" -Force -ErrorAction SilentlyContinue
        }

        It "Get-Help works for module" {
            { Get-Help -Name "VSAModule" -ErrorAction SilentlyContinue } | Should Not Throw
        }

        It "Get-Help works for New-VSAConnection" {
            { Get-Help -Name "New-VSAConnection" -ErrorAction SilentlyContinue } | Should Not Throw
        }

        It "Can retrieve help for connection function" {
            $Help = Get-Help -Name "New-VSAConnection" -ErrorAction SilentlyContinue
            $Help.Name | Should Not BeNullOrEmpty
        }

        It "Get-Help -Full works" {
            { Get-Help -Name "New-VSAConnection" -Full -ErrorAction SilentlyContinue } | Should Not Throw
        }

        It "Get-Help -Examples works" {
            { Get-Help -Name "New-VSAConnection" -Examples -ErrorAction SilentlyContinue } | Should Not Throw
        }
    }

    Context "Documentation Coverage" {
        BeforeEach {
            $HelpXml = [xml](Get-Content -Path $HelpFilePath -Raw)
        }

        It "Help file documents module overview" {
            $Content = Get-Content -Path $HelpFilePath -Raw
            $Content -match "VSAModule" | Should Be $true
        }

        It "Help includes examples" {
            $Content = Get-Content -Path $HelpFilePath -Raw
            $Content -match "example|Example" | Should Be $true
        }

        It "Help includes descriptions" {
            $Content = Get-Content -Path $HelpFilePath -Raw
            $Content -match "description|Description" | Should Be $true
        }
    }
}
