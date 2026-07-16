# VSAModule

A PowerShell wrapper for the Kaseya VSA 9 REST API. It handles authentication, token renewal, retry, paging, and secure credential storage so you can automate VSA tasks from PowerShell without hand-rolling REST calls.

**Note:** This module simplifies interaction with the Kaseya VSA REST API; it does not modify or impact the behavior of the API itself. Issues or glitches within the REST API are unrelated to the module and should be addressed to Kaseya directly.

**Current version:** 1.6.0 · **License:** [MIT](LICENSE.txt)

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

- **139 cmdlets, 169 aliases** covering organizations, agents, assets, tickets, staff, roles, scopes, tenants, custom fields, agent procedures, remote-control services, temporary agents, alerts, and more.
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

### Version 1.6.0 (Current)

Two things land together: **one HTTP stack** (an internal transport unification), and the correctness fixes from the v1.5.0 full-surface sandbox testing pass ([TESTING-REPORT-v1.5.0.md](TESTING-REPORT-v1.5.0.md)). The public API is unchanged; the minor bump signals the transport replacement, matching the precedent set by v1.2.0's write-path refactor.

#### One HTTP stack

Before this release the module made HTTP calls two different ways: `Invoke-RestMethod` on the sequential path and `System.Net.Http.HttpClient` in the v1.5.0 parallel engine. Each carried its own copy of the retry rules, envelope handling and error typing, and those copies **had already drifted** -- so this was not merely untidy, it was a source of live defects.

Everything now goes through HttpClient, with a single definition of each policy shared verbatim by both paths (`private/Invoke-VSAHttp.ps1`): one retry-status set, one back-off rule, one envelope classifier (`Resolve-VSAResponse`), one error factory (`New-VSATransportError`). `Get-RequestData` is now a thin sequential adapter over that stack and contains no HTTP logic of its own. The parallel engine keeps exactly one thing of its own -- the asynchronous pump and its adaptive window -- because that is the only genuine difference between the two modes. Four divergences are fixed as a result:

- **Typed errors now work under `-Parallel`.** The parallel path re-threw the raw transport exception, so `.StatusCode` / `.ConnectionReset` branching (the v1.3.0 typed-error contract) silently did not work for parallel callers. Both paths now build errors identically.
- **`Retry-After` is honoured under `-Parallel`.** The parallel path ignored the server's own back-off hint -- precisely where it matters most, since a throttling SaaS answers a wide window with 429s.
- **The raw non-enveloped payload rule (F-63) and the unexpected-response guard now apply to both paths**; they previously existed only on the sequential path.
- **One shared, cached HttpClient** replaces per-call client construction (which leaked a socket into `TIME_WAIT` on every parallel batch).

**Windows PowerShell 5.1:** the module now loads `System.Net.Http` at import. On .NET Core that assembly is part of the shared framework, but on .NET Framework it is separate and not loaded by default, so `New-VSAConnection` failed with `Unable to find type [System.Net.Http.HttpClient]`. It cannot be loaded lazily inside the transport: PowerShell compiles a function body on first invocation and resolves every type literal in it at that moment, so an `Add-Type` in the same function always runs too late. (This also fixes the same latent fault in the v1.5.0 parallel engine.)

Secondary benefits: HttpClient does not throw on 4xx/5xx, so error bodies are simply read rather than reconstructed from an `ErrorRecord` -- which retired the edition-branching `Get-VSAErrorBody` / `Get-VSAHttpStatus` helpers entirely, along with the `-SkipCertificateCheck` request-splat strategy that only `Invoke-RestMethod` needed. Transport tests now run the real stack against a fake `HttpMessageHandler` instead of mocking a library the module no longer uses, so the retry loop, `Retry-After` parsing, header/body construction and error typing are genuinely executed. Certificate handling is unchanged: PowerShell 7 uses a per-handler validator, and Windows PowerShell 5.1 continues to use the process-wide `ICertificatePolicy` that HttpClient honours there.

#### `-Parallel` now covers every paged read

v1.5.0 added `-Parallel` only to the three data-driven dispatchers, so it reached the ~120 dispatcher aliases but **none of the 29 standalone `Get-VSA*` functions** -- including `Get-VSASDTicket` and `Get-VSAAgent`. Service-desk tickets were the motivating case for the feature, and `Get-VSAAgent -Parallel` was the README's own headline example, yet both failed with *"A parameter cannot be found that matches parameter name 'Parallel'"*. The shared read path (`Invoke-VSARestMethod`) already supported the whole trio; these functions simply never declared or forwarded it.

- **`-Parallel`, `-ThrottleLimit` and `-ParallelThreshold` added to the 24 standalone read functions that page a collection**, forwarding to the same engine the dispatchers use. Excluded: the three download cmdlets (`Get-VSAAPFile`, `Get-VSAAuditDocument`, `Get-VSAStorageContent`), which stream one body to a file and have no pages to parallelise. Verified live: each returns results identical to its sequential path.
- **Fixed: a single-page collection with an explicit low `-ParallelThreshold` threw** `Cannot validate argument on parameter 'Request'`. Passing the threshold test with everything already in page 1 built an *empty* pages-2..N list and handed it to the pump. Parallel now also requires a page 2 to exist. The default auto-threshold sits far above one page, which is why this only surfaced once a low threshold was set explicitly.
- **`Get-VSASDTicket` now explains itself.** It requires exactly one of `-ServiceDeskId` / `-ServiceDeskTicketId` because the API has no "all tickets" collection (a bare `api/v1.0/automation/servicedesktickets` returns HTTP 403). The old message stated the rule but not where ids come from; it now names `Get-VSASD` and shows the all-desks recipe.

#### Found by real (non-`-WhatIf`) writes against a live VSA

`-WhatIf` stops at `ShouldProcess` and never reaches the transport, so it can only prove that parameters bind. Exercising the write surface for real - creating disposable entities, mutating them, verifying by read-back, then deleting them - found two defects it could not have:

- **`Update-VSAStaff` failed with HTTP 500 unless `-Function` was supplied.** The backend stored procedure takes that field as its `@purpose` argument and rejects the entire update when the key is absent (*"expects parameter '@purpose', which was not supplied"*). It had historically been sent unconditionally for precisely this reason; the v1.2.0 prune-by-bound-state change (F-52) made it conditional and silently reintroduced the failure. It is now always sent: an explicit `-Function` is honoured, and when omitted the record's **current** value is read back and re-sent, so the update succeeds without wiping the staff member's real job function.
- **A blocked write endpoint no longer burns a retry storm.** The v1.6.0 transport treated *any* transport error as transient, so a connection reset - which is exactly how a hardened (post-2021) VSA answers a blocked write - was retried 3 times over ~7 s with three alarming warnings before returning the same result. Retries now follow one shared rule (`Test-VSARetryable`): a transient HTTP status (429/502/503/504) is retried for any method, because the server told us it did not process the request; a **no-response** is retried only for **idempotent** methods, because otherwise the server may have applied the write before the socket dropped and a retry could duplicate it. Blocked writes now fail in under a second, still typed `ConnectionReset`; parallel read fan-outs (GET-only) still survive a socket blip.

#### Consistency and documentation

A full audit for inconsistencies (create/update parameter drift, `-Force` semantics, help completeness, file encodings), with every fix verified:

- **`Update-VSAOrganization` now accepts `-OrgName`** (alias). The create/update pair disagreed on what to call the same value: `New-VSAOrganization` takes `-OrgName`, the update took only `-OrganizationName` -- even though the API's own body field is `OrgName`. Both spellings are live-verified to drive a real update; the canonical name is unchanged.
- **Dead help resurrected.** `Publish-VSADocument` and `Publish-VSACustomExtensionFile` declared `.PARAMETER $DestinationFolder` -- with a `$`, which PowerShell's help parser does not bind, so the descriptions were silently invisible. `Get-Help` now renders them.
- **All remaining `.PARAMETER` gaps closed: 35 functions -> 0.** Each description was written from the parameter's actual behaviour, verified by `Get-Help` rendering the text rather than merely by its presence in the file.
- **`-Force` is documented for what it really is.** On `Remove-VSARCService` it sends the API's own `force=true` flag; on `Remove-VSASessionTimer` it switches the request from DELETE to PATCH. Neither is a confirmation bypass, and both now say so explicitly, pointing to `-Confirm:$false` instead.
- **Line endings normalised** to the module's dominant CRLF: 3 files that were internally mixed are fixed, and 154 of 155 files are now consistent. Each rewrite was proved token-equivalent before being written. `private/Get-RequestData.ps1` is left as it is by choice: it embeds the `VSAApiException` C# class in an `Add-Type` here-string, where the line endings are part of a string literal's value rather than mere formatting. It works, and working embedded code is not worth rewriting for cosmetics.
- **`New-VSAOrganization` documents the server's propagation lag**: the returned `OrgId` is not queryable or updatable for a second or two (the API answers HTTP 404 "Org does not exist" until then), which matters when chaining a create straight into an update.

#### Correctness fixes

- **Unresolved name lookups can no longer reach the wire (8 cmdlets).** Cmdlets that accept a friendly `-*Name` and resolve it to an Id assigned the lookup result straight back onto the parameter. When a name did not resolve, this either masked the real error behind a misleading `"Non-numeric Id"` (from the parameter's own validator re-firing), or - worse - sent the unresolved value. Most severe: `Clear-VSATenantRoleType` typed `$RoleTypeId` as `[int]`, so an unknown `-RoleTypeName` coerced `$null` to `0` and **silently issued `DELETE .../roletypes/{tenant}?roleTypeId=0`**; `Update-VSAUser` had no not-found check at all. All eight now resolve into a local, verify it, and only then assign - so the accurate "not found" message survives and the unresolved case cannot be sent. Affected: `Clear-VSATenantRoleType`, `Disable-VSATenant`, `Enable-VSAUser`, `Remove-VSAUser`, `Set-VSATenantModuleLicense`, `Set-VSATenantModuleUsageType`, `Set-VSATenantRoletypeLimit`, `Update-VSAUser`.
- **`Clear-VSATenantRoleType -RoleTypeId` retyped `[int]` -> validated `[string]`**, matching every other Id in the module and removing the zero-coercion trap. VSA object ids are large numeric strings (the sandbox tenant id is 26 digits, overflowing both `[int]` and `[int64]`).
- **`Update-VSAUser` no longer silently drops a field** when `-DefaultStaffOrgName`, `-AdminRoleNames` or `-AdminScopeNames` resolve to nothing; it now throws instead of omitting the key from the request body.
- **`New-VSALCAuditLog -AgentName` now defaults to `'VSAModule'`.** The server rejects an empty `AgentName` with HTTP 400, so the cmdlet's own documented one-argument example (`-AgentId` + `-Message`) previously failed against a live server. The help had always promised this default; it is now implemented.
- **Help accuracy.** Documented `Set-VSATenantModuleLicense`'s `-zzVal` / `-LicenseType` / `-LicenseName` and both parameter sets, and added self-describing aliases `-LicenseValueId` / `-LicenseValue` (the `zz` names are the Kaseya API's own field names, sent verbatim, so they are kept). Added the missing `DynamicParam` recurrence docs to `New-VSAAPScheduled`, `New-VSAPatchScan`, `Set-VSAPatchIgnore` and `Start-VSAPatchUpdate`. Fixed a `Magniture` -> `Magnitude` typo that documented a nonexistent parameter while the real one went undocumented (3 cmdlets), and removed 10 `.PARAMETER` entries describing parameters that do not exist.
- **Documented a server-side trap:** the `tenant` endpoint silently ignores `$filter` (it returns rows even for a filter matching nothing), unlike `users`/`roletypes`/`orgs`/`agents`/`scopes`/`roles`, which validate it server-side. Tenant name resolution is therefore deliberately client-side and must not be "optimised" to use `$filter`. See the report's Section 2.

#### Uniform `-WhatIf` safety across the whole write surface

- **`Copy-VSAOrgStructure` and `Copy-VSAMGStructure` now support `-WhatIf`.** These were the only two mutating cmdlets in the module without it - and the highest-blast-radius ones, mass-creating an entire organization or machine-group tree on a destination VSA. They compose public cmdlets rather than the write chokepoint, so they now call `ShouldProcess` directly, gating the whole create-and-verify block: under `-WhatIf` they print exactly what would be created and the 60-second server read-back wait is skipped. Live-verified against the sandbox - nothing is created, and the run takes a second rather than spinning in the wait loop.
- **The module-wide `PSShouldProcess` analyzer warning is resolved, not just tolerated.** Centralising `ShouldProcess` in `Invoke-VSAWriteRequest` (invoked with each cmdlet's `$PSCmdlet` via `-Caller`) is deliberate, but static analysers cannot see the delegation and flagged all ~96 delegating write cmdlets. Each now carries a `SuppressMessageAttribute` with a justification naming the pattern, so the tooling agrees with the architecture and the rationale is documented in place. Guarded by tests that fail if a new mutating cmdlet is added without either a `ShouldProcess` call or the justified suppression.

### Version 1.5.0

Performance release: **opt-in parallel fetching** for large SaaS installations, where a full sequential fetch (especially per-parent lookups like service-desk notes) can otherwise take hours. Additive and backward-compatible: without `-Parallel`, every command behaves exactly as before. Dual-edition (Windows PowerShell 5.1 and PowerShell 7). See [Performance: parallel fetching](#performance-parallel-fetching-opt-in).

- **New coordinator engine** (`Invoke-VSAParallelRequest`, private): a single-threaded pump running a sliding window of up to `-ThrottleLimit` concurrent `HttpClient` requests. Because dispatch happens on one thread, the session token is stamped and renewed **single-flight by construction** (no lock, no race), and a mid-run 401 (SaaS session cut short) triggers exactly one forced renewal rather than a stampede. Transient failures (429/502/503/504) retry with capped back-off, and a 429 also shrinks the active window adaptively, then recovers.
- **`Get-VSAItem … -Parallel`** pages a large collection concurrently (pages 2..N), engaging only past a threshold (default two throttle windows) since page 1 already reports the exact total.
- **`Get-VSAItemById -Id <array> -Parallel`** fans a per-id lookup across many ids (the N+1 case, e.g. `Get-VSASDTicketNote -Id $ticketIds -Parallel`), via `Invoke-VSABatchGet`, fully paging each id.
- **5.1 correctness:** the .NET Framework default 2-connections-per-host cap is raised to the window width, so a wide throttle is genuinely parallel rather than silently serialised behind two sockets.
- Parallel results are verified identical to sequential results (same records, `$skip`/id order). Adds `Tests/VSAModule.Parallel.Tests.ps1`.
- **Measured live** (SaaS sandbox, throttle 8): ticket-note fan-out across 200 tickets **184 s → 21.5 s (8.5×)**; a 21-page collection **32 s → 6.3 s (5.1×)**; a 2→32 throttle sweep confirmed no server throttling and diminishing returns past 8.

### Version 1.4.0

Broad coverage expansion driven by a full diff against the live VSA Swagger: **31 new read/remove commands** added as endpoint-map entries on the existing data-driven dispatchers (no new files), plus **24 new write functions** built on the shared write path. Everything was exercised against a live VSA server. The internal machine-to-machine surface (agent-to-server replication, BMS/IT Glue integration, clustering, policy/event-set editor internals) is intentionally excluded: it is not admin-callable.

- **31 new commands (aliases on the generic dispatchers):**
  - *Remote control:* `Get-VSARCService`, `Get-VSARCServiceByAsset`, `Get-VSARCMachine`, `Get-VSARCMachineByView`
  - *Temporary agents:* `Get-VSATemporaryAgent`, `Get-VSATemporaryAgentConfig`, `Remove-VSATemporaryAgent`
  - *Agent procedures:* `Get-VSAAPList`, `Get-VSAAPProcHistory`, `Get-VSAAPExecHistory`, `Get-VSAAPPrompt`, `Get-VSAAPPromptById`, `Get-VSAAPVariable`
  - *Agents / assets:* `Get-VSAAgentActiveAdmin`, `Get-VSAAgentUserProfile`, `Get-VSAAgentUpdateSchedule`, `Get-VSAAssetById`, `Get-VSAAssetAudit`
  - *Alerts, orgs, tenants:* `Get-VSAAlertDefinition`, `Get-VSAOrgType`, `Get-VSAOrgLocation`, `Get-VSATenantLogonPolicy`, `Get-VSATenantDefaultSetting`
  - *Service desk, backup, misc:* `Get-VSASDTicketByDesk`, `Get-VSASDTicketById`, `Get-VSACBStatus`, `Get-VSAFunctionById`, and the document aggregations `Get-VSADocumentServiceAudit` / `Get-VSADocumentVolumeLabel` / `Get-VSADocumentServiceName` / `Get-VSADocumentDistinctVolumeLabel`
- 29 of the 31 returned live data on the test server; `Get-VSASDTicketById` and `Get-VSATenantLogonPolicy` resolved to the correct path but returned a server-side HTTP 500 on that particular instance at the time (their paths matched the Swagger exactly). Update (v1.5.0 testing pass): `Get-VSASDTicketById` now succeeds when given a ticket id from a well-formed service desk; the earlier 500 was specific to the ticket used at the time, not the endpoint. `Get-VSATenantLogonPolicy` still returns a server-side HTTP 500 on this instance.
- **24 new write functions** (real cmdlets on the shared `Invoke-VSAWriteRequest` / `ConvertTo-VSARequestBody` base, with uniform `-WhatIf`/`-Confirm`):
  - *Remote control services:* `New-VSARCService`, `Set-VSARCService`, `Remove-VSARCService`, `Set-VSAAssetProxy`, `Set-VSAAssetService`
  - *Temporary agents:* `New-VSATemporaryAgent`, `Set-VSATemporaryAgentName`, `New-VSATemporaryAgentNote`, `Send-VSATemporaryAgentEmail`
  - *Agent / asset lifecycle:* `Suspend-VSAAgent`, `Start-VSAAgentUpgrade`, `Convert-VSAAssetToDevice`, `Convert-VSADeviceToAsset`, `Publish-VSADevice`
  - *Alerts:* `Set-VSAAgentAlert`, `Set-VSASystemAlert`, `Get-VSAAlertTracking`
  - *Automation / patch / service desk / org:* `Start-VSAAPReturnId`, `Stop-VSAPatchSchedule`, `New-VSASDTicket`, `Get-VSAOrgNetwork`
  - *User management:* `Set-VSAUserPassword`, `Reset-VSAUserPassword`, `Close-VSAUserSession` (user-mutation endpoints; may be network-blocked on hardened post-2021 builds)
- Adds `Tests/VSAModule.EndpointMaps.Tests.ps1`, which enforces that every map alias resolves to the right dispatcher and is declared in the manifest's `AliasesToExport`.

### Version 1.3.3

Maintenance and help-accuracy release: dead-code cleanup, packaging tidy-up, and fixes to advertised-but-broken behavior. No cmdlets or parameters added or removed, nothing breaking:
- **Fix: `Get-Help` showed no synopsis or description for five user cmdlets.** `Disable-VSAUser`, `Enable-VSAUser`, `Remove-VSAUser`, `Update-VSAUser`, and `Add-VSAUserToRole` displayed only auto-generated syntax. Their `.NOTES` prose wrapped so a line began with `.StatusCode …`, which PowerShell's comment-based-help parser read as an unknown help directive and used to discard the entire help block. The wording was adjusted so no line starts with a `.token`; `Get-Help` now shows the intended help.
- **Fix: `Get-VSATenantModuleLicense` and `Get-VSATenantRoletypeFunclist` ignored `-Filter`/`-Sort`.** Both cmdlets declared and documented these parameters but never passed them to the transport, so they were silently discarded. They are now forwarded as the OData `$filter`/`$orderby` query the rest of the module uses (verified live: the server accepts them). The stale `.PARAMETER ResolveIDs` help entry, which described a parameter neither cmdlet has, was removed.
- **Maintenance: removed redundant packaging and dead files.** Deleted the checked-in `VSAModule.nuspec`: a generated packaging snapshot that only duplicated `VSAModule.psd1` (which is the authoritative source of the id, version, description, URLs, release notes, and tags) and is ignored by `Publish-Module`, which regenerates its own from the manifest. Also removed the leftover NuGet OPC artifacts (`_rels/`, `package/`, `[Content_Types].xml`) and the inert external MAML help file (`en-US/VSAModule-help.xml`; comment-based help always shadowed it, so `Get-Help` never surfaced it), plus a few dead `#[CmdletBinding()]` comment lines and a duplicate `Export-ModuleMember` line. No public surface changed.
- **Maintenance: de-duplicated the dynamic-parameter helper.** Six schedule/recurrence cmdlets (`Set-VSAAuditSchedule`, `Set-VSAScheduleAuditSysInfo`, `Set-VSAPatchIgnore`, `New-VSAScheduleAuditBaseLine`, `New-VSAAPScheduled`, `Start-VSAPatchUpdate`) each carried an identical copy of a `New-VSARuntimeParameter` helper inside their `DynamicParam` block (one was even named differently). They now share a single private helper (`private/New-VSARuntimeParameter.ps1`), which is visible to each `DynamicParam` block because those run in module scope. No behavior change: the dynamic recurrence parameters (`DaysOfWeek`, `DayOfMonth`, `MonthOfYear`, `Times`, and others) and their validation are identical; verified live against a VSA server.
- **Maintenance: normalized source formatting.** A whitespace-only pass across the module stripped trailing whitespace, re-indented the debug/verbose logging lines to their block depth, and collapsed stray multi-blank-line runs. Every file was verified token-equivalent (parsed before/after; all non-whitespace tokens identical), so the change is provably behavior-preserving.
- **Tests:** the help suite (`Tests/VSAModule.Help.Tests.ps1`) was rewritten to validate the comment-based help actually surfaced by `Get-Help` for every public function, rather than the removed MAML file. Adds `Tests/VSAModule.RuntimeParameter.Tests.ps1` and `Tests/VSAModule.FilterSort.Tests.ps1`.

### Version 1.3.2

Fixes found during a full-module acceptance test against a live VSA server (no cmdlets added or removed):
- **Fix: Cloud Backup cmdlets returned no data.** `Get-VSACBServer(s)`, `Get-VSACBWS`, and `Get-VSACBVM` always threw *"Unexpected API response"*. The Cloud Backup (`kcb/*`) endpoints return a bare JSON object (a flat `{ <agentId>: <status> }` map) with none of the standard `{Result, ResponseCode, Status, Error}` envelope fields, and the transport mistook that for a broken envelope. The transport now recognizes a genuinely non-enveloped payload and returns it as-is (a status-only envelope still yields an empty result, unchanged).
- **Fix: tenant role-type cmdlets couldn't target instance-specific role types.** `Enable-VSATenantRoleType` / `Clear-VSATenantRoleType` validated `-RoleType`/`-RoleTypeName` against a hardcoded list and resolved names via a static name→Id map, so real role types that exist on an instance (e.g. `Multi-Tenant`, `Multi-Tenant Admin`, or any custom/tenant role type) could never be selected. Both now resolve names to Ids at runtime via `Get-VSARoleType` (with tab-completion and a clear error listing the available role types), matching `Set-VSATenantRoletypeLimit`, which already worked this way. The stale `$TenantRoleTypeIdMap` was removed.
- **Fix: `New-VSALCAuditLog -Message`** was documented as required but declared optional; omitting it sent a null log message and the server returned HTTP 400. It is now mandatory.
- **Fix: `Send-VSAEmail -UniqueTag`** was declared mandatory but the function body already treats it as optional; it is now optional, so a `UniqueTag` is no longer forced on every email.
- **Fix: `Set-VSATenantModuleUsageType` parameter sets were cross-wired.** `TenantId`/`ModuleName` were grouped in one set and `ModuleId`/`TenantName` in the other, so the two natural calls (`-TenantId <id> -ModuleId <id>` and `-TenantName <name> -ModuleName <name>`) could not be satisfied (*"Parameter set cannot be resolved"*); only awkward id-of-one-with-name-of-the-other combinations worked. The sets are now `ById = {TenantId, ModuleId}` and `ByName = {TenantName, ModuleName}` (and the examples were corrected). Found during a full coverage sweep of every function and alias.
- **Fix: `New-VSASDTicketNote -Hidden` and `-SystemFlag` were mandatory switches.** A `[switch]` that must always be supplied is a contradiction: it forced `-Hidden -SystemFlag` on every call just to create an ordinary ticket note. Both are now optional and default to `$false` (which the body already handled).
- **Fix: the multipart upload cmdlets ignored `-WhatIf`/`-Confirm`.** `Publish-VSADocument` and `Publish-VSACustomExtensionFile` (which build a raw multipart body and don't route through the shared write dispatcher) did not support `ShouldProcess`, unlike every other write cmdlet. They now honor `-WhatIf`/`-Confirm`, so a dry run no longer uploads.
- Adds `Tests/VSAModule.RawPayload.Tests.ps1` and `Tests/VSAModule.ParamContract.Tests.ps1`.

### Version 1.3.1

- **Fix: `New-VSAOrganization -CustomFields` with a single field.** A lone custom field was serialized as a bare JSON object instead of a one-element array, which the VSA API rejected with an HTTP 400. Passing two or more fields worked, so this only affected the single-field case. (Root cause: a `$(...)` subexpression around `ToArray()` unwrapped the single-element array to its scalar element. Live-found during full-module acceptance testing against a VSA server; the offline mock hid it because a bare object round-trips through `ConvertFrom-Json` like a one-element array.) Adds raw-JSON-shape regression tests.

### Version 1.3.0

Uniform `-WhatIf`/`-Confirm`, typed API errors, and structural cleanup:
- **Uniform ShouldProcess.** Every state-changing cmdlet now honors `-WhatIf`/`-Confirm`. The gate is centralized in `Invoke-VSAWriteRequest` (via a `-Caller $PSCmdlet` hand-off), so `-WhatIf` short-circuits the request before it is sent. This also fixes the cmdlets that previously *declared* `SupportsShouldProcess` but never called it (so `-WhatIf` was silently ignored).
- **Typed API errors.** Failed calls now throw a `VSAApiException` inside a properly-categorized `ErrorRecord`, so callers can branch programmatically instead of parsing message strings: `$_.Exception.StatusCode` (int; `0` = no HTTP response), `$_.Exception.ConnectionReset` (`$true` when the socket was reset), `$_.Exception.VSAError`, and `$_.CategoryInfo.Category` (`PermissionDenied` for 403, `ObjectNotFound` for 404, `ConnectionError` for a reset). **Note:** on hardened (post-2021) VSA builds, user-mutation endpoints (`Update`/`Remove`/`Enable`/`Disable-VSAUser`, `Add-VSAUserToRole`) are blocked at the network layer: the connection is reset (`ConnectionReset = $true`, `StatusCode = 0`) rather than returning a 403/404. Read-only user cmdlets are unaffected. This is a VSA-side restriction, not a module limitation.
- **Structural cleanup.** Endpoint/id maps extracted from the `.psm1` monolith into a dot-sourced `private/VSAEndpointMaps.ps1`; the 17 empty completer `catch {}` blocks now emit a `Write-Debug` diagnostic; dead `-CustomFields` parameter removed from `Update-VSAOrganization`.
- Adds `Tests/VSAModule.TypedError.Tests.ps1` (9 tests) and `-WhatIf` gate tests. Full suite green; live-verified against a VSA server (404 → `ObjectNotFound`, blocked user writes → `ConnectionReset`).

### Version 1.2.0

Write-path (New/Update/Set/…) unified behind two internal helpers:
- **`Invoke-VSAWriteRequest`: one dispatch tail for every write cmdlet.** ~79 `New`/`Update`/`Set`/`Add`/`Enable`/`Disable`/`Start`/`Stop`/`Rename`/`Close`/`Move`/`Send`/`Remove`/`Clear` cmdlets previously hand-copied the same tail (assemble `$Params`, forward the connection, prune the body, serialize JSON, invoke, expand `ExtendedOutput`). That tail now lives in one tested helper, eliminating two whole bug classes by construction: **F-31** (a cmdlet forgetting to forward `-VSAConnection`, so it was silently ignored; this had already bitten `New-VSAAgentInstallPkg`) and **F-52** (pruning a body with `-not $BodyHT[$key]`, which dropped a legitimate `0`/`$false`/`''`; now only `$null`/empty-string are pruned, so an explicit `0`/`$false` is transmitted). JSON is also serialized at a single consistent depth (10) rather than the old per-cmdlet default of 2, which silently truncated deeper bodies.
- **`ConvertTo-VSARequestBody`: body assembly from bound parameters.** Replaces the repeated `foreach ($key in $AllFields) { if ($PSBoundParameters.ContainsKey($key)) ... }` loops (membership by `ContainsKey`, never truthiness), with optional parameter-to-body-field renaming.
- Adds `Tests/VSAModule.WriteRequest.Tests.ps1` (12 tests). Full behavior preserved: the existing suite stayed green throughout and the whole flow was live-verified end-to-end against a VSA server.

### Version 1.1.2

Structured nested-object parameters (backward-compatible):
- **Native objects for nested parameters:** `-ContactInfo`, `-Attributes`, `-CustomFields` (and `New-VSATenant -LicenseValues`) now accept a `[hashtable]` or `[pscustomobject]` directly (e.g. `New-VSAOrganization -ContactInfo @{ PrimaryEmail = 'a@b.com'; City = 'New York' }`). The legacy `"{ Key= value; ... }"` string form still works. All parsing is centralized in one private helper, `ConvertTo-VSAHashtable`, replacing seven copies of a `-match '{(.*?)\}'` + `ConvertFrom-StringData` idiom that corrupted any value containing `}`, `;`, `=`, or `\` and depended on the pipeline-global `$Matches`.
- **Latent bug fixes surfaced by the refactor:** `New-VSATenant -Attributes` was declared `[hashtable]` but string-parsed (so a real hashtable never worked) and its Attributes block was duplicated (a non-empty value threw on the second `.Add`); `New-VSAOrganization -CustomFields` used `ArrayList.AddRange` on a hashtable, flattening each field object into loose dictionary entries. All fixed.
- Adds `Tests/VSAModule.NestedObject.Tests.ps1` (19 tests).

### Version 1.1.1

Cross-platform persistent-connection support:
- **F-60 (cross-platform persistence):** `SetPersistent` now works correctly on Linux/macOS. Previously, encryption silently fell back to PowerShell's no-key `ConvertTo-SecureString`, which "succeeds" on non-Windows but is trivially reversible with no key at all (obfuscation, not encryption). The module now detects the platform once at import and selects a real encryption strategy: DPAPI on Windows (unchanged), or AES with a 32-byte key derived at runtime from per-user + per-machine identifiers on Linux/macOS; the key is never stored, only re-derived on demand. `CompatiblePSEditions` now declares both `Desktop` and `Core`.

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

## Author

Vladislav Semko

## Support and Contributions

For issues, feature requests, or security concerns, please refer to the project repository. Security vulnerabilities should be reported responsibly and not disclosed publicly until a fix is available.

Built for Kaseya VSA 9 automation. Kaseya offers a broader suite of IT management solutions at [kaseya.com](https://www.kaseya.com).
