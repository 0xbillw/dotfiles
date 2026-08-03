[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }
$verifier = Join-Path $PSScriptRoot 'Test-ReleaseAssets.ps1'
$fixture = Join-Path $PSScriptRoot 'fixtures\release-assets.json'

& $verifier -RepositoryRoot $RepositoryRoot -FixturePath $fixture -Scenario matching
foreach ($case in @(
    @{ Name = 'missing-asset'; Class = 'asset-missing' },
    @{ Name = 'digest-mismatch'; Class = 'digest-mismatch' },
    @{ Name = 'unsupported-host'; Class = 'unsupported-host' },
    @{ Name = 'upstream-unavailable'; Class = 'upstream-unavailable' }
)) {
    $shell = (Get-Process -Id $PID).Path
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & $shell -NoProfile -ExecutionPolicy Bypass -File $verifier -RepositoryRoot $RepositoryRoot -FixturePath $fixture -Scenario $case.Name 2>&1
    $ErrorActionPreference = $previousPreference
    if ($LASTEXITCODE -eq 0 -or "$output" -notmatch [regex]::Escape("[$($case.Class)]")) {
        throw "Release asset fixture '$($case.Name)' did not fail as $($case.Class)."
    }
}

Write-Host 'Release asset verifier fixture contracts passed.'
# Expected child-process failures must not leak into the CI step result.
$global:LASTEXITCODE = 0
