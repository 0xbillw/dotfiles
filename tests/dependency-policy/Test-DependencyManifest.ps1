[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$PolicyJsonPath,
    [switch]$CheckConsumers
)

$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
    $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

function Assert-Policy {
    param([object]$Condition, [string]$Message)
    if (-not [bool]$Condition) {
        throw "Dependency policy validation failed: $Message"
    }
}

function Find-Chezmoi {
    if ($env:CHEZMOI -and (Test-Path -LiteralPath $env:CHEZMOI)) {
        return $env:CHEZMOI
    }
    $command = Get-Command chezmoi -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    $wingetRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    $candidate = Get-ChildItem -LiteralPath $wingetRoot -Filter chezmoi.exe -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($candidate) {
        return $candidate.FullName
    }
    throw 'chezmoi was not found. Set CHEZMOI to its executable path.'
}

$chezmoi = Find-Chezmoi
$json = if ($PolicyJsonPath) {
    Get-Content -LiteralPath $PolicyJsonPath -Raw
}
else {
    $rendered = & $chezmoi -S $RepositoryRoot execute-template '{{ .dependencyPolicy | toJson }}'
    Assert-Policy ($LASTEXITCODE -eq 0) 'chezmoi could not render dependencyPolicy.'
    $rendered
}
$policy = $json | ConvertFrom-Json

$expectedDependencies = @(
    'nushell', 'zellij', 'helix', 'starship', 'zoxide', 'fzf', 'wezterm',
    'jetbrainsmono-nerd-font'
)
$dependencyNames = @($policy.dependencies.PSObject.Properties.Name)
$targetNames = @($policy.supportedTargets)

Assert-Policy ($policy.schema -eq 1) 'schema must equal 1.'
Assert-Policy ($dependencyNames.Count -eq $expectedDependencies.Count) 'exactly eight dependencies are required.'
foreach ($name in $expectedDependencies) {
    Assert-Policy ($name -in $dependencyNames) "missing dependency '$name'."
}
Assert-Policy ($targetNames.Count -eq 7) 'the declared support boundary must contain seven normalized targets.'

$orders = @()
foreach ($property in $policy.dependencies.PSObject.Properties) {
    $id = $property.Name
    $dependency = $property.Value
    $orders += [int]$dependency.installOrder
    Assert-Policy ($dependency.version -match '^\d[^\s]*$') "$id has no exact version."
    Assert-Policy ($dependency.version -notmatch 'latest|[xX*]|[<>~=]') "$id uses a floating version."
    Assert-Policy (@($dependency.roles).Count -gt 0) "$id has no applicable role."
    Assert-Policy ($dependency.removeGuidance.windows -and $dependency.removeGuidance.posix) "$id lacks removal guidance."

    $dependencyTargets = @($dependency.targets.PSObject.Properties.Name)
    foreach ($targetName in $targetNames) {
        Assert-Policy ($targetName -in $dependencyTargets) "$id lacks target '$targetName'."
        $target = $dependency.targets.$targetName
        Assert-Policy ($target.strategy -in @('official-artifact', 'native-package', 'platform-exception')) "$id/$targetName has an invalid strategy."
        if ($target.strategy -eq 'official-artifact') {
            Assert-Policy ($target.url -match '^https://') "$id/$targetName must use HTTPS."
            Assert-Policy ($target.url -match '^https://github\.com/') "$id/$targetName is not an official GitHub release URL."
            Assert-Policy ($target.sha256 -match '^[0-9a-f]{64}$') "$id/$targetName has an invalid SHA-256."
            Assert-Policy ($target.archive) "$id/$targetName has no archive type."
            Assert-Policy ($target.url -match [regex]::Escape([string]$dependency.version)) "$id/$targetName URL does not reference declared version $($dependency.version)."
        }
        elseif ($target.strategy -eq 'native-package') {
            Assert-Policy ($target.manager -and $target.package -and $target.packageVersion) "$id/$targetName lacks an exact native package declaration."
            Assert-Policy ($target.packageVersion -match [regex]::Escape([string]$dependency.version)) "$id/$targetName package version does not reference declared version $($dependency.version)."
        }
        else {
            $exception = $target.exception
            Assert-Policy ($exception.reason -and $exception.scope -and $exception.compatibleVersion -and
                @($exception.evidence).Count -gt 0 -and $exception.removalCondition) "$id/$targetName has an incomplete platform exception."
        }
        if ($dependency.kind -eq 'font' -and $target.strategy -eq 'official-artifact') {
            $fontFiles = @($target.installedFiles.PSObject.Properties)
            Assert-Policy ($fontFiles.Count -eq 4) "$id/$targetName must declare four installed font files."
            foreach ($fontFile in $fontFiles) {
                Assert-Policy ($fontFile.Value -match '^[0-9a-f]{64}$') "$id/$targetName/$($fontFile.Name) has an invalid installed-file hash."
            }
        }
    }
}

Assert-Policy (($orders | Sort-Object -Unique).Count -eq $orders.Count) 'installOrder values must be unique.'
Assert-Policy (@($policy.dependencies.wezterm.roles) -contains 'workstation') 'WezTerm must apply to workstations.'
Assert-Policy (@($policy.dependencies.wezterm.roles) -notcontains 'server') 'WezTerm must not apply to servers.'
Assert-Policy (@($policy.dependencies.'jetbrainsmono-nerd-font'.roles) -notcontains 'server') 'The font must not apply to servers.'

if ($CheckConsumers) {
    $installerPaths = @(
        'run_onchange_before_10-install-packages.cmd.tmpl',
        'run_onchange_before_10-install-packages-darwin.sh.tmpl',
        'run_onchange_before_10-install-packages-linux.sh.tmpl'
    )
    foreach ($dependency in $policy.dependencies.PSObject.Properties.Value) {
        foreach ($relativePath in $installerPaths) {
            $content = Get-Content -LiteralPath (Join-Path $RepositoryRoot $relativePath) -Raw
            Assert-Policy ($content -notmatch [regex]::Escape([string]$dependency.version)) "$relativePath duplicates managed version $($dependency.version)."
        }
    }
}

Write-Host "Dependency manifest valid: $($dependencyNames.Count) dependencies, $($targetNames.Count) targets."
