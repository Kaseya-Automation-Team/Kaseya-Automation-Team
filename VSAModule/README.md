# VSAModule

A PowerShell wrapper for the Kaseya VSA 9 REST API. It handles authentication, token renewal, retry, paging, and secure credential storage so you can automate VSA tasks from PowerShell without hand-rolling REST calls.

**Note:** This module simplifies interaction with the Kaseya VSA REST API; it does not modify or impact the behavior of the API itself. Issues or glitches within the REST API are unrelated to the module and should be addressed to Kaseya directly.

**Current version:** 1.7.0 · **License:** [MIT](LICENSE.txt)

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Key Features](#key-features)
- [Security](#security)
- [API Limits](#api-limits)
- [Getting Help](#getting-help)
- [Release Notes](#release-notes)
- [Author](#author)
- [Support and Contributions](#support-and-contributions)

## Requirements

| | Support |
|---|---|
| Windows PowerShell 5.1 | Windows only (5.1 never shipped for any other OS) |
| PowerShell 7.x | Windows, Linux, and macOS |
| Dependencies | None (fully self-contained, no external packages required) |

Persistent-connection encryption is platform-detected: Windows uses DPAPI (user- and machine-bound); Linux/macOS use AES with a key derived at runtime from per-user + per-machine identifiers (weaker than DPAPI, but appropriate since the store itself is only a process-scoped environment variable; see [Security](#security)).

## Installation

Install from the [PowerShell Gallery](https://www.powershellgallery.com/packages/VSAModule):

```powershell
Install-Module -Name VSAModule -Scope CurrentUser
```

## Quick Start

### Recommended: Non-Persistent Connection (Most Secure)

```powershell
begin {
    Import-Module -Name VSAModule -Force

    $VSAUserName = '<Kaseya VSA REST API User Name>'
    $VSAUserPAT  = '<Kaseya VSA REST API User PAT>'

    [securestring]$secStringPassword = ConvertTo-SecureString $VSAUserPAT -AsPlainText -Force
    [pscredential]$VSACred = New-Object System.Management.Automation.PSCredential ($VSAUserName, $secStringPassword)

    # Create non-persistent connection (credentials stored in memory only)
    $VSAConnParams = @{
        VSAServer               = 'https://your-vsa9-server.com'
        Credential              = $VSACred
        IgnoreCertificateErrors = $false  # Use $true only for testing with self-signed certificates
    }

    $VSAConnection = New-VSAConnection @VSAConnParams
}

process {
    $VSAOrganizations = Get-VSAOrganization -VSAConnection $VSAConnection
}

# Connection is automatically cleaned up at end of script
```

### Alternative: Persistent Connection (Interactive Sessions Only)

**WARNING: Use persistent connections only in secure, interactive PowerShell sessions. Not recommended for automated scripts.**

```powershell
# Credentials encrypted with DPAPI on Windows, or a runtime-derived-key AES on Linux/macOS
$VSAConnection = New-VSAConnection `
    -VSAServer 'https://your-vsa9-server.com' `
    -Credential (Get-Credential) `
    -SetPersistent

# Later commands can use the implicit connection
$agents = Get-VSAAgent

# IMPORTANT: Clear the persistent connection when done
[VSAConnection]::ClearPersistentConnection()
# or
Remove-Item env:\VSAConnection -ErrorAction SilentlyContinue
```

### Production Best Practice: Use a Credential Store

For service accounts and production automation, keep the PAT out of the script entirely:

```powershell
# Store credentials securely (one-time setup)
cmdkey /add:vsaserver /user:vsauser /pass:token

# Retrieve and use in script
$credential = Get-StoredCredential -Target vsaserver  # Requires the CredentialManager module
$VSAConnection = New-VSAConnection -VSAServer 'https://vsa.example.com' -Credential $credential
```

## Key Features

- **140 cmdlets, 168 aliases** covering organizations, agents, assets, tickets, staff, roles, scopes, tenants, custom fields, agent procedures, remote-control services, temporary agents, alerts, and more.
- **Automatic paging**: collections are paged transparently via `$skip`/`$top`; no manual loop needed for large result sets.
- **Automatic retry**: transient HTTP errors (429, 502, 503, 504) retry automatically with exponential backoff (and `Retry-After` support).
- **Automatic token renewal**: session tokens are renewed transparently before paged/long-running requests.
- **Uniform `-WhatIf` / `-Confirm`**: every state-changing cmdlet supports `ShouldProcess`.
- **Typed errors**: failed calls throw a `VSAApiException` with `.StatusCode`, `.ConnectionReset`, and `.VSAError`, so scripts can branch on failure kind instead of parsing message text (see [Release Notes](#release-notes), v1.3.0).
- **Native object parameters**: nested request bodies (`-ContactInfo`, `-Attributes`, `-CustomFields`, …) accept a `[hashtable]`/`[pscustomobject]` directly.
- **Zero dependencies**: fully self-contained PowerShell module.

## Security

- **OData injection prevention**: filter values are automatically escaped:

  ```powershell
  # Safe: special characters are automatically escaped
  $agents = Get-VSAAgent -Filter "ComputerName eq 'O''Brien''s Computer'"

  # Safe: an injection attempt is escaped and treated as a literal
  $agents = Get-VSAAgent -Filter "Status eq 'online' or 1 eq 1"
  ```

- **Parameter validation**: ID parameters accept only positive integers:

  ```powershell
  Remove-VSAAgentNote -ID 12345    # Valid
  Remove-VSAAgentNote -ID "ABC123" # Rejected with a clear validation error
  ```

- **Credential handling:**
  - Non-persistent connections keep credentials in memory only, for the life of the session.
  - Persistent connections are encrypted via `ConvertTo-SecureString` using a platform-detected strategy: DPAPI on Windows, runtime-derived-key AES on Linux/macOS.
  - The PAT is cleared from memory via SecureString marshaling after use.
- **HTTPS enforcement** and automatic retry protection against cascading failures.

## API Limits

The Kaseya VSA REST API caps every collection response at **100 records per request**, regardless of the `-Top`/`$top` value requested. The module pages through larger result sets automatically using `$skip`/`$top`.

## Performance: parallel fetching (opt-in)

Large SaaS installations can hold hundreds of thousands of records. Because the API pages 100 at a time, and exposes some data (e.g. service-desk notes) only per parent record, a full sequential fetch can take hours. The module offers an **opt-in** `-Parallel` mode that fetches independent requests concurrently through a single-threaded coordinator that keeps the session token, retries, and rate-limit back-off centralised. It works on both Windows PowerShell 5.1 and PowerShell 7.

```powershell
# Page a large collection concurrently (pages 2..N fetched in parallel)
Get-VSAAgent -VSAConnection $conn -Parallel

# Service-desk tickets, the case parallel fetching exists for
Get-VSASDTicket -VSAConnection $conn -ServiceDeskId $deskId -Parallel

# Every ticket on every desk. The API has no "all tickets" endpoint -- tickets are addressable
# only per service desk -- so enumerate the desks and fetch each one's tickets in parallel.
Get-VSASD -VSAConnection $conn |
    Select-Object -ExpandProperty ServiceDeskId |
    ForEach-Object { Get-VSASDTicket -VSAConnection $conn -ServiceDeskId $_ -Parallel }

# Fan out a per-parent lookup across many ids -- the "N+1" case (e.g. notes for many tickets)
$ticketIds = (Get-VSASDTicketByDesk -VSAConnection $conn -Id $deskId).ServiceDeskTicketId
$allNotes  = Get-VSASDTicketNote -VSAConnection $conn -Id $ticketIds -Parallel -ThrottleLimit 8
```

`-Parallel` is available on **every read cmdlet that returns a paged collection** -- both the data-driven dispatcher aliases and the standalone `Get-VSA*` functions. It is deliberately absent from the three download cmdlets (`Get-VSAAPFile`, `Get-VSAAuditDocument`, `Get-VSAStorageContent`), which stream a single response body to a file and have no pages to fetch concurrently.

Measured on a live VSA SaaS sandbox (default throttle 8): fanning out ticket-note lookups across 200 tickets dropped from **184 s to 21.5 s (8.5×)**, and page-parallelising a 2,000-record (21-page) collection dropped from **32 s to 6.3 s (5.1×)**; both returned byte-identical result sets. Re-measured in v1.6.0 on a real service desk of **2,004 tickets: 13.6 s to 5.6 s (2.4×)**, identical result sets (the smaller multiple simply reflects fewer pages than throttle windows). A throttle sweep (2→32) showed no server throttling and clear diminishing returns past 8, which is why 8 is the default.

Notes:
- **Opt-in and safe by default.** Without `-Parallel`, behaviour is byte-for-byte identical to before. Parallel results are identical to sequential results (same records, merged in `$skip`/id order).
- **`-ThrottleLimit`** (default 8) caps concurrent requests. On shared SaaS you are one tenant among many, so a modest value is a good citizen; the engine also *reduces* concurrency automatically when the server returns HTTP 429, then recovers.
- **Threshold.** Parallel only engages once there is enough work to be worth it (by default two full throttle windows, approximately `2 × ThrottleLimit × 100` records); smaller collections take the sequential path. Override with `-ParallelThreshold <records>`.
- **Token handling is centralised.** The coordinator stamps and renews the session token on its single thread, so token renewal is race-free by construction (a persistent connection works too, since only the coordinator touches it). An explicit `-VSAConnection` is still recommended for long unattended jobs.
- **Complementary tip:** pair `-Parallel` with `-Filter` on a modified-date field (delta sync) so recurring jobs fetch only what changed, often a far bigger win than concurrency alone.
- **`-Filter` caveat: you cannot filter on a large numeric id.** VSA object ids are 15-26 digit strings, but the server types id fields (e.g. `OrgId`) as `Edm.Int32` inside an OData `$filter`, so `Get-VSAOrganization -Filter "OrgId eq <26-digit id>"` fails with **HTTP 400** *"Unrecognized 'Edm.Int32' literal"* (the id overflows Int32). Filter on a string field instead (e.g. `-Filter "OrgRef eq 'acme'"`), or fetch by the id **path** parameter (`-OrgId`/`-Id`), or match client-side. This also means a create-then-read-back must match on a stable non-id field, since the just-issued id is not filterable. (Verified live; related to the `tenant`-endpoint `$filter` trap in the release notes.)

## Getting Help

```powershell
# List all commands
Get-Command -Module VSAModule | Format-Table Name, Synopsis

# Full help for a specific command
Get-Help Get-VSAAgent -Full
Get-Help New-VSAConnection -Full
```

Comment-based help is available on every public cmdlet. For the underlying REST API itself, see the [Kaseya VSA REST API documentation](http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/index.asp#home.htm) or your VSA server's own Swagger UI at `https://<your-vsa-url>/api/v1.0/swagger/ui/index`.

## Release Notes

### Version 1.7.0 (Current)

**One read engine.** The knowledge of "what a VSA response looks like" now lives in a single decode layer shared by the sequential path, the parallel pump and the later-page merge, so the empty-body, status-only, raw-payload and non-JSON-error rules have exactly one definition. A single progress policy covers every long read (on by default and throttled, with its own bar; silence it the standard way with `$ProgressPreference = 'SilentlyContinue'`).

- **`Get-VSAAPList` now returns data**, and gains `-Parallel`. VSA 9 stores Agent Procedures as XML, so the endpoint answers with a Kaseya ScExport document rather than a JSON envelope; the cmdlet feeds an ScExport decoder into the shared read engine and inherits its paging, retry, token renewal and session-invalidation recovery.
- **Correctness.** `Update-VSAOrganization` no longer sends `[decimal]`-cast numbers the server rejects (`7` was serialised as `7.0`), and every 26-digit object id is now a `[string]` module-wide -- they overflow `Int32`/`Int64`.
- **Coherence.** `-Parallel` decodes correctly for every reader; OData paging options are built for `GET` only (a `PUT` no longer goes out as `...?$top=100`); the internal dispatch engines throw an actionable message when called directly.

Full details for this and every earlier release: **[CHANGELOG.md](CHANGELOG.md)**.

## Author

Vladislav Semko

## Support and Contributions

For issues, feature requests, or security concerns, please refer to the project repository. Security vulnerabilities should be reported responsibly and not disclosed publicly until a fix is available.

Built for Kaseya VSA 9 automation. Kaseya offers a broader suite of IT management solutions at [kaseya.com](https://www.kaseya.com).
