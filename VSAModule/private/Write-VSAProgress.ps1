function Write-VSAProgress {
    <#
    .SYNOPSIS
        The module's single progress-indicator policy for long, multi-page reads.
    .DESCRIPTION
        Every read that pages a large collection -- the sequential path, the parallel pump, and the
        XML Agent-Procedure list -- shows the same progress bar through this one helper, so the three
        paths cannot drift in look or behaviour. It is a thin, deliberate wrapper over Write-Progress
        that adds the three things a raw Write-Progress call in a tight loop gets wrong:

          * THROTTLED. Write-Progress is surprisingly expensive: redrawing on every completed page of
            a large fan-out can dominate the run. This coalesces updates to at most one redraw per
            ~200 ms per operation, so a 400-page fetch costs a handful of redraws, not 400. The
            -Completed call always draws (it clears the bar).

          * UNIQUE Id. Each operation passes an Id from New-VSAProgressId (a random, non-zero id). A
            bare Write-Progress uses id 0, which collides with -- and clobbers -- a progress bar the
            caller's own script may be showing. A distinct id nests cleanly instead.

          * NOT coupled to -Verbose/-Debug. Progress is a UX affordance, not a diagnostic stream. It
            is ON by default and suppressed the standard PowerShell way: $ProgressPreference =
            'SilentlyContinue' (which Write-Progress already honours, so there is nothing to check
            here). Verbose/Debug remain purely diagnostic.

        The per-operation throttle timestamp lives in a module-scoped map keyed by Id. The module's
        read paths are single-threaded (even the parallel pump runs one coordinator thread), so no
        locking is needed; -Completed removes the key so the map does not grow across operations.
    .PARAMETER Id
        The operation's progress id (from New-VSAProgressId). Isolates this bar from any other.
    .PARAMETER Activity
        The Write-Progress activity label (the operation description).
    .PARAMETER Current
        Records (or pages) retrieved so far. Ignored when -Completed is set.
    .PARAMETER Total
        The known total to retrieve. When 0/unknown, the bar shows a status line without a percentage.
    .PARAMETER Status
        Optional status text; a sensible "Current / Total" default is used when omitted.
    .PARAMETER Completed
        Clears the bar for this Id and drops its throttle state. Call once in a finally block.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int] $Id,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Activity,

        [Parameter(Mandatory = $false)]
        [int] $Current = 0,

        [Parameter(Mandatory = $false)]
        [int] $Total = 0,

        [Parameter(Mandatory = $false)]
        [string] $Status,

        [Parameter(Mandatory = $false)]
        [switch] $Completed
    )

    if ($null -eq $script:VSAProgressLastDraw) {
        $script:VSAProgressLastDraw = @{}
    }

    if ($Completed) {
        # Always clear the bar, even if $ProgressPreference silenced the intermediate updates.
        Write-Progress -Id $Id -Activity $Activity -Completed
        $script:VSAProgressLastDraw.Remove($Id)
        return
    }

    # Coalesce updates: at most one redraw per ~200 ms per operation. The first update for an Id has
    # no prior timestamp and always draws, so a short read still shows one bar.
    $now  = [datetime]::UtcNow
    $last = $script:VSAProgressLastDraw[$Id]
    if ($null -ne $last -and ($now - $last).TotalMilliseconds -lt 200) {
        return
    }
    $script:VSAProgressLastDraw[$Id] = $now

    if ([string]::IsNullOrEmpty($Status)) {
        $Status = if ($Total -gt 0) { "$Current / $Total" } else { "$Current retrieved" }
    }

    if ($Total -gt 0) {
        $pct = [Math]::Min(100, [int](100 * $Current / $Total))
        Write-Progress -Id $Id -Activity $Activity -Status $Status -PercentComplete $pct
    } else {
        Write-Progress -Id $Id -Activity $Activity -Status $Status
    }
}

function New-VSAProgressId {
    <#
    .SYNOPSIS
        Returns a unique, non-zero Write-Progress id for one paged-read operation.
    .DESCRIPTION
        Each long read claims its own id so its progress bar never collides with progress id 0 (the
        default) that a caller's own script may be driving. Non-zero and random across the positive
        Int32 range; the tiny collision chance is harmless (two module reads are not concurrent on the
        one thread these paths run on).
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param()
    return Get-Random -Minimum 1 -Maximum ([int]::MaxValue)
}
