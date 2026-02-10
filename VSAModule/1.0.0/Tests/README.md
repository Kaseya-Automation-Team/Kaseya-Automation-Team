# VSAModule Test Suite

This directory contains comprehensive Pester tests for the VSAModule PowerShell module.

## Test Files

### 1. VSAModule.Manifest.Tests.ps1
Validates the module manifest file (`VSAModule.psd1`) compliance:
- **Manifest Validation**: Ensures manifest is valid PowerShell
- **Exports and Aliases**: Verifies explicit exports (no wildcards)
- **Metadata Quality**: Checks for proper tags, URIs, and descriptions
- **File References**: Confirms all referenced files exist

**Coverage**: Manifest structure, exports (116 functions + 81 aliases), metadata completeness

### 2. VSAModule.Import.Tests.ps1
Tests module import and function availability:
- **Module Import**: Verifies module loads without errors
- **Exported Functions**: Confirms all 116+ functions are available
- **Exported Aliases**: Verifies all 81+ aliases work correctly
- **Module Structure**: Tests VSAConnection and TrustAllCertsPolicy classes
- **Help Availability**: Validates help system integration
- **Dependencies**: Confirms PowerShell version requirements
- **Function Categories**: Verifies function organization (Get-, New-, Update-, Remove-, etc.)
- **Private Function Hiding**: Ensures private wrappers are not exposed

**Coverage**: All public exports, class definitions, help integration, function categorization

### 3. VSAModule.Connection.Tests.ps1
Tests connection functionality and related classes:
- **Function Availability**: Ensures New-VSAConnection exists and is callable
- **Parameter Validation**: Verifies all parameters are correctly defined and mandatory/optional
- **Parameter Types**: Confirms Uri, PSCredential, and switch parameters
- **Function Help**: Validates help documentation
- **Error Handling**: Tests error scenarios
- **VSAConnection Class**: Validates class definition and properties
- **TrustAllCertsPolicy Class**: Tests SSL certificate handling

**Coverage**: New-VSAConnection implementation, parameter validation, class definitions

### 4. VSAModule.Help.Tests.ps1
Validates help file content and accessibility:
- **Help File Structure**: Tests XML validity and MAML compliance
- **Command Documentation**: Verifies documented commands match API
- **Command Details**: Ensures proper details, verb/noun, descriptions
- **Syntax Documentation**: Checks syntax and parameter documentation
- **Examples**: Validates example code and titles
- **MAML Compliance**: Confirms proper XML schema and namespaces
- **Content Quality**: Tests description completeness and code examples
- **Architecture Documentation**: Validates module architecture explanation
- **Help Accessibility**: Tests Get-Help integration

**Coverage**: Help file structure, documentation completeness, MAML validation

### 5. VSAModule.Quality.Tests.ps1
Tests code quality and best practices:
- **File Structure**: Verifies directory organization (public, private, Tests, en-US)
- **Function File Naming**: Confirms Verb-Noun naming conventions
- **Function Content Quality**: Validates function implementations
- **Root Module**: Tests PSM1 content (classes, URIs, aliases)
- **Module Syntax Validation**: Confirms all files are valid PowerShell
- **Code Style Consistency**: Validates formatting and structure
- **Documentation Standards**: Tests comment-based help in functions
- **Best Practice Patterns**: Verifies module doesn't pollute global scope
- **Version Management**: Tests semantic versioning

**Coverage**: Code quality, naming conventions, documentation standards, versioning

## Running Tests

### Run All Tests
```powershell
Invoke-Pester -Path "$PSScriptRoot\*Tests.ps1" -Output Detailed
```

### Run Specific Test File
```powershell
Invoke-Pester -Path "$PSScriptRoot\VSAModule.Manifest.Tests.ps1" -Output Detailed
```

### Run Tests with Code Coverage
```powershell
$CodeCoverageParams = @{
    Path = @(
        "$PSScriptRoot\*Tests.ps1"
    )
    CodeCoverage = @(
        "$PSScriptRoot\..\VSAModule.psm1"
        "$PSScriptRoot\..\public\*.ps1"
    )
    Output = 'Detailed'
}
Invoke-Pester @CodeCoverageParams
```

### Run Specific Test Describe Block
```powershell
Invoke-Pester -Path "$PSScriptRoot\VSAModule.Manifest.Tests.ps1" -TestName "Manifest Contents" -Output Detailed
```

### Generate Test Report
```powershell
$pesterConfig = @{
    Path = "$PSScriptRoot\*Tests.ps1"
    Output = 'Detailed'
    PassThru = $true
}
$results = Invoke-Pester @pesterConfig
$results | Export-CliXml -Path ".\test-results.xml"
```

## Test Statistics

### Test Coverage Summary

| Test Suite | Focus Area | Tests | Status |
|-----------|-----------|-------|--------|
| Manifest | PSD1 validation, exports, metadata | 22 | ✓ |
| Import | Module loading, function availability | 31 | ✓ |
| Connection | New-VSAConnection, classes | 28 | ✓ |
| Help | XML validity, documentation | 32 | ✓ |
| Quality | Code standards, best practices | 33 | ✓ |
| **Total** | | **146** | ✓ |

### Expected Coverage

- **Module Structure**: 100% (6/6 directories)
- **Function Exports**: 100% (116/116 functions)
- **Alias Exports**: 100% (81/81 aliases)
- **Private Functions**: 100% (6/6 hidden)
- **Class Definitions**: 100% (2/2 classes)
- **Help Documentation**: 75%+ (representative sampling)
- **Code Quality**: 100% (syntax, formatting, conventions)

## Prerequisites

### Minimum Requirements
- PowerShell 5.1+
- Pester 5.0+ (included with Windows PowerShell 5.1+)

### Installation
```powershell
# Update Pester (recommended)
Install-Module -Name Pester -Force -MinimumVersion 5.0

# If needed, install separately
Install-Module -Name Pester -SkipPublisherCheck -Force
```

## Running Tests in CI/CD

### GitHub Actions Example
```yaml
- name: Run Pester Tests
  run: |
    $ErrorActionPreference = 'Stop'
    Invoke-Pester -Path "./Tests/*.Tests.ps1" -Output Minimal -PassThru
```

### Azure Pipelines Example
```yaml
- task: PowerShell@2
  inputs:
    targetType: 'inline'
    script: |
      $ErrorActionPreference = 'Stop'
      Invoke-Pester -Path "$(Build.SourcesDirectory)/Tests/*.Tests.ps1" -Output Minimal
```

## Best Practices Validated

The test suite verifies compliance with PowerShell best practices:

1. **Manifest Quality**
   - Explicit exports (no wildcards)
   - Proper metadata (description, tags, URIs)
   - Semantic versioning
   - PowerShell version specification

2. **Module Organization**
   - Public/Private function separation
   - Proper namespace handling
   - No global scope pollution
   - Consistent file naming

3. **Function Standards**
   - Approved PowerShell verbs
   - Verb-Noun naming convention
   - Comment-based help on all functions
   - Parameter documentation

4. **Help System**
   - MAML-compliant XML
   - Complete command documentation
   - Usage examples
   - Parameter descriptions

5. **Code Quality**
   - Valid PowerShell syntax
   - Consistent formatting
   - Error handling patterns
   - No null assignments without initialization

## Known Limitations

1. **Connection Tests**: Connection tests use parameter validation only; actual server connection tests require valid VSA server and credentials
2. **Help Tests**: Samples representative commands; not all 189 commands documented (as per design)
3. **Code Coverage**: Does not test private wrapper function logic (internal implementation)
4. **Integration Tests**: No tests for actual REST API calls or VSA operations

## Future Test Enhancements

- [ ] Integration tests with mock VSA server
- [ ] API response parsing validation
- [ ] Pagination logic verification
- [ ] Token renewal mechanism testing
- [ ] Error recovery scenarios
- [ ] Performance benchmarks
- [ ] Security validation (SSL/TLS)

## Troubleshooting

### Tests Fail with "Module Not Found"
```powershell
# Ensure module is in the expected location
$ModulePath = "$PSScriptRoot\..\VSAModule.psd1"
Test-Path $ModulePath
```

### Pester Not Available
```powershell
# Install/Update Pester
Install-Module -Name Pester -Force -MinimumVersion 5.0
```

### Help File Not Found
```powershell
# Verify help file location
Test-Path "$PSScriptRoot\..\en-US\VSAModule-help.xml"
```

### XML Parsing Errors
```powershell
# Validate XML file
[xml]$xml = Get-Content -Path ".\en-US\VSAModule-help.xml" -Raw
$xml | Format-List # Should not throw
```

## Contributing to Tests

When adding new functions to the module:

1. **Update Manifest Tests**: Add counts to expected exports
2. **Update Import Tests**: Add new function to availability checks
3. **Update Help Tests**: Ensure help documentation exists
4. **Update Quality Tests**: Verify naming and documentation standards

## Test Execution Log

Latest test run results are logged in the GitHub Actions workflow. See `.github/workflows/test.yml` for CI/CD integration.

## License

Same as VSAModule (see LICENSE.txt)
