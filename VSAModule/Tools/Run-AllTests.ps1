#requires -Modules Pester
[CmdletBinding()] param()
$ErrorActionPreference = 'Stop'
$moduleRoot = Split-Path -Parent $PSScriptRoot
$config = New-PesterConfiguration
$config.Run.Path = Join-Path $moduleRoot 'Tests'
$config.Output.Verbosity = 'Detailed'
$config.Run.Exit = $true
Invoke-Pester -Configuration $config
