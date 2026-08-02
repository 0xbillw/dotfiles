[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
    $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

$validator = Join-Path $PSScriptRoot 'Test-DependencyManifest.ps1'
$validatorSource = Get-Content -LiteralPath $validator -Raw
if ($validatorSource -notmatch 'PolicyJsonPath') {
    throw 'The manifest validator does not support mutation input through PolicyJsonPath.'
}

$chezmoi = if ($env:CHEZMOI) { $env:CHEZMOI } else {
    (Get-Command chezmoi -ErrorAction Stop).Source
}
$json = & $chezmoi -S $RepositoryRoot execute-template '{{ .dependencyPolicy | toJson }}'
$policy = $json | ConvertFrom-Json
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-policy-upgrade-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $temporaryRoot | Out-Null
try {
    $staleVersion = $json | ConvertFrom-Json
    $staleVersion.dependencies.nushell.version = '0.114.2'
    $stalePath = Join-Path $temporaryRoot 'stale-version.json'
    $staleVersion | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $stalePath -Encoding UTF8
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $validator `
        -RepositoryRoot $RepositoryRoot -PolicyJsonPath $stalePath 2>&1
    $ErrorActionPreference = $previousPreference
    if ($LASTEXITCODE -eq 0 -or "$output" -notmatch 'does not reference declared version') {
        throw 'A version-only mutation did not fail with the expected target artifact diagnostic.'
    }

    $incompleteException = $json | ConvertFrom-Json
    $incompleteException.dependencies.wezterm.targets.'linux-x86_64-gnu'.exception.removalCondition = ''
    $exceptionPath = Join-Path $temporaryRoot 'incomplete-exception.json'
    $incompleteException | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $exceptionPath -Encoding UTF8
    $ErrorActionPreference = 'Continue'
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $validator `
        -RepositoryRoot $RepositoryRoot -PolicyJsonPath $exceptionPath 2>&1
    $ErrorActionPreference = $previousPreference
    if ($LASTEXITCODE -eq 0 -or "$output" -notmatch 'incomplete platform exception') {
        throw 'An incomplete platform exception was not rejected.'
    }

    $windowsIntegration = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'run_after_generate-nushell-integrations.cmd.tmpl') -Raw
    $posixIntegration = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'run_after_generate-nushell-integrations.sh.tmpl') -Raw
    foreach ($content in @($windowsIntegration, $posixIntegration)) {
        if ($content -notmatch 'declaredVersion=' -or $content -notmatch 'observedVersion=') {
            throw 'Integration retain matching is not keyed by declared and observed versions.'
        }
    }
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
}

Write-Host 'Policy upgrade mutation checks passed.'
