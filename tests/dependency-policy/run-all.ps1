[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$BaseRef,
    [string]$TestDirectory,
    [switch]$SkipQuality
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }
if (-not $TestDirectory) { $TestDirectory = $PSScriptRoot }

# Safety boundary: this static and contract suite never invokes production chezmoi apply.
$inventory = @(
    'Test-DependencyManifest.ps1',
    'Test-PolicyUpgrade.ps1',
    'Test-WindowsDependencyInstall.ps1',
    'Test-WindowsReconciliation.ps1',
    'Test-ReleaseAssets.ps1'
)

foreach ($name in $inventory) {
    $path = Join-Path $TestDirectory $name
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing expected test: $name" }
}

$passed = 0
$shell = (Get-Process -Id $PID).Path
foreach ($name in $inventory) {
    if ($SkipQuality -and $name -eq 'Test-ReleaseAssets.ps1') { continue }
    $path = Join-Path $TestDirectory $name
    Write-Host "==> $path"
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $path, '-RepositoryRoot', $RepositoryRoot)
    if ($name -eq 'Test-ReleaseAssets.ps1' -and $BaseRef) { $arguments += @('-BaseRef', $BaseRef) }
    & $shell @arguments
    if ($LASTEXITCODE -ne 0) { throw "Test failed: $name (exit $LASTEXITCODE)" }
    $passed++
}

if (-not $SkipQuality) {
    Write-Host '==> repository quality checks'
    & git -C $RepositoryRoot diff --check
    if ($LASTEXITCODE -ne 0) { throw 'Repository whitespace validation failed.' }
    if ($BaseRef) {
        & git -C $RepositoryRoot rev-parse --verify $BaseRef *> $null
        if ($LASTEXITCODE -ne 0) { throw "Comparison base '$BaseRef' was not found." }
        & git -C $RepositoryRoot diff --check "$BaseRef...HEAD"
        if ($LASTEXITCODE -ne 0) { throw 'Changed-range whitespace validation failed.' }
        $added = & git -C $RepositoryRoot diff --unified=0 "$BaseRef...HEAD" -- . ':(exclude)*.png' ':(exclude)*.jpg' ':(exclude)*.zip'
        $nonEnglish = @($added | Where-Object { $_ -match '^\+(?!\+\+)' -and $_ -match '[^\x00-\x7F]' })
        if ($nonEnglish.Count -gt 0) { throw "Non-English added lines detected:`n$($nonEnglish -join "`n")" }
    }
    else { Write-Host 'Changed-line checks skipped: no BaseRef supplied.' }

    $chezmoi = if ($env:CHEZMOI) { $env:CHEZMOI } else { (Get-Command chezmoi -ErrorAction Stop).Source }
    $managed = @(& $chezmoi -S $RepositoryRoot managed)
    if ($LASTEXITCODE -ne 0) { throw 'chezmoi managed-target inspection failed.' }
    $forbidden = @('.agents', '.specify', 'specs', 'tests')
    foreach ($target in $managed) {
        $normalized = "$target".Replace('\', '/').TrimStart('./')
        foreach ($root in $forbidden) {
            if ($normalized -eq $root -or $normalized.StartsWith("$root/")) { throw "Development path is managed: $target" }
        }
    }

    $parseErrors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($PSCommandPath, [ref]$null, [ref]$parseErrors)
    if ($parseErrors) { throw "PowerShell syntax validation failed: $parseErrors" }
}

Write-Host "Dependency policy suite passed: $passed tests."
Write-Host 'Evidence: static/contract only; no clean-install claim.'
