<#
.SYNOPSIS
    Master test runner for VSAModule Pester tests
    
.DESCRIPTION
    This script orchestrates the execution of all VSAModule Pester tests with various options
    for output format, code coverage, and detailed reporting.

.PARAMETER TestPath
    Specific path to test files. Defaults to all test files in current directory.

.PARAMETER TestName
    Specific test name to run. Wildcards supported.

.PARAMETER Output
    Output verbosity level. Options: Minimal, Normal, Detailed. Default: Detailed

.PARAMETER CodeCoverage
    Include code coverage analysis. Requires running with elevated privileges.

.PARAMETER PassThru
    Return test results object for further processing

.PARAMETER GenerateReport
    Generate HTML test report

.EXAMPLE
    .\Run-Tests.ps1
    Runs all tests with detailed output

.EXAMPLE
    .\Run-Tests.ps1 -TestName "Manifest*" -Output Normal
    Runs manifest tests with normal verbosity

.EXAMPLE
    .\Run-Tests.ps1 -CodeCoverage -GenerateReport
    Runs all tests with code coverage and generates HTML report

#>

[CmdletBinding()]
param(
    [ValidateScript({ Test-Path $_ })]
    [string]$TestPath = $PSScriptRoot,
    
    [string]$TestName,
    
    [ValidateSet('Minimal', 'Normal', 'Detailed')]
    [string]$Output = 'Detailed',
    
    [switch]$CodeCoverage,
    
    [switch]$PassThru,
    
    [switch]$GenerateReport
)

# Configuration
$ModuleRoot = Split-Path -Parent $PSScriptRoot
$TestResultsPath = Join-Path -Path $PSScriptRoot -ChildPath 'test-results.xml'
$HtmlReportPath = Join-Path -Path $PSScriptRoot -ChildPath 'test-report.html'

Write-Host "VSAModule Test Runner" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host ""

# Verify Pester is installed
try {
    $PesterVersion = (Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
    Write-Host "Pester Version: $PesterVersion" -ForegroundColor Green
} catch {
    Write-Host "Pester module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Build Invoke-Pester parameters
$PesterParams = @{
    Path = Get-ChildItem -Path $TestPath -Filter '*Tests.ps1' -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName
    Output = $Output
    PassThru = $PassThru -or $GenerateReport
}

# Add test name filter if provided
if ($TestName) {
    $PesterParams.TestName = $TestName
    Write-Host "Running tests matching: $TestName" -ForegroundColor Yellow
} else {
    Write-Host "Running all tests in: $TestPath" -ForegroundColor Yellow
}

# Add code coverage if requested
if ($CodeCoverage) {
    Write-Host "Code coverage analysis enabled" -ForegroundColor Yellow
    $PesterParams.CodeCoverage = @(
        Join-Path -Path $ModuleRoot -ChildPath 'VSAModule.psm1'
        Join-Path -Path $ModuleRoot -ChildPath 'public\*.ps1'
    )
}

Write-Host ""
Write-Host "Executing tests..." -ForegroundColor Cyan
Write-Host ""

# Execute tests
$TestResults = Invoke-Pester @PesterParams

# Display summary
Write-Host ""
Write-Host "Test Execution Complete" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

if ($TestResults) {
    Write-Host "Total Tests: $($TestResults.Tests.Count)" -ForegroundColor White
    Write-Host "Passed: $($TestResults.PassedCount)" -ForegroundColor Green
    Write-Host "Failed: $($TestResults.FailedCount)" -ForegroundColor Red
    Write-Host "Skipped: $($TestResults.SkippedCount)" -ForegroundColor Yellow
    Write-Host "Not Run: $($TestResults.NotRunCount)" -ForegroundColor Gray
    
    $PassRate = if ($TestResults.Tests.Count -gt 0) {
        [math]::Round(($TestResults.PassedCount / $TestResults.Tests.Count) * 100, 2)
    } else {
        0
    }
    Write-Host "Pass Rate: $PassRate%" -ForegroundColor White
    
    # Show code coverage if enabled
    if ($CodeCoverage -and $TestResults.CodeCoverage) {
        $CoveragePercentage = [math]::Round($TestResults.CodeCoverage.CoveragePercentage, 2)
        Write-Host "Code Coverage: $CoveragePercentage%" -ForegroundColor White
    }
    
    # Export results to XML
    $TestResults | Export-CliXml -Path $TestResultsPath
    Write-Host ""
    Write-Host "Results exported to: $TestResultsPath" -ForegroundColor Green
    
    # Generate HTML report if requested
    if ($GenerateReport) {
        Write-Host "Generating HTML report..." -ForegroundColor Yellow
        
        # Create simple HTML report
        $Html = @"
<!DOCTYPE html>
<html>
<head>
    <title>VSAModule Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #2c3e50; }
        .summary { background-color: #ecf0f1; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .passed { color: #27ae60; font-weight: bold; }
        .failed { color: #e74c3c; font-weight: bold; }
        .skipped { color: #f39c12; font-weight: bold; }
        .test-suite { margin-top: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { text-align: left; padding: 8px; border-bottom: 1px solid #ddd; }
        th { background-color: #34495e; color: white; }
        tr:hover { background-color: #f5f5f5; }
    </style>
</head>
<body>
    <h1>VSAModule Pester Test Report</h1>
    <p><em>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</em></p>
    
    <div class="summary">
        <h2>Summary</h2>
        <p>Total Tests: $($TestResults.Tests.Count)</p>
        <p><span class="passed">Passed: $($TestResults.PassedCount)</span></p>
        <p><span class="failed">Failed: $($TestResults.FailedCount)</span></p>
        <p><span class="skipped">Skipped: $($TestResults.SkippedCount)</span></p>
        <p>Pass Rate: $PassRate%</p>
        $(if ($CodeCoverage) { "<p>Code Coverage: $CoveragePercentage%</p>" })
    </div>
    
    <h2>Test Details</h2>
    <table>
        <tr>
            <th>Test Name</th>
            <th>Result</th>
            <th>Duration</th>
        </tr>
"@
        
        foreach ($Test in $TestResults.Tests) {
            $Result = if ($Test.Result -eq 'Passed') { '<span class="passed">Passed</span>' } 
                      elseif ($Test.Result -eq 'Failed') { '<span class="failed">Failed</span>' }
                      else { '<span class="skipped">Skipped</span>' }
            
            $Html += "<tr><td>$($Test.Name)</td><td>$Result</td><td>$($Test.Duration.TotalMilliseconds)ms</td></tr>"
        }
        
        $Html += @"
    </table>
</body>
</html>
"@
        
        $Html | Out-File -FilePath $HtmlReportPath -Encoding UTF8
        Write-Host "HTML report generated: $HtmlReportPath" -ForegroundColor Green
    }
    
    # Return test results if requested
    if ($PassThru) {
        return $TestResults
    }
    
    # Exit with appropriate code
    exit $TestResults.FailedCount
} else {
    Write-Host "No test results returned" -ForegroundColor Red
    exit 1
}
