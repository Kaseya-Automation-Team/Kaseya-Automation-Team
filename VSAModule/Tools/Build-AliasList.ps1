#requires -Version 5.1
<#
.SYNOPSIS
    Prints the sorted, unique union of every alias the module actually creates at runtime,
    ready to paste into VSAModule.psd1's AliasesToExport (F-03, F-04, F-06).
.DESCRIPTION
    Collects aliases from two sources:
    1. The keys of $URISuffixGetMap, $URISuffixGetByIdMap, $URISuffixRemoveMap (module-scope
       hashtables in VSAModule.psm1 that back the dynamically created Get-VSAItem/
       Get-VSAItemById/Remove-VSAItem aliases).
    2. Every literal -Name argument passed to New-Alias/Set-Alias in public/*.ps1.
.OUTPUTS
    One quoted, sorted, de-duplicated alias name per line to the pipeline.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

$moduleRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $moduleRoot 'VSAModule.psd1'

Import-Module $manifestPath -Force
$module = Get-Module -Name VSAModule
if (-not $module) { throw "Build-AliasList: VSAModule did not import." }

# Source 1: the three URI-suffix map keys, read from the module's own script scope.
$mapAliases = & $module {
    @($URISuffixGetMap.Keys) + @($URISuffixGetByIdMap.Keys) + @($URISuffixRemoveMap.Keys)
}

# Source 2: every -Name argument of New-Alias/Set-Alias declared in public/*.ps1.
$staticAliases = foreach ($file in Get-ChildItem -Path (Join-Path $moduleRoot 'public') -Filter '*.ps1' -File) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($match in [regex]::Matches($content, '-Name\s+([A-Za-z][\w-]+)')) {
        $match.Groups[1].Value
    }
}

$allAliases = @($mapAliases) + @($staticAliases) | Sort-Object -Unique

foreach ($name in $allAliases) {
    "        '$name'"
}
