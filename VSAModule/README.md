# VSAModule

A PowerShell wrapper for the Kaseya VSA 9 REST API. It handles authentication, token renewal, retry, paging, and secure credential storage so you can automate VSA tasks from PowerShell without hand-rolling REST calls.

**Note:** This module simplifies interaction with the Kaseya VSA REST API; it does not modify or impact the behavior of the API itself. Issues or glitches within the REST API are unrelated to the module and should be addressed to Kaseya directly.

**Current version:** 1.3.3 · **License:** [MIT](LICENSE.txt)

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
| Dependencies | None — fully self-contained, no external packages required |

Persistent-connection encryption is platform-detected: Windows uses DPAPI (user- and machine-bound); Linux/macOS use AES with a key derived at runtime from per-user + per-machine identifiers (weaker than DPAPI, but appropriate since the store itself is only a process-scoped environment variable — see [Security](#security)).

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
- **Automatic paging** — collections are paged transparently via `$skip`/`$top`; no manual loop needed for large result sets.
- **Automatic retry** — transient HTTP errors (429, 502, 503, 504) retry automatically with exponential backoff (and `Retry-After` support).
- **Automatic token renewal** — session tokens are renewed transparently before paged/long-running requests.
- **Uniform `-WhatIf` / `-Confirm`** — every state-changing cmdlet supports `ShouldProcess`.
- **Typed errors** — failed calls throw a `VSAApiException` with `.StatusCode`, `.ConnectionReset`, and `.VSAError`, so scripts can branch on failure kind instead of parsing message text (see [Release Notes](#release-notes), v1.3.0).
- **Native object parameters** — nested request bodies (`-ContactInfo`, `-Attributes`, `-CustomFields`, …) accept a `[hashtable]`/`[pscustomobject]` directly.
- **Zero dependencies** — fully self-contained PowerShell module.

## Security

- **OData injection prevention** — filter values are automatically escaped:

  ```powershell
  # Safe: special characters are automatically escaped
  $agents = Get-VSAAgent -Filter "ComputerName eq 'O''Brien''s Computer'"

  # Safe: an injection attempt is escaped and treated as a literal
  $agents = Get-VSAAgent -Filter "Status eq 'online' or 1 eq 1"
  ```

- **Parameter validation** — ID parameters accept only positive integers:

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

### Version 1.4.0 (Current)

Broad coverage expansion driven by a full diff against the live VSA Swagger: **31 new read/remove commands** added as endpoint-map entries on the existing data-driven dispatchers (no new files), plus **24 new write functions** built on the shared write path. Everything was exercised against a live VSA server. The internal machine-to-machine surface (agent↔server replication, BMS/IT Glue integration, clustering, policy/event-set editor internals) is intentionally excluded — it is not admin-callable.

- **31 new commands (aliases on the generic dispatchers):**
  - *Remote control:* `Get-VSARCService`, `Get-VSARCServiceByAsset`, `Get-VSARCMachine`, `Get-VSARCMachineByView`
  - *Temporary agents:* `Get-VSATemporaryAgent`, `Get-VSATemporaryAgentConfig`, `Remove-VSATemporaryAgent`
  - *Agent procedures:* `Get-VSAAPList`, `Get-VSAAPProcHistory`, `Get-VSAAPExecHistory`, `Get-VSAAPPrompt`, `Get-VSAAPPromptById`, `Get-VSAAPVariable`
  - *Agents / assets:* `Get-VSAAgentActiveAdmin`, `Get-VSAAgentUserProfile`, `Get-VSAAgentUpdateSchedule`, `Get-VSAAssetById`, `Get-VSAAssetAudit`
  - *Alerts, orgs, tenants:* `Get-VSAAlertDefinition`, `Get-VSAOrgType`, `Get-VSAOrgLocation`, `Get-VSATenantLogonPolicy`, `Get-VSATenantDefaultSetting`
  - *Service desk, backup, misc:* `Get-VSASDTicketByDesk`, `Get-VSASDTicketById`, `Get-VSACBStatus`, `Get-VSAFunctionById`, and the document aggregations `Get-VSADocumentServiceAudit` / `Get-VSADocumentVolumeLabel` / `Get-VSADocumentServiceName` / `Get-VSADocumentDistinctVolumeLabel`
- **24 new write functions** (real cmdlets on the shared `Invoke-VSAWriteRequest` / `ConvertTo-VSARequestBody` base, with uniform `-WhatIf`/`-Confirm`):
  - *Remote control services:* `New-VSARCService`, `Set-VSARCService`, `Remove-VSARCService`, `Set-VSAAssetProxy`, `Set-VSAAssetService`
  - *Temporary agents:* `New-VSATemporaryAgent`, `Set-VSATemporaryAgentName`, `New-VSATemporaryAgentNote`, `Send-VSATemporaryAgentEmail`
  - *Agent / asset lifecycle:* `Suspend-VSAAgent`, `Start-VSAAgentUpgrade`, `Convert-VSAAssetToDevice`, `Convert-VSADeviceToAsset`, `Publish-VSADevice`
  - *Alerts:* `Set-VSAAgentAlert`, `Set-VSASystemAlert`, `Get-VSAAlertTracking`
  - *Automation / patch / service desk / org:* `Start-VSAAPReturnId`, `Stop-VSAPatchSchedule`, `New-VSASDTicket`, `Get-VSAOrgNetwork`
  - *User management:* `Set-VSAUserPassword`, `Reset-VSAUserPassword`, `Close-VSAUserSession` (user-mutation endpoints; may be network-blocked on hardened post-2021 builds)
- Adds `Tests/VSAModule.EndpointMaps.Tests.ps1`, which enforces that every map alias resolves to the right dispatcher and is declared in the manifest's `AliasesToExport`.

### Version 1.3.3

Maintenance and help-accuracy release — dead-code cleanup, packaging tidy-up, and fixes to advertised-but-broken behavior. No cmdlets or parameters added or removed, nothing breaking:
- **Fix: `Get-Help` showed no synopsis or description for five user cmdlets.** `Disable-VSAUser`, `Enable-VSAUser`, `Remove-VSAUser`, `Update-VSAUser`, and `Add-VSAUserToRole` displayed only auto-generated syntax. Their `.NOTES` prose wrapped so a line began with `.StatusCode …`, which PowerShell's comment-based-help parser read as an unknown help directive and used to discard the entire help block. The wording was adjusted so no line starts with a `.token`; `Get-Help` now shows the intended help.
- **Fix: `Get-VSATenantModuleLicense` and `Get-VSATenantRoletypeFunclist` ignored `-Filter`/`-Sort`.** Both cmdlets declared and documented these parameters but never passed them to the transport, so they were silently discarded. They are now forwarded as the OData `$filter`/`$orderby` query the rest of the module uses (verified live: the server accepts them). The stale `.PARAMETER ResolveIDs` help entry — which described a parameter neither cmdlet has — was removed.
- **Maintenance: removed redundant packaging and dead files.** Deleted the checked-in `VSAModule.nuspec` — a generated packaging snapshot that only duplicated `VSAModule.psd1` (which is the authoritative source of the id, version, description, URLs, release notes, and tags) and is ignored by `Publish-Module`, which regenerates its own from the manifest. Also removed the leftover NuGet OPC artifacts (`_rels/`, `package/`, `[Content_Types].xml`) and the inert external MAML help file (`en-US/VSAModule-help.xml`) — comment-based help always shadowed it, so `Get-Help` never surfaced it — plus a few dead `#[CmdletBinding()]` comment lines and a duplicate `Export-ModuleMember` line. No public surface changed.
- **Maintenance: de-duplicated the dynamic-parameter helper.** Six schedule/recurrence cmdlets (`Set-VSAAuditSchedule`, `Set-VSAScheduleAuditSysInfo`, `Set-VSAPatchIgnore`, `New-VSAScheduleAuditBaseLine`, `New-VSAAPScheduled`, `Start-VSAPatchUpdate`) each carried an identical copy of a `New-VSARuntimeParameter` helper inside their `DynamicParam` block (one was even named differently). They now share a single private helper (`private/New-VSARuntimeParameter.ps1`), which is visible to each `DynamicParam` block because those run in module scope. No behavior change — the dynamic recurrence parameters (`DaysOfWeek`, `DayOfMonth`, `MonthOfYear`, `Times`, …) and their validation are identical; verified live against a VSA server.
- **Maintenance: normalized source formatting.** A whitespace-only pass across the module stripped trailing whitespace, re-indented the debug/verbose logging lines to their block depth, and collapsed stray multi-blank-line runs. Every file was verified token-equivalent (parsed before/after; all non-whitespace tokens identical), so the change is provably behavior-preserving.
- **Tests:** the help suite (`Tests/VSAModule.Help.Tests.ps1`) was rewritten to validate the comment-based help actually surfaced by `Get-Help` for every public function, rather than the removed MAML file. Adds `Tests/VSAModule.RuntimeParameter.Tests.ps1` and `Tests/VSAModule.FilterSort.Tests.ps1`.

### Version 1.3.2

Fixes found during a full-module acceptance test against a live VSA server (no cmdlets added or removed):
- **Fix: Cloud Backup cmdlets returned no data.** `Get-VSACBServer(s)`, `Get-VSACBWS`, and `Get-VSACBVM` always threw *"Unexpected API response"*. The Cloud Backup (`kcb/*`) endpoints return a bare JSON object — a flat `{ <agentId>: <status> }` map — with none of the standard `{Result, ResponseCode, Status, Error}` envelope fields, and the transport mistook that for a broken envelope. The transport now recognizes a genuinely non-enveloped payload and returns it as-is (a status-only envelope still yields an empty result, unchanged).
- **Fix: tenant role-type cmdlets couldn't target instance-specific role types.** `Enable-VSATenantRoleType` / `Clear-VSATenantRoleType` validated `-RoleType`/`-RoleTypeName` against a hardcoded list and resolved names via a static name→Id map, so real role types that exist on an instance (e.g. `Multi-Tenant`, `Multi-Tenant Admin`, or any custom/tenant role type) could never be selected. Both now resolve names to Ids at runtime via `Get-VSARoleType` (with tab-completion and a clear error listing the available role types) — matching `Set-VSATenantRoletypeLimit`, which already worked this way. The stale `$TenantRoleTypeIdMap` was removed.
- **Fix: `New-VSALCAuditLog -Message`** was documented as required but declared optional; omitting it sent a null log message and the server returned HTTP 400. It is now mandatory.
- **Fix: `Send-VSAEmail -UniqueTag`** was declared mandatory but the function body already treats it as optional; it is now optional, so a `UniqueTag` is no longer forced on every email.
- **Fix: `Set-VSATenantModuleUsageType` parameter sets were cross-wired.** `TenantId`/`ModuleName` were grouped in one set and `ModuleId`/`TenantName` in the other, so the two natural calls — `-TenantId <id> -ModuleId <id>` and `-TenantName <name> -ModuleName <name>` — could not be satisfied (*"Parameter set cannot be resolved"*); only awkward id-of-one-with-name-of-the-other combinations worked. The sets are now `ById = {TenantId, ModuleId}` and `ByName = {TenantName, ModuleName}` (and the examples were corrected). Found during a full coverage sweep of every function and alias.
- **Fix: `New-VSASDTicketNote -Hidden` and `-SystemFlag` were mandatory switches.** A `[switch]` that must always be supplied is a contradiction — it forced `-Hidden -SystemFlag` on every call just to create an ordinary ticket note. Both are now optional and default to `$false` (which the body already handled).
- **Fix: the multipart upload cmdlets ignored `-WhatIf`/`-Confirm`.** `Publish-VSADocument` and `Publish-VSACustomExtensionFile` (which build a raw multipart body and don't route through the shared write dispatcher) did not support `ShouldProcess`, unlike every other write cmdlet. They now honor `-WhatIf`/`-Confirm`, so a dry run no longer uploads.
- Adds `Tests/VSAModule.RawPayload.Tests.ps1` and `Tests/VSAModule.ParamContract.Tests.ps1`.

### Version 1.3.1

- **Fix: `New-VSAOrganization -CustomFields` with a single field.** A lone custom field was serialized as a bare JSON object instead of a one-element array, which the VSA API rejected with an HTTP 400. Passing two or more fields worked, so this only affected the single-field case. (Root cause: a `$(...)` subexpression around `ToArray()` unwrapped the single-element array to its scalar element. Live-found during full-module acceptance testing against a VSA server; the offline mock hid it because a bare object round-trips through `ConvertFrom-Json` like a one-element array.) Adds raw-JSON-shape regression tests.

### Version 1.3.0

Uniform `-WhatIf`/`-Confirm`, typed API errors, and structural cleanup:
- **Uniform ShouldProcess.** Every state-changing cmdlet now honors `-WhatIf`/`-Confirm`. The gate is centralized in `Invoke-VSAWriteRequest` (via a `-Caller $PSCmdlet` hand-off), so `-WhatIf` short-circuits the request before it is sent. This also fixes the cmdlets that previously *declared* `SupportsShouldProcess` but never called it (so `-WhatIf` was silently ignored).
- **Typed API errors.** Failed calls now throw a `VSAApiException` inside a properly-categorized `ErrorRecord`, so callers can branch programmatically instead of parsing message strings: `$_.Exception.StatusCode` (int; `0` = no HTTP response), `$_.Exception.ConnectionReset` (`$true` when the socket was reset), `$_.Exception.VSAError`, and `$_.CategoryInfo.Category` (`PermissionDenied` for 403, `ObjectNotFound` for 404, `ConnectionError` for a reset). **Note:** on hardened (post-2021) VSA builds, user-mutation endpoints (`Update`/`Remove`/`Enable`/`Disable-VSAUser`, `Add-VSAUserToRole`) are blocked at the network layer — the connection is reset (`ConnectionReset = $true`, `StatusCode = 0`) rather than returning a 403/404. Read-only user cmdlets are unaffected. This is a VSA-side restriction, not a module limitation.
- **Structural cleanup.** Endpoint/id maps extracted from the `.psm1` monolith into a dot-sourced `private/VSAEndpointMaps.ps1`; the 17 empty completer `catch {}` blocks now emit a `Write-Debug` diagnostic; dead `-CustomFields` parameter removed from `Update-VSAOrganization`.
- Adds `Tests/VSAModule.TypedError.Tests.ps1` (9 tests) and `-WhatIf` gate tests. Full suite green; live-verified against a VSA server (404 → `ObjectNotFound`, blocked user writes → `ConnectionReset`).

### Version 1.2.0

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

## Author

Vladislav Semko

## Support and Contributions

For issues, feature requests, or security concerns, please refer to the project repository. Security vulnerabilities should be reported responsibly and not disclosed publicly until a fix is available.

Built for Kaseya VSA 9 automation — Kaseya offers a broader suite of IT management solutions at [kaseya.com](https://www.kaseya.com).
