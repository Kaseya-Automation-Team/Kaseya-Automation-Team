# VSAModule Pester Test Configuration
# This file defines the test configuration for running VSAModule tests

# Pester Configuration for VSAModule
$PesterConfig = @{
    # Path to test files
    Path = @(
        "$PSScriptRoot\VSAModule.Manifest.Tests.ps1"
        "$PSScriptRoot\VSAModule.Import.Tests.ps1"
        "$PSScriptRoot\VSAModule.Connection.Tests.ps1"
        "$PSScriptRoot\VSAModule.Help.Tests.ps1"
        "$PSScriptRoot\VSAModule.Quality.Tests.ps1"
    )
    
    # Output verbosity
    Output = @{
        Verbosity = 'Detailed'
        StackTraceVerbosity = 'Full'
    }
    
    # Test result configuration
    TestDrive = @{
        Enabled = $true
    }
    
    # Should configuration
    Should = @{
        ErrorAction = 'Stop'
    }
}

# Code Coverage configuration (optional)
$CodeCoverageConfig = @{
    Path = @(
        "$PSScriptRoot\..\VSAModule.psm1"
        "$PSScriptRoot\..\public\*.ps1"
        "$PSScriptRoot\..\private\*.ps1"
    )
    CoveragePercentTarget = 75
}

# Test result options
$TestResultOptions = @{
    OutputFormat = 'NUnitXml'
    OutputPath = "$PSScriptRoot\test-results.xml"
}

# Export for use in CI/CD or manual test runs
Export-ModuleMember -Variable PesterConfig, CodeCoverageConfig, TestResultOptions
