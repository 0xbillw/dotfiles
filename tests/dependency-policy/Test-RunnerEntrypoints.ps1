[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }
$runner = Join-Path $PSScriptRoot 'run-all.ps1'
if (-not (Test-Path -LiteralPath $runner)) { throw 'PowerShell aggregate runner is missing.' }
$source = Get-Content -LiteralPath $runner -Raw
$expected = @(
    'Test-DependencyManifest.ps1', 'Test-PolicyUpgrade.ps1', 'Test-WindowsDependencyInstall.ps1',
    'Test-WindowsReconciliation.ps1', 'Test-ReleaseAssets.ps1'
)
foreach ($name in $expected) {
    if ($source -notmatch [regex]::Escape($name)) { throw "PowerShell inventory omits $name." }
}
foreach ($required in @('TestDirectory', 'BaseRef', 'Dependency policy suite passed:', 'chezmoi apply')) {
    if ($source -notmatch [regex]::Escape($required)) { throw "PowerShell runner contract is missing $required." }
}
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-runner-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporary | Out-Null
try {
    $shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell.exe' }
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & $shell -NoProfile -ExecutionPolicy Bypass -File $runner -RepositoryRoot $RepositoryRoot -TestDirectory $temporary -SkipQuality 2>&1
    $ErrorActionPreference = $previousPreference
    if ($LASTEXITCODE -eq 0 -or "$output" -notmatch 'Missing expected test') { throw 'PowerShell runner did not reject a missing inventory file.' }
}
finally { Remove-Item -LiteralPath $temporary -Recurse -Force }
Write-Host 'PowerShell aggregate runner contract passed.'
