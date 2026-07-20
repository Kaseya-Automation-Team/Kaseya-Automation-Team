# Changelog

All notable changes to **VSAModule**. This is the full history; the [README](README.md) carries only the current release's highlights.


### Version 1.7.0 (Current)

One read engine: a single decode seam and a single progress policy shared by every read, plus correctness and coherence fixes from a full live-sandbox pass. The public surface is unchanged apart from opt-in additions (`Get-VSAAPList` gains `-Parallel`) and several id parameters retyped to strings.

- **One decode layer** (`private/ConvertFrom-VSAResponseBody.ps1`). Response interpretation moved out of the two-and-a-half places that had to be kept in agreement by hand; the sequential path, the parallel pump and the later-page merge now share one definition of the empty-body (F-21), status-only (F-23), raw-payload (F-63) and non-JSON-error (F-72) rules. Why: [DESIGN-NOTES §1, §3](DESIGN-NOTES.md).
- **`Get-VSAAPList` now returns data**, and gains `-Parallel`. Its endpoint serves the Agent Procedure tree as Kaseya `ScExport` **XML** (VSA 9 stores procedures as XML), which the JSON-only read path could never parse - so the cmdlet always returned nothing. It is now a dedicated function feeding an ScExport decoder into the shared engine, inheriting paging, retry, token renewal, progress and session recovery. Live-verified: 786 procedures, serial identical to parallel. This is why the surface is now **140 functions / 168 aliases**. Why: [DESIGN-NOTES §4](DESIGN-NOTES.md).
- **One progress policy** across every paged read - on by default (sequential included), throttled, with its own bar id; silence it with `$ProgressPreference = 'SilentlyContinue'`. Previously only `-Parallel` showed a bar. Why: [DESIGN-NOTES §8](DESIGN-NOTES.md).
- **`Update-VSAOrganization` no longer sends `[decimal]`-cast numbers.** `NoOfEmployees`/`ParentOrgId` serialised `7` as `7.0`, which the endpoint rejects with HTTP 400; they now travel as the caller's string value.
- **Every 26-digit object id is now `[string]` module-wide** (`Update-VSAUser`, `Set-VSAAgentAlert`/`Set-VSASystemAlert` `ScriptId`, `Enable-VSATenantRoleType` `RoleTypeId`, `Update-VSAInfoMsg` `ID`) - they overflow `Int32`/`Int64`. Small fixed catalog codes stay numeric, test-guarded. Why: [DESIGN-NOTES §9](DESIGN-NOTES.md).
- **`-Parallel` decodes correctly for every reader** - the engine forwards its decoder to the pump, which previously hard-coded JSON (an XML `-Parallel` read would have failed per page).
- **OData paging options are built for `GET` only** - a `PUT` no longer goes out as `.../orgs/{id}?$top=100`. Why: [DESIGN-NOTES §10](DESIGN-NOTES.md).
- **The internal dispatch engines explain themselves** when called directly rather than through their aliases, and a dead `-AdminType` parameter was removed from `Update-VSAUser`.

Evidence: [TESTING-REPORT-rigorous-reads-2026-07-16.md](TESTING-REPORT-rigorous-reads-2026-07-16.md), [TESTING-REPORT-writes-2026-07-16.md](TESTING-REPORT-writes-2026-07-16.md).

### Version 1.6.0

Two things land together: **one HTTP stack** (an internal transport unification) and the correctness fixes from the v1.5.0 full-surface sandbox pass. The public API is unchanged; the minor bump signals the transport replacement.

- **One HTTP stack.** `Invoke-RestMethod` (sequential) and `HttpClient` (parallel) each carried their own retry, envelope and error rules - and the copies **had already drifted**, so this was a source of live defects, not untidiness. Everything now goes through `HttpClient` with one shared definition of each policy. Four divergences fixed: typed errors and `Retry-After` now work under `-Parallel`; the raw non-enveloped payload rule (F-63) and the unexpected-response guard apply to both paths; one shared cached client replaces per-call construction (which leaked a socket into `TIME_WAIT` every batch). Why: [DESIGN-NOTES §1, §2](DESIGN-NOTES.md).
- **Windows PowerShell 5.1:** `System.Net.Http` is now loaded at module import - `New-VSAConnection` previously failed with *"Unable to find type [System.Net.Http.HttpClient]"* on .NET Framework. It cannot be loaded lazily. Why: [DESIGN-NOTES §2](DESIGN-NOTES.md).
- **`-Parallel` extended to all 24 standalone paged reads.** v1.5.0 reached only the dispatcher aliases, so `Get-VSAAgent -Parallel` - the README's own headline example - did not exist. Excluded: the three download cmdlets, which stream one body and have no pages. Also fixed: a single-page collection with a low explicit `-ParallelThreshold` threw; `Get-VSASDTicket` now names `Get-VSASD` as the source of desk ids.
- **F-69 - `Update-VSAStaff` returned HTTP 500 unless `-Function` was supplied.** The backend stored procedure takes it as `@purpose` and rejects the whole update without it. Now always sent; when omitted the record's current value is read back and re-sent, so the real job function is not wiped.
- **F-70 - a blocked write no longer burns a retry storm.** One shared rule (`Test-VSARetryable`): a transient HTTP status retries for any method; a no-response retries only for **idempotent** methods. Blocked writes now fail in under a second, still typed `ConnectionReset`. Why: [DESIGN-NOTES §5](DESIGN-NOTES.md).
- **F-77 / F-78 - recovery from server-side session invalidation.** A session can be killed before its client-tracked expiry; a 401 now forces one renewal and retries once, on both the sequential path and the pump (where renewal uses its own budget, so it never eats the retries reserved for throttling). Why: [DESIGN-NOTES §6](DESIGN-NOTES.md).
- **F-79 / F-80** - `Set-VSARCService` preserves `ClientApp`/`Path` when omitted (the server null-refs without them); `Send-VSAEmail` auto-generates a `UniqueTag` (the server 400s without one).
- **Uniform `-WhatIf` across the whole write surface.** `Copy-VSAOrgStructure`/`Copy-VSAMGStructure` gained it - the two highest-blast-radius cmdlets - and the module-wide `PSShouldProcess` analyzer warning is resolved with justified suppressions rather than tolerated. Why: [DESIGN-NOTES §11](DESIGN-NOTES.md).
- **Correctness and documentation.** Unresolved name lookups can no longer reach the wire (8 cmdlets, one of which could issue `roleTypeId=0`); `Clear-VSATenantRoleType -RoleTypeId` retyped to a validated `[string]`; `New-VSALCAuditLog -AgentName` defaults to `'VSAModule'`; `Update-VSAOrganization` accepts `-OrgName`; all remaining `.PARAMETER` gaps closed (35 functions to 0); `-Force` documented for what it really does; line endings normalised.

**Known server-side limitations (not module defects):** see [DESIGN-NOTES §13](DESIGN-NOTES.md).

Evidence: [TESTING-REPORT-v1.6.0.md](TESTING-REPORT-v1.6.0.md), [TESTING-REPORT-v1.5.0.md](TESTING-REPORT-v1.5.0.md).

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
