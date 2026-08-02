[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
    $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

function Assert-Contains {
    param([string]$Text, [string]$Pattern, [string]$Scenario)
    if ($Text -notmatch $Pattern) {
        throw "Windows dependency fixture '$Scenario' is not implemented (missing $Pattern)."
    }
}

$path = Join-Path $RepositoryRoot 'run_onchange_before_10-install-packages.cmd.tmpl'
$helper = Join-Path $RepositoryRoot '.chezmoitemplates\dependency-policy-windows.ps1'
$content = (Get-Content -LiteralPath $path -Raw) + "`n" + (Get-Content -LiteralPath $helper -Raw)

Assert-Contains $content '\.dependencyPolicy\.dependencies' 'manifest-consumer'
Assert-Contains $content 'DOTFILES_DEPENDENCY_TEST' 'isolated-fixture-mode'
Assert-Contains $content 'target-unsupported' 'unknown-target'
Assert-Contains $content 'preflight-blocked' 'unavailable-and-bad-hash'
Assert-Contains $content 'installedFiles' 'font-file-identity'
Assert-Contains $content 'dependency management is disabled' 'disabled-management'
Assert-Contains $content 'already-compatible' 'matching-and-second-apply'
Assert-Contains $content 'duplicate-active-path' 'duplicate-path'
Assert-Contains $content 'workstation-only' 'workstation-server-filter'

Write-Host 'Windows dependency install fixture contract is present.'
