# Changelog - VSAModule

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-01-27

### Major Release - Production Ready

VSAModule reaches v1.0.0 with comprehensive REST API coverage for Kaseya VSA 9, production-grade error handling, security hardening, and extensive test coverage.

### ✨ Features

#### Core Functionality
- **90+ PowerShell cmdlets** providing complete REST API wrapper for Kaseya VSA 9
- Support for **persistent and non-persistent connection modes** with optional DPAPI encryption
- **Comprehensive API coverage**: Organizations, Assets, Agents, Departments, Machine Groups, Service Desk, Tickets, Staff, Users, Roles, Scopes, Custom Fields, Audits, Patches, and more
- **100+ aliases** for convenient command invocation and backward compatibility
- **Full CRUD operations** (Create, Read, Update, Delete) for most resources
- **Advanced filtering**: Filter, Paging, and Sort parameters on query operations
- **Dynamic parameter resolution**: Tenant names, organization names, and resource names can be resolved dynamically

#### Reliability Enhancements (v0.1.5+)
- **Automatic retry logic** with exponential backoff for transient HTTP errors (502, 503, 504)
  - Default: 3 retries with 1s, 2s, 4s, 8s waits
  - Configurable via MaxRetries parameter (0-10 range)
  - Prevents cascading failures during temporary server issues
  - Clear warning messages showing retry progress

- **Automatic token renewal** for large dataset operations
  - Transparently handles session expiration when fetching >25,000 records
  - No user intervention required

### 🔒 Security Enhancements

- **Windows DPAPI Encryption** for storing sensitive connection data
  - Optional persistent connection storage with automatic encryption
  - Credential cleanup on session termination
  - Account-specific encryption (non-transferable between users)

- **OData Injection Prevention**
  - All filter parameters sanitized and validated
  - Special characters escaped according to OData standards
  - Protection against query injection attacks

- **HTTPS Enforcement**
  - Module enforces HTTPS for all REST API communications
  - Certificate validation with optional bypass for testing (IgnoreCertificateErrors switch)
  - Secure by default

- **Input Validation**
  - ValidateNotNull() on VSAConnection parameters
  - ValidateScript() on numeric ID parameters
  - ValidateNotNullOrEmpty() on string filters
  - Comprehensive parameter validation across all functions

### 🐛 Bug Fixes

- Fixed Get-VSAAlarm AlarmId parameter to be optional (Mandatory=$false)
  - Users can now retrieve all alarms as documented
  - AlarmId parameter now correctly optional to match REST API behavior

- Fixed parameter validation in query operations
  - Numeric IDs now properly validated as non-null
  - Filter, Paging, Sort parameters with consistent validation

### 📋 Testing & Quality

- **7 comprehensive Pester test suites**:
  - Manifest validation (VSAModule.Tests.ps1)
  - Module import verification (ImportModule.Tests.ps1)
  - Help documentation completeness (Help.Tests.ps1)
  - Connection management (Connection.Tests.ps1)
  - Code quality analysis (PSScriptAnalyzer)
  - Security validation tests
  - Integration test templates

- **100% function documentation**
  - Complete .SYNOPSIS, .DESCRIPTION, .PARAMETER sections
  - Real-world .EXAMPLE sections for each function
  - Comprehensive .NOTES sections
  - Help available via Get-Help cmdlet

- **Zero external dependencies**
  - PowerShell 5.1 native functionality only
  - No NuGet packages required
  - Self-contained module

### 📦 Dependencies

- **Required**: PowerShell 5.1 (Windows)
- **Optional**: Pester 5.0+ (for running tests)
- **No external NuGet/module dependencies**

### ⚙️ Technical Details

- **Module Type**: Script Module (PSModuleType)
- **PowerShell Edition**: Windows PowerShell 5.1+
- **Pipeline Support**: Value from pipeline by property name for all major parameters
- **C# Classes**: VSAConnection class with encryption/decryption support
- **Dynamic Parameters**: Optional name-to-ID resolution where applicable
- **Parameter Sets**: Multiple parameter sets for dual-mode operations where needed

### 📝 Documentation

- **README.md**: Comprehensive getting started guide and usage examples
- **Help System**: Full PowerShell help integration (Get-Help Get-VSAAgent, etc.)

### 🔄 Migration Notes

If upgrading from v0.x:

- **No breaking changes** in API surface
- All existing scripts continue to work
- New retry logic is transparent (automatic)
- New security features are opt-in (DPAPI persistence)
- Existing non-persistent connections continue to work

### ✅ Release Checklist

- [x] Retry logic implementation with exponential backoff
- [x] Automatic token renewal for large datasets
- [x] Security hardening (DPAPI, OData prevention, HTTPS)
- [x] Comprehensive parameter validation
- [x] Complete help documentation
- [x] 7 test suites with good coverage
- [x] Zero external dependencies
- [x] 100% backward compatibility
- [x] Manifest validation passing
- [x] Module imports without errors
- [x] All 90+ functions discoverable
- [x] Pre-release verification complete

### 🙏 Support

For issues, feature requests, or contributions, please visit the project repository.

---

**Release Date**: January 27, 2026  
**Manifest Version**: 1.0.0  
**Status**: Production Ready
