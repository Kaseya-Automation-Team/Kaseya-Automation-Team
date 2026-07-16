BeforeAll {
    $ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    $ModulePath = Join-Path -Path $ModuleRoot -ChildPath 'VSAModule.psd1'
}

Describe "New-VSAConnection Function Tests" {

    BeforeEach {
        Import-Module $ModulePath -Force
    }

    Context "Function Availability" {
        It "New-VSAConnection function exists" {
            Get-Command -Name "New-VSAConnection" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "New-VSAConnection is a function" {
            (Get-Command -Name "New-VSAConnection").CommandType | Should -Be "Function"
        }

        It "New-VSAConnection has parameter sets" {
            $Command = Get-Command -Name "New-VSAConnection"
            $Command.ParameterSets.Count | Should -BeGreaterThan 0
        }
    }

    Context "Parameter Validation" {
        BeforeEach {
            $Command = Get-Command -Name "New-VSAConnection"
        }

        It "Has VSAServer parameter" {
            $Command.Parameters.Keys -contains "VSAServer" | Should -Be $true
        }

        It "Has Credential parameter" {
            $Command.Parameters.Keys -contains "Credential" | Should -Be $true
        }

        It "Has IgnoreCertificateErrors parameter" {
            $Command.Parameters.Keys -contains "IgnoreCertificateErrors" | Should -Be $true
        }

        It "Has SetPersistent parameter" {
            $Command.Parameters.Keys -contains "SetPersistent" | Should -Be $true
        }

        It "VSAServer parameter is mandatory" {
            $Attr = $Command.Parameters["VSAServer"].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            $Attr.Mandatory | Should -Be $true
        }
    }

    Context "Function Help" {
        It "New-VSAConnection has help" {
            $Help = Get-Help -Name "New-VSAConnection" -ErrorAction SilentlyContinue
            $Help.Name | Should -Not -BeNullOrEmpty
        }

        It "Help has synopsis" {
            $Help = Get-Help -Name "New-VSAConnection" -ErrorAction SilentlyContinue
            $Help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "Help has description" {
            $Help = Get-Help -Name "New-VSAConnection" -ErrorAction SilentlyContinue
            $Help.Description | Should -Not -BeNullOrEmpty
        }
    }

    Context "Error Handling" {
        It "Returns error for invalid VSAServer URL" {
            $Credential = New-Object PSCredential("user", (ConvertTo-SecureString "password" -AsPlainText -Force))
            { New-VSAConnection -VSAServer "invalid" -Credential $Credential -ErrorAction Stop } | Should -Throw
        }

        It "Requires Credential object" {
            { New-VSAConnection -VSAServer "https://vsa.example.com" -Credential $null -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe "VSAConnection Class Tests" {

    BeforeEach {
        Import-Module $ModulePath -Force
    }

    Context "Class Definition" {
        It "VSAConnection class exists" {
            { [VSAConnection] } | Should -Not -Throw
        }

        It "Can create VSAConnection instance" {
            { $conn = New-Object VSAConnection } | Should -Not -Throw
        }
    }

    Context "Class Properties" {
        It "VSAConnection has URI property" {
            $conn = New-Object VSAConnection
            $conn | Get-Member -Name "URI" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "VSAConnection has UserName property" {
            $conn = New-Object VSAConnection
            $conn | Get-Member -Name "UserName" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "VSAConnection has Token property" {
            $conn = New-Object VSAConnection
            $conn | Get-Member -Name "Token" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Certificate handling (no TrustAllCertsPolicy class)" {

    BeforeEach {
        Import-Module $ModulePath -Force
    }

    Context "Design" {
        # T-5.2 / F-26: the obsolete ICertificatePolicy-based TrustAllCertsPolicy class was
        # removed. Certificate-error bypass is handled per-request in Get-RequestData, branching
        # on the PowerShell edition.
        It "TrustAllCertsPolicy class is not defined" {
            ('TrustAllCertsPolicy' -as [type]) | Should -BeNullOrEmpty
        }
    }
}
