# About

This module is designed to make it easier to use the Kaseya VSA API in your PowerShell scripts. By handling all the hard work, it allows you to develop your scripts faster and more efficiently. There's no need for a steep learning curve; simply load the module, enter your API keys, and get results within minutes!

**Note:** While this PowerShell module simplifies interaction with the Kaseya VSA REST API, it does not modify or impact the behavior of the API itself. Any issues or glitches that arise within the REST API are unrelated to the module and should be addressed to Kaseya directly.

## 🎉 Version 1.0.0 - Production Ready

**Released: January 27, 2026**

VSAModule v1.0.0 is a production-ready release with comprehensive REST API coverage, enterprise-grade reliability, and advanced security features.

### ✨ What's New in v1.0

- **Automatic Retry Logic**: Transient HTTP errors (502, 503, 504) automatically retry with exponential backoff (1s, 2s, 4s, 8s...)
- **Large Dataset Support**: Automatic token renewal for queries exceeding 25,000 records
- **Enhanced Security**: Windows DPAPI encryption for persistent connections, OData injection prevention, HTTPS enforcement
- **90+ REST API Cmdlets**: Complete coverage of organizations, agents, assets, tickets, staff, roles, scopes, and more
- **Comprehensive Testing**: 7 Pester test suites with good coverage
- **Zero Dependencies**: Fully self-contained PowerShell module, no external packages required

**See [CHANGELOG.md](./CHANGELOG.md) for complete v1.0 release notes**

## Security

**Version 1.0 includes enterprise security features:**
- OData Injection Prevention - User input in filters is automatically escaped
- Parameter Validation - All ID parameters validated against injection attacks
- Credential Encryption - Persistent connections use Windows DPAPI encryption
- Secure Cleanup - Credentials cleared from memory after use
- Automatic Retry Protection - Prevents cascading failures with exponential backoff

See [SECURITY_HARDENING.md](./SECURITY_HARDENING.md) for detailed security implementation and best practices.

## Basics

You can install the module from the [PowerShell Gallery](https://www.powershellgallery.com/packages/VSAModule). Use the example below to get started.

### Recommended: Non-Persistent Connection (Most Secure)

```powershell
begin {
    # Load the VSAModule
    $ModuleName = 'VSAModule'
    Import-Module -Name $ModuleName -Force

    # Get credentials
    $VSAUserName = '<Kaseya VSA REST API User Name>'
    $VSAUserPAT =  '<Kaseya VSA REST API User PAT>'

    [securestring]$secStringPassword = ConvertTo-SecureString $VSAUserPAT -AsPlainText -Force
    [pscredential]$VSACred = New-Object System.Management.Automation.PSCredential ($VSAUserName, $secStringPassword)

    # Create non-persistent connection (credentials stored in memory only)
    $VSAConnParams = @{
        VSAServer               = 'https://your-vsa9-server.com'
        Credential              = $VSACred
        IgnoreCertificateErrors = $false  # Use $true only for testing with self-signed certificates
    }

    # Establish connection to the VSA Environment
    $VSAConnection = New-VSAConnection @VSAConnParams
}

process {
    # Get VSA Organizations Information
    $VSAOrganizations = Get-VSAOrganization -VSAConnection $VSAConnection
}

# Connection is automatically cleaned up at end of script
```

### Alternative: Persistent Connection (Interactive Sessions Only)

**WARNING: Use persistent connections only in secure, interactive PowerShell sessions. Not recommended for automated scripts.**

```powershell
# Create persistent connection (credentials encrypted with Windows DPAPI)
$VSAConnection = New-VSAConnection `
    -VSAServer 'https://your-vsa9-server.com' `
    -Credential (Get-Credential) `
    -SetPersistent

# Later commands can use implicit connection
$agents = Get-VSAAgent

# IMPORTANT: Clear persistent connection when done
[VSAConnection]::ClearPersistentConnection()
# or
Remove-Item env:\VSAConnection -ErrorAction SilentlyContinue
```

### Production Best Practice: Use Windows Credential Manager

For service accounts and production automation:

```powershell
# Store credentials securely (one-time setup)
cmdkey /add:vsaserver /user:vsauser /pass:token

# Retrieve and use in script
$credential = Get-StoredCredential -Target vsaserver  # Requires CredentialManager module
$VSAConnection = New-VSAConnection -VSAServer 'https://vsa.example.com' -Credential $credential
```

## Security Features

### OData Injection Prevention (v0.1.6+)

Filter parameters are automatically escaped to prevent OData injection:

```powershell
# Safe: Special characters are automatically escaped
$agents = Get-VSAAgent -Filter "ComputerName eq 'O''Brien''s Computer'"

# Safe: Attempted injection is escaped and treated as literal
$agents = Get-VSAAgent -Filter "Status eq 'online' or 1 eq 1"
```

### Parameter Validation (v0.1.6+)

All ID parameters are validated to accept only positive integers:

```powershell
# Valid: Numeric IDs only
Remove-VSAAgentNote -ID 12345

# Error: Non-numeric values are rejected with clear message
Remove-VSAAgentNote -ID "ABC123"  # Generates validation error
```

### Credential Security (v0.1.6+)

- **Non-persistent connections**: Credentials stored only in memory during authentication
- **Persistent connections**: Encrypted using Windows DPAPI via ConvertTo-SecureString
- **Automatic cleanup**: PAT cleared from memory using SecureString marshaling

See [SECURITY_HARDENING.md](./SECURITY_HARDENING.md) for complete security details.

## Kaseya VSA API

Visit the [online help](http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/index.asp#home.htm) to find out more about the Kaseya API. Or use your VSA swagger https://[your vsa url]/api/v1.0/swagger/ui/index to see and test the API.

## Release notes

### Version 0.1.6 (Current - Security Hardened)

**Security Improvements:**
- Fixed OData injection vulnerability in filter parameters
- Enhanced ID parameter validation with declarative patterns
- Implemented ConvertTo-SecureString encryption for persistent connections
- Added secure credential cleanup mechanisms
- Comprehensive security documentation and best practices

**New Functions:**
- `Escape-ODataString` - Escapes special characters in OData filters
- `Protect-VSAConnectionData` - Encrypts connection data using DPAPI
- `Unprotect-VSAConnectionData` - Decrypts connection data using DPAPI

**Documentation:**
- New [SECURITY_HARDENING.md](./SECURITY_HARDENING.md) with detailed security implementation
- Enhanced help for `New-VSAConnection` with credential security guidance
- Updated README.md with security best practices and examples

**Backward Compatibility:**
- All changes are backward compatible
- Existing scripts require no modifications
- Security improvements are automatic and transparent

**Module Statistics:**
- 116 public functions
- 81 aliases
- 2 new security functions
- 500+ lines of security documentation

### Version 0.1.5

- Reduced the number of cmdlets while maintaining functionality
- Initial credential storage implementation

### Version 0.1.4

- Updated Copy-VSAMGStructure Function

## Getting Help

### View Available Commands

```powershell
Get-Command -Module VSAModule | Format-Table Name, Synopsis
```

### Get Help for a Specific Command

```powershell
Get-Help Get-VSAAgent -Full
Get-Help New-VSAConnection -Full
```

### Security Questions?

Review [SECURITY_HARDENING.md](./SECURITY_HARDENING.md) for:
- Detailed security implementation
- Best practices for credential handling
- Testing recommendations
- Migration guide
- Production deployment guidelines

## Sponsored

Stay secure and compliant with Kaseya's comprehensive IT management solutions. Visit Kaseya today!

---

## Support and Contributions

For issues, feature requests, or security concerns, please refer to the project repository. Security vulnerabilities should be reported responsibly and not disclosed publicly until a fix is available.

### Documentation Files

- **README.md** (this file) - Quick start and overview
- **SECURITY_HARDENING.md** - Detailed security implementation (v0.1.6+)
- **TESTING_SUMMARY.md** - Test suite documentation
- **VSAModule.psd1** - Module manifest with metadata
- **en-US/VSAModule-help.xml** - MAML-compliant help documentation

### Version Information

- **Current Version**: 0.1.6
- **Module Type**: PowerShell 5.1+
- **Dependencies**: None (built-in PowerShell only)
- **Tested On**: Windows PowerShell 5.1, PowerShell 7.x

