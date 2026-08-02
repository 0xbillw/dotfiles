[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
    $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

$policy = Get-Content -LiteralPath (Join-Path $RepositoryRoot '.chezmoitemplates\dependency-policy-windows.ps1') -Raw
$integration = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'run_after_generate-nushell-integrations.cmd.tmpl') -Raw

function Require-Pattern([string]$Text, [string]$Pattern, [string]$Scenario) {
    if ($Text -notmatch $Pattern) {
        throw "Windows reconciliation '$Scenario' is not implemented (missing $Pattern)."
    }
}

Require-Pattern $policy 'downgrade' 'newer-downgrade'
Require-Pattern $policy 'retain-unsupported' 'newer-retain'
Require-Pattern $policy 'cancelled' 'newer-cancel'
Require-Pattern $policy 'interaction-required' 'newer-non-interactive'
Require-Pattern $policy 'declaredVersion' 'retain-declaration-key'
Require-Pattern $policy 'observedVersion' 'retain-observed-version'
Require-Pattern $policy 'Invalid choice' 'invalid-input-retry'
Require-Pattern $policy 'Changed:' 'partial-failure-changed'
Require-Pattern $policy 'Failed:' 'partial-failure-failed'
Require-Pattern $policy 'Pending:' 'partial-failure-pending'
Require-Pattern $policy 'removeGuidance' 'safe-removal-guidance'
Require-Pattern $policy 'duplicate-active-path' 'unrelated-installation-preservation'
Require-Pattern $integration 'retain-unsupported' 'retained-integration-generation'

Write-Host 'Windows reconciliation fixture contract is present.'
