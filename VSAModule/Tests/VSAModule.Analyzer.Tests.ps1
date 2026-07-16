$ModuleRoot = Split-Path -Path (Split-Path -Parent $PSScriptRoot)

Describe "VSAModule PSScriptAnalyzer Gate" {

    BeforeAll {
        $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
        if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
            throw "PSScriptAnalyzer is not installed. Run: Install-Module PSScriptAnalyzer -Force"
        }
        Import-Module PSScriptAnalyzer -Force
        # Gate the shipped module code. The Tests directory is excluded because Pester's
        # BeforeAll/It variable flow produces PSUseDeclaredVarsMoreThanAssignments false positives.
        $script:ScanPaths = @(
            (Join-Path $script:ModuleRoot 'VSAModule.psm1')
            (Join-Path $script:ModuleRoot 'VSAModule.psd1')
            (Join-Path $script:ModuleRoot 'public')
            (Join-Path $script:ModuleRoot 'private')
        )
        $script:Results = $script:ScanPaths | ForEach-Object {
            Invoke-ScriptAnalyzer -Path $_ -Recurse -Settings PSGallery
        }
    }

    It "Has no Error-severity findings" {
        $errors = @($script:Results | Where-Object { $_.Severity -eq 'Error' })
        $report = ($errors | ForEach-Object { "$($_.ScriptName):$($_.Line) $($_.RuleName)" }) -join "`n"
        $errors.Count | Should -Be 0 -Because "Errors found:`n$report"
    }

    It "Has no Warning findings for critical rules" {
        $criticalRules = @(
            'PSAvoidUsingWriteHost'
            'PSUseDeclaredVarsMoreThanAssignments'
            'PSUseApprovedVerbs'
            'PSAvoidGlobalVars'
        )
        $warnings = @($script:Results | Where-Object { $_.Severity -eq 'Warning' -and $criticalRules -contains $_.RuleName })
        $report = ($warnings | ForEach-Object { "$($_.ScriptName):$($_.Line) $($_.RuleName)" }) -join "`n"
        $warnings.Count | Should -Be 0 -Because "Critical-rule warnings found:`n$report"
    }
}
