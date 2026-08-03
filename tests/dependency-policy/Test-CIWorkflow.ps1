[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }
$path = Join-Path $RepositoryRoot '.github\workflows\dependency-policy.yml'
if (-not (Test-Path -LiteralPath $path)) { throw 'Dependency policy workflow is missing.' }
$workflow = Get-Content -LiteralPath $path -Raw
$patterns = @(
    'pull_request:', 'push:', 'workflow_dispatch:', 'contents: read', 'timeout-minutes: 15',
    'cancel-in-progress: true', '11bd71901bbe5b1630ceea73d27597364c9af683', '2.71.1',
    'run-all.ps1', 'run-all.sh', 'Test-CIWorkflow.ps1', 'checksums.txt', 'checksum mismatch',
    'Windows x86_64', 'Linux x86_64', 'macOS arm64', 'macOS x86_64',
    'Release assets and repository quality', 'Static/contract evidence only; no clean-install claim.'
)
foreach ($pattern in $patterns) {
    if ($workflow -notmatch [regex]::Escape($pattern)) { throw "Workflow contract is missing '$pattern'." }
}
foreach ($forbidden in @('pull_request_target', 'self-hosted', 'contents: write', 'id-token: write')) {
    if ($workflow -match [regex]::Escape($forbidden)) { throw "Workflow contains forbidden setting '$forbidden'." }
}
$jobNames = [regex]::Matches($workflow, '(?m)^\s+name: (Windows x86_64|Linux x86_64|macOS arm64|macOS x86_64|Release assets and repository quality)$')
if ($jobNames.Count -ne 5) { throw 'Workflow required-check job names are not stable and unique.' }
Write-Host 'Dependency policy workflow contract passed.'
