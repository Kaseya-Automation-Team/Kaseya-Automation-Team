BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "Update-cmdlet body pruning uses ContainsKey, not truthiness (T-7.4 / F-52)" {

    It "Update-VSAUser prunes BodyHT by ContainsKey, not truthiness" {
        # Update-VSAUser's own DynamicParam block has a pre-existing, unrelated bug (a
        # ValidateSetAttribute constructor mismatch) that makes the cmdlet impossible to invoke
        # at all right now, on any input - unrelated to this fix and out of scope here. Verify
        # the corrected pruning logic directly in the source instead of via invocation.
        $content = Get-Content -Path (Join-Path $script:ModuleRoot 'public/Update-VSAUser.ps1') -Raw
        $content | Should -Not -Match '-not\s+\$BodyHT\[\$key\]'
        $content | Should -Match '-not\s+\$PSBoundParameters\.ContainsKey\(\$key\)'
    }

    It "Update-VSAStaff sends OrgIdNumber 0 when explicitly provided (mapped OrgId body field)" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Update-VSAStaff -OrgStaffId 10001 -OrgIdNumber 0 -StaffFullName 'Jane Doe' | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.PSObject.Properties.Name | Should -Contain 'OrgId'
            $obj.OrgId | Should -Be 0
        }
    }

    It "Update-VSAStaff omits fields that were never bound" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Update-VSAStaff -OrgStaffId 10001 -OrgIdNumber 5 -StaffFullName 'Jane Doe' | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.PSObject.Properties.Name | Should -Not -Contain 'DeptId'
            $obj.PSObject.Properties.Name | Should -Not -Contain 'SupervisorId'
        }
    }
}

Describe "Update-VSASDTicketStatus StatusId is [string] (T-7.4 / F-52)" {
    It "declares StatusId as [string]" {
        $cmd = Get-Command -Name Update-VSASDTicketStatus
        $cmd.Parameters['StatusId'].ParameterType.Name | Should -Be 'String'
    }
}

Describe "Reversed set tests fixed (T-7.4 / F-48)" {
    It "<Name> uses '`$Repeat -ne ''Never''' instead of the reversed literal-match" -ForEach @(
        @{ Name = 'Set-VSAAuditSchedule' }
        @{ Name = 'New-VSAPatchScan' }
        @{ Name = 'Set-VSAScheduleAuditSysInfo' }
        @{ Name = 'Set-VSAPatchIgnore' }
        @{ Name = 'Start-VSAPatchUpdate' }
    ) {
        $content = Get-Content -Path (Join-Path $script:ModuleRoot "public/$Name.ps1") -Raw
        $content | Should -Not -Match "'Never'\s*-notmatch\s*\`$Repeat"
        $content | Should -Match '\$Repeat\s*-ne\s*''Never'''
    }
}

Describe "Copy-VSAMGStructure has no `$global: variables (T-7.4 / F-45)" {
    It "does not use `$global: anywhere" {
        $content = Get-Content -Path (Join-Path $script:ModuleRoot 'public/Copy-VSAMGStructure.ps1') -Raw
        $content | Should -Not -Match '\$global:'
    }
}

Describe "New-VSADocumentFolder has no `$SourceFilePath ghost (T-7.4 / F-45)" {
    It "does not reference the undeclared `$SourceFilePath variable" {
        $content = Get-Content -Path (Join-Path $script:ModuleRoot 'public/New-VSADocumentFolder.ps1') -Raw
        $content | Should -Not -Match '\$SourceFilePath'
    }
}

Describe "Duplicate dead `$Params assignments removed (T-7.4 / F-45)" {
    It "<Name> has exactly one `$Params hashtable assignment" -ForEach @(
        @{ Name = 'Get-VSAAgent' }
        @{ Name = 'Get-VSAAdminTask' }
        @{ Name = 'Get-VSAAsset' }
        @{ Name = 'Get-VSAThirdAppNotification' }
    ) {
        $content = Get-Content -Path (Join-Path $script:ModuleRoot "public/$Name.ps1") -Raw
        $count = [regex]::Matches($content, '\[hashtable\]\$Params\s*=\s*@\{').Count
        $count | Should -Be 1
    }
}
