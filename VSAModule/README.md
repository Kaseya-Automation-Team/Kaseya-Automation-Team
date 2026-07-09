# About

This module is designed to make it easier to use the Kaseya VSA API in your PowerShell scripts. By handling all the hard work, it allows you to develop your scripts faster and more efficiently. There's no need for a steep learning curve; simply load the module, enter your API keys, and get results within minutes!

**Note:** While this PowerShell module simplifies interaction with the Kaseya VSA REST API, it does not modify or impact the behavior of the API itself. Any issues or glitches that arise within the REST API are unrelated to the module and should be addressed to Kaseya directly.

## 🎉 Version 1.2.0 - Production Ready

**Released: January 27, 2026 · Updated: July 6, 2026**

VSAModule v1.2.0 is a production-ready release with comprehensive REST API coverage, enterprise-grade reliability, and advanced security features.

### ✨ What's New in v1.0

- **Automatic Retry Logic**: Transient HTTP errors (502, 503, 504) automatically retry with exponential backoff (1s, 2s, 4s, 8s...)
- **Automatic Token Renewal**: Session tokens are renewed transparently before making paged/long-running requests
- **Enhanced Security**: Platform-detected encryption for persistent connections (DPAPI on Windows, AES on Linux/macOS), OData injection prevention, HTTPS enforcement
- **112 REST API Cmdlets**: Complete coverage of organizations, agents, assets, tickets, staff, roles, scopes, tenants, and more
- **Comprehensive Testing**: Pester test suite covering transport, auth, structure, and security behavior
- **Zero Dependencies**: Fully self-contained PowerShell module, no external packages required

## Security

**Version 1.0 includes enterprise security features:**
- OData Injection Prevention - User input in filters is automatically escaped
- Parameter Validation - All ID parameters validated against injection attacks
- Credential Encryption - Persistent connections use DPAPI (Windows) or a runtime-derived-key AES (Linux/macOS)
- Secure Cleanup - Credentials cleared from memory after use
- Automatic Retry Protection - Prevents cascading failures with exponential backoff

## Platform Support

Windows PowerShell 5.1 is Windows-only (it never shipped for any other OS). PowerShell 7.x is supported on **Windows, Linux, and macOS**. Persistent-connection encryption is platform-detected: Windows uses DPAPI (user- and machine-bound); Linux/macOS use AES with a key derived at runtime from per-user + per-machine identifiers (weaker than DPAPI, but appropriate since the store itself is only a process-scoped environment variable — see the Release Notes below).

## API Limits

The Kaseya VSA REST API caps every collection response at **100 records per request**, regardless of the `-Top`/`$top` value requested. The module pages through larger result sets automatically using `$skip`/`$top`.

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
# Create persistent connection (credentials encrypted with DPAPI on Windows, or a
# runtime-derived-key AES on Linux/macOS)
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

### OData Injection Prevention

Filter parameters are automatically escaped to prevent OData injection:

```powershell
# Safe: Special characters are automatically escaped
$agents = Get-VSAAgent -Filter "ComputerName eq 'O''Brien''s Computer'"

# Safe: Attempted injection is escaped and treated as literal
$agents = Get-VSAAgent -Filter "Status eq 'online' or 1 eq 1"
```

### Parameter Validation

All ID parameters are validated to accept only positive integers:

```powershell
# Valid: Numeric IDs only
Remove-VSAAgentNote -ID 12345

# Error: Non-numeric values are rejected with clear message
Remove-VSAAgentNote -ID "ABC123"  # Generates validation error
```

### Credential Security

- **Non-persistent connections**: Credentials stored only in memory during authentication
- **Persistent connections**: Encrypted via ConvertTo-SecureString using a platform-detected strategy (DPAPI on Windows, runtime-derived-key AES on Linux/macOS)
- **Automatic cleanup**: PAT cleared from memory using SecureString marshaling

## Kaseya VSA API

Visit the [online help](http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/index.asp#home.htm) to find out more about the Kaseya API. Or use your VSA swagger https://[your vsa url]/api/v1.0/swagger/ui/index to see and test the API.

## Release notes

### Version 1.2.0 (Current)

Write-path (New/Update/Set/…) unified behind two internal helpers:
- **`Invoke-VSAWriteRequest` — one dispatch tail for every write cmdlet.** ~79 `New`/`Update`/`Set`/`Add`/`Enable`/`Disable`/`Start`/`Stop`/`Rename`/`Close`/`Move`/`Send`/`Remove`/`Clear` cmdlets previously hand-copied the same tail (assemble `$Params`, forward the connection, prune the body, serialize JSON, invoke, expand `ExtendedOutput`). That tail now lives in one tested helper, eliminating two whole bug classes by construction: **F-31** (a cmdlet forgetting to forward `-VSAConnection`, so it was silently ignored — this had already bitten `New-VSAAgentInstallPkg`) and **F-52** (pruning a body with `-not $BodyHT[$key]`, which dropped a legitimate `0`/`$false`/`''` — now only `$null`/empty-string are pruned, so an explicit `0`/`$false` is transmitted). JSON is also serialized at a single consistent depth (10) rather than the old per-cmdlet default of 2, which silently truncated deeper bodies.
- **`ConvertTo-VSARequestBody` — body assembly from bound parameters.** Replaces the repeated `foreach ($key in $AllFields) { if ($PSBoundParameters.ContainsKey($key)) … }` loops (membership by `ContainsKey`, never truthiness), with optional parameter→body-field renaming.
- Adds `Tests/VSAModule.WriteRequest.Tests.ps1` (12 tests). Full behavior preserved — the existing suite stayed green throughout and the whole flow was live-verified end-to-end against a VSA server.

### Version 1.1.2

Structured nested-object parameters (backward-compatible):
- **Native objects for nested parameters:** `-ContactInfo`, `-Attributes`, `-CustomFields` (and `New-VSATenant -LicenseValues`) now accept a `[hashtable]` or `[pscustomobject]` directly — e.g. `New-VSAOrganization -ContactInfo @{ PrimaryEmail = 'a@b.com'; City = 'New York' }`. The legacy `"{ Key= value; ... }"` string form still works. All parsing is centralized in one private helper, `ConvertTo-VSAHashtable`, replacing seven copies of a `-match '{(.*?)\}'` + `ConvertFrom-StringData` idiom that corrupted any value containing `}`, `;`, `=`, or `\` and depended on the pipeline-global `$Matches`.
- **Latent bug fixes surfaced by the refactor:** `New-VSATenant -Attributes` was declared `[hashtable]` but string-parsed (so a real hashtable never worked) and its Attributes block was duplicated (a non-empty value threw on the second `.Add`); `New-VSAOrganization -CustomFields` used `ArrayList.AddRange` on a hashtable, flattening each field object into loose dictionary entries. All fixed.
- Adds `Tests/VSAModule.NestedObject.Tests.ps1` (19 tests).

### Version 1.1.1

Cross-platform persistent-connection support:
- **F-60 (cross-platform persistence):** `SetPersistent` now works correctly on Linux/macOS. Previously, encryption silently fell back to PowerShell's no-key `ConvertTo-SecureString`, which "succeeds" on non-Windows but is trivially reversible with no key at all (obfuscation, not encryption). The module now detects the platform once at import and selects a real encryption strategy: DPAPI on Windows (unchanged), or AES with a 32-byte key derived at runtime from per-user + per-machine identifiers on Linux/macOS — the key is never stored, only re-derived on demand. `CompatiblePSEditions` now declares both `Desktop` and `Core`.

### Version 1.1.0

Windows PowerShell 5.1 certificate-bypass and TLS hardening fixes:
- **F-27b (cert-bypass regression):** Fixed `IgnoreCertificateErrors` on WinPS 5.1 by replacing a PowerShell scriptblock callback (which can't run on the TLS handshake thread) with a compiled `ICertificatePolicy` type. Feature-detected at module load; Core uses `-SkipCertificateCheck`.
- **TLS protocol hardening:** Framework branch now pins `TLS 1.2 + TLS 1.3` (when available) outright, never OR-ing into the host's existing protocols (which may still carry SSL3/TLS1.0); maintains backward compat via explicit floor.
- Edition-specific strategies now centralized in one load-time region, feature-detected on `-SkipCertificateCheck` capability.

### Version 1.0.0

Security- and reliability-hardened rewrite of the transport, authentication, and connection-persistence layers:
- OData injection prevention in filter parameters (`ConvertTo-ODataString`, applied internally)
- Declarative ID parameter validation (positive integers only)
- Persistent connections encrypted via `Protect-VSAConnectionData` / `Unprotect-VSAConnectionData` (Windows DPAPI at the time; see v1.1.1 for the cross-platform strategy)
- Automatic retry with exponential backoff on transient HTTP errors, and `Retry-After` support
- Automatic session-token renewal ahead of paged/long-running requests
- Mandatory-`VSAConnection` requirement removed from all public cmdlets; every public function accepts either an explicit or a persistent connection

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

See the "Security" and "Security Features" sections above, or run `Get-Help New-VSAConnection -Full` for credential-handling guidance.

## Sponsored

Stay secure and compliant with Kaseya's comprehensive IT management solutions. Visit Kaseya today!

---

## Support and Contributions

For issues, feature requests, or security concerns, please refer to the project repository. Security vulnerabilities should be reported responsibly and not disclosed publicly until a fix is available.

### Documentation Files

- **README.md** (this file) - Quick start and overview
- **VSAModule.psd1** - Module manifest with metadata
- Comment-based help on every public cmdlet (`Get-Help <CmdletName> -Full`)

### Version Information

- **Current Version**: 1.2.0
- **Module Type**: PowerShell 5.1+ (5.1 is Windows-only; PowerShell 7.x also runs on Linux/macOS)
- **Dependencies**: None (built-in PowerShell only)
- **Tested On**: Windows PowerShell 5.1 (Windows), PowerShell 7.x (Windows, Linux)

