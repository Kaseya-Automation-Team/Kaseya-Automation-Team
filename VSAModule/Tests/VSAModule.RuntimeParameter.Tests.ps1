BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "New-VSARuntimeParameter shared helper" {

    It "is a private module helper (not exported)" {
        Get-Command -Module VSAModule -Name 'New-VSARuntimeParameter' -ErrorAction SilentlyContinue |
            Should -BeNullOrEmpty
        InModuleScope VSAModule {
            Get-Command -Name 'New-VSARuntimeParameter' -CommandType Function -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }
    }

    It "builds a RuntimeDefinedParameter with the requested name and type" {
        InModuleScope VSAModule {
            $p = New-VSARuntimeParameter -Name 'Times' -Type ([int])
            $p | Should -BeOfType ([System.Management.Automation.RuntimeDefinedParameter])
            $p.Name | Should -Be 'Times'
            $p.ParameterType | Should -Be ([int])
        }
    }

    It "attaches a ValidateSetAttribute only when a set is supplied" {
        InModuleScope VSAModule {
            $withSet = New-VSARuntimeParameter -Name 'DaysOfWeek' -Type ([string]) -ValidateSet @('Monday', 'Tuesday')
            ($withSet.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues |
                Should -Be @('Monday', 'Tuesday')

            $noSet = New-VSARuntimeParameter -Name 'Times' -Type ([int])
            ($noSet.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }) |
                Should -BeNullOrEmpty
        }
    }

    It "reflects the Mandatory flag (defaults to false)" {
        InModuleScope VSAModule {
            $optional = New-VSARuntimeParameter -Name 'Times' -Type ([int])
            ($optional.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory |
                Should -Be $false

            $required = New-VSARuntimeParameter -Name 'Times' -Type ([int]) -Mandatory $true
            ($required.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory |
                Should -Be $true
        }
    }
}

Describe "Schedule cmdlets use the shared helper, not an inline copy" {

    # These six cmdlets each used to redefine an identical New-VSARuntimeParameter / New-RuntimeParameter
    # inside their DynamicParam block. They now share private/New-VSARuntimeParameter.ps1.
    $ScheduleCmdlets = @(
        'Set-VSAAuditSchedule', 'Set-VSAScheduleAuditSysInfo', 'Set-VSAPatchIgnore',
        'New-VSAScheduleAuditBaseLine', 'New-VSAAPScheduled', 'Start-VSAPatchUpdate'
    ) | ForEach-Object { @{ Name = $_ } }

    It "<Name> no longer defines the helper inline" -ForEach $ScheduleCmdlets {
        $content = Get-Content -Path (Join-Path $script:ModuleRoot "public/$Name.ps1") -Raw
        $content | Should -Not -Match 'function\s+New-(VSA)?RuntimeParameter'
    }

    It "<Name> references the shared New-VSARuntimeParameter" -ForEach $ScheduleCmdlets {
        $content = Get-Content -Path (Join-Path $script:ModuleRoot "public/$Name.ps1") -Raw
        $content | Should -Match 'New-VSARuntimeParameter'
    }
}

Describe "DynamicParam binding resolves the shared helper" {

    BeforeAll {
        # A dummy connection satisfies [ValidateNotNull()]; -WhatIf keeps every call off the network.
        $script:DummyConn = InModuleScope VSAModule { [VSAConnection]::new() }
    }

    It "Set-VSAAuditSchedule binds Weeks/DaysOfWeek/Times dynamic params" {
        { Set-VSAAuditSchedule -VSAConnection $script:DummyConn -AgentID 100 -Repeat Weeks -DaysOfWeek Monday -Times 2 -WhatIf } |
            Should -Not -Throw
    }

    It "Set-VSAScheduleAuditSysInfo binds Months/DayOfMonth/MonthOfYear dynamic params" {
        { Set-VSAScheduleAuditSysInfo -VSAConnection $script:DummyConn -AgentID 100 -Repeat Months -DayOfMonth FirstMonday -MonthOfYear January -WhatIf } |
            Should -Not -Throw
    }

    It "Start-VSAPatchUpdate binds Weeks/DaysOfWeek dynamic params" {
        { Start-VSAPatchUpdate -VSAConnection $script:DummyConn -AgentGuids 100 -Repeat Weeks -DaysOfWeek Friday -WhatIf } |
            Should -Not -Throw
    }

    It "rejects a value outside the dynamic ValidateSet the helper attached" {
        { Set-VSAAuditSchedule -VSAConnection $script:DummyConn -AgentID 100 -Repeat Weeks -DaysOfWeek 'Notaday' -WhatIf } |
            Should -Throw -ExpectedMessage '*does not belong to the set*'
    }
}
