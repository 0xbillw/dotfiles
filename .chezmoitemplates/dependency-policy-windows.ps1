[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$RepositoryRoot,
    [switch]$Workstation
)

$ErrorActionPreference = 'Stop'
$TargetName = 'windows-x86_64'
$RoleName = if ($Workstation) { 'workstation' } else { 'server' }
$StateRoot = Join-Path $env:LOCALAPPDATA 'cross-platform-terminal-workspace\dependency-state'
$BinRoot = Join-Path $HOME '.local\bin'
$FontRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$StageRoot = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-dependencies-" + [guid]::NewGuid().ToString('N'))

# dependency-policy markers: target-unsupported preflight-blocked already-compatible
# dependency-policy markers: duplicate-active-path workstation-only installedFiles
# DOTFILES_DEPENDENCY_TEST is reserved for isolated fixture copies.

function Find-Chezmoi {
    $command = Get-Command chezmoi -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $candidate = Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') `
        -Filter chezmoi.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($candidate) { return $candidate.FullName }
    throw 'chezmoi is required to render the dependency policy.'
}

function Get-CommandName([string]$Id) {
    switch ($Id) {
        nushell { 'nu.exe' }
        helix { 'hx.exe' }
        default { "$Id.exe" }
    }
}

function Normalize-Version([string]$Parser, [string]$Raw) {
    $tokens = @($Raw.Trim() -split '\s+')
    switch ($Parser) {
        plain { if ($tokens.Count) { $tokens[0] } }
        'first-token' { if ($tokens.Count) { $tokens[0] } }
        'second-token' { if ($tokens.Count -gt 1) { $tokens[1] } }
        default { $Raw.Trim() }
    }
}

function Get-ObservedExecutable($Dependency) {
    $commandName = Get-CommandName $Dependency.id
    $managedPath = Join-Path $BinRoot $commandName
    $activePath = if (Test-Path -LiteralPath $managedPath) {
        $managedPath
    }
    else {
        (Get-Command $commandName -ErrorAction SilentlyContinue | Select-Object -First 1).Source
    }
    if (-not $activePath -and $Dependency.id -eq 'wezterm') {
        $wezTermPath = Join-Path $env:ProgramFiles 'WezTerm\wezterm.exe'
        if (Test-Path -LiteralPath $wezTermPath) { $activePath = $wezTermPath }
    }
    if (-not $activePath) {
        return [pscustomobject]@{ Version = 'missing'; Path = $null }
    }
    $raw = (& $activePath --version 2>$null | Select-Object -First 1)
    [pscustomobject]@{
        Version = Normalize-Version $Dependency.versionProbe.parser ([string]$raw)
        Path = $activePath
    }
}

function Get-FontIdentityStatus($Target) {
    foreach ($property in $Target.installedFiles.PSObject.Properties) {
        $path = Join-Path $FontRoot $property.Name
        if (-not (Test-Path -LiteralPath $path)) { return 'missing-or-different' }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $property.Value) {
            return 'missing-or-different'
        }
        $systemPath = Join-Path (Join-Path $env:WINDIR 'Fonts') $property.Name
        if (Test-Path -LiteralPath $systemPath) {
            $systemHash = (Get-FileHash -LiteralPath $systemPath -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($systemHash -ne $property.Value) { return 'duplicate-active-path' }
        }
    }
    'exact'
}

function Test-FontIdentity($Target) {
    (Get-FontIdentityStatus $Target) -eq 'exact'
}

function Compare-PolicyVersion([string]$Observed, [string]$Expected) {
    $observedParts = @($Observed -split '[^0-9]+' | Where-Object { $_ -ne '' } | ForEach-Object { [long]$_ })
    $expectedParts = @($Expected -split '[^0-9]+' | Where-Object { $_ -ne '' } | ForEach-Object { [long]$_ })
    if (-not $observedParts.Count -or -not $expectedParts.Count) { return 'different' }
    $count = [Math]::Max($observedParts.Count, $expectedParts.Count)
    for ($index = 0; $index -lt $count; $index++) {
        $observedPart = if ($index -lt $observedParts.Count) { $observedParts[$index] } else { 0 }
        $expectedPart = if ($index -lt $expectedParts.Count) { $expectedParts[$index] } else { 0 }
        if ($observedPart -gt $expectedPart) { return 'newer' }
        if ($observedPart -lt $expectedPart) { return 'older' }
    }
    'different'
}

function Get-RetainState([string]$Id) {
    $path = Join-Path $StateRoot "$Id.state"
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    $values = @{}
    foreach ($line in Get-Content -LiteralPath $path) {
        if ($line -match '^([^=]+)=(.*)$') { $values[$Matches[1]] = $Matches[2] }
    }
    $values
}

function Test-RetainOverride([string]$Id, [string]$Declared, [string]$Observed) {
    $state = Get-RetainState $Id
    $state -and $state.schema -eq '1' -and $state.dependencyId -eq $Id -and
        $state.declaredVersion -eq $Declared -and $state.observedVersion -eq $Observed -and
        $state.decision -eq 'retain-unsupported'
}

function Save-RetainOverride([string]$Id, [string]$Declared, [string]$Observed) {
    $path = Join-Path $StateRoot "$Id.state"
    $temporary = "$path.tmp"
    @(
        'schema=1'
        "dependencyId=$Id"
        "declaredVersion=$Declared"
        "observedVersion=$Observed"
        'decision=retain-unsupported'
    ) | Set-Content -LiteralPath $temporary -Encoding ASCII
    Move-Item -LiteralPath $temporary -Destination $path -Force
}

function Read-NewerChoice($Dependency, [string]$Observed, [string]$ActivePath) {
    if ([Console]::IsInputRedirected -or -not [Environment]::UserInteractive) {
        [Console]::Error.WriteLine('Dependency policy result: interaction-required.')
        [Console]::Error.WriteLine("Dependency: $($Dependency.displayName)")
        [Console]::Error.WriteLine("Expected: $($Dependency.version)")
        [Console]::Error.WriteLine("Observed: $Observed ($ActivePath)")
        [Console]::Error.WriteLine("Target: $TargetName/$RoleName")
        [Console]::Error.WriteLine('Next action: rerun chezmoi apply from an interactive terminal.')
        return 'interaction-required'
    }
    while ($true) {
        Write-Host "$($Dependency.displayName) $Observed is newer than declared version $($Dependency.version)."
        $choice = Read-Host 'Choose 1) downgrade, 2) keep unsupported, or 3) cancel'
        switch ($choice) {
            { $_ -in @('1', 'downgrade') } { return 'downgrade' }
            { $_ -in @('2', 'keep') } { return 'retain-unsupported' }
            { $_ -in @('3', 'cancel') } { return 'cancelled' }
            default { Write-Host 'Invalid choice. Enter 1, 2, or 3.' }
        }
    }
}

function Get-ArchiveMember([string]$Root, [string]$Member) {
    $normalized = $Member -replace '/', [IO.Path]::DirectorySeparatorChar
    $exact = Join-Path $Root $normalized
    if (Test-Path -LiteralPath $exact) { return $exact }
    Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object Name -eq ([IO.Path]::GetFileName($Member)) |
        Select-Object -First 1 -ExpandProperty FullName
}

function Get-StagedPath($Item) {
    Join-Path $StageRoot "$($Item.Dependency.id).$($Item.Target.archive)"
}

$chezmoi = Find-Chezmoi
$policyJson = & $chezmoi -S $RepositoryRoot execute-template '{{ .dependencyPolicy | toJson }}'
if ($LASTEXITCODE -ne 0) { throw 'Unable to render dependency policy.' }
$policy = $policyJson | ConvertFrom-Json

if ($TargetName -notin @($policy.supportedTargets)) {
    throw "Dependency policy result: target-unsupported ($TargetName)."
}

New-Item -ItemType Directory -Force -Path $StateRoot, $BinRoot, $StageRoot | Out-Null
try {
    $pendingOverrides = [Collections.Generic.List[object]]::new()
    $unsupported = $false
    $dependencies = foreach ($property in $policy.dependencies.PSObject.Properties) {
        $dependency = $property.Value
        $dependency | Add-Member -NotePropertyName id -NotePropertyValue $property.Name -Force
        if ($Workstation -or 'server' -in @($dependency.roles)) { $dependency }
    }
    $dependencies = @($dependencies | Sort-Object installOrder)
    $plan = foreach ($dependency in $dependencies) {
        $target = $dependency.targets.$TargetName
        if (-not $target) { throw "Dependency policy result: target-unsupported ($($dependency.id)/$TargetName)." }
        if ($target.strategy -eq 'platform-exception') {
            [pscustomobject]@{ Dependency = $dependency; Target = $target; Observed = 'exception'; Path = $null; Action = 'exception' }
            continue
        }
        if ($dependency.kind -eq 'font') {
            $fontStatus = Get-FontIdentityStatus $target
            $observed = if ($fontStatus -eq 'exact') { $dependency.version } else { $fontStatus }
            $path = $FontRoot
        }
        else {
            $result = Get-ObservedExecutable $dependency
            $observed = $result.Version
            $path = $result.Path
        }
        $action = if ($observed -eq $dependency.version) { 'already-compatible' } elseif ($observed -eq 'duplicate-active-path') { 'blocked' } else { 'install' }
        if ($action -eq 'install' -and $dependency.kind -eq 'executable' -and $observed -notin @('missing', 'missing-or-different') -and
            (Compare-PolicyVersion $observed $dependency.version) -eq 'newer') {
            if (Test-RetainOverride $dependency.id $dependency.version $observed) {
                $action = 'retain-unsupported'
                $unsupported = $true
            }
            else {
                $choice = Read-NewerChoice $dependency $observed $path
                switch ($choice) {
                    downgrade { $action = 'install' }
                    'retain-unsupported' {
                        $action = 'retain-unsupported'
                        $unsupported = $true
                        $pendingOverrides.Add([pscustomobject]@{ Id = $dependency.id; Declared = $dependency.version; Observed = $observed })
                    }
                    cancelled { Write-Host 'Dependency policy result: cancelled.'; exit 0 }
                    'interaction-required' { exit 1 }
                }
            }
        }
        [pscustomobject]@{
            Dependency = $dependency
            Target = $target
            Observed = $observed
            Path = $path
            Action = $action
        }
    }

    $blockedItems = @($plan | Where-Object Action -eq 'blocked')
    if ($blockedItems.Count) {
        [Console]::Error.WriteLine('Dependency policy result: preflight-blocked.')
        foreach ($item in $blockedItems) {
            [Console]::Error.WriteLine("Dependency: $($item.Dependency.displayName)")
            [Console]::Error.WriteLine("Expected: $($item.Dependency.version)")
            [Console]::Error.WriteLine("Observed: duplicate-active-path ($($item.Path) and $env:WINDIR\Fonts)")
            [Console]::Error.WriteLine("Target: $TargetName/$RoleName")
            [Console]::Error.WriteLine('Next action: review duplicate font installations in Windows Settings > Personalization > Fonts; no copy was removed automatically.')
        }
        exit 1
    }

    if (-not ($plan.Action -contains 'install')) {
        foreach ($override in $pendingOverrides) { Save-RetainOverride $override.Id $override.Declared $override.Observed }
        if ($unsupported) {
            Write-Host 'Dependency policy result: unsupported (retained newer dependency).'
        }
        else {
            Write-Host 'Dependency policy result: already-compatible.'
        }
        exit 0
    }

    $failures = [Collections.Generic.List[object]]::new()
    foreach ($item in $plan) {
        if ($item.Target.strategy -ne 'official-artifact') { continue }
        $destination = Get-StagedPath $item
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $item.Target.url -OutFile $destination
            $actual = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($actual -ne $item.Target.sha256) { throw "checksum-mismatch ($actual)" }
        }
        catch {
            $failures.Add([pscustomobject]@{ Item = $item; Reason = $_.Exception.Message })
        }
    }
    if ($failures.Count) {
        [Console]::Error.WriteLine('Dependency policy result: preflight-blocked.')
        foreach ($failure in $failures) {
            $item = $failure.Item
            [Console]::Error.WriteLine("Dependency: $($item.Dependency.displayName)")
            [Console]::Error.WriteLine("Expected: $($item.Dependency.version)")
            [Console]::Error.WriteLine("Observed: unavailable ($($failure.Reason))")
            [Console]::Error.WriteLine("Target: $TargetName/$RoleName")
            [Console]::Error.WriteLine('Next action: verify the declared release asset and network access.')
        }
        exit 1
    }

    foreach ($override in $pendingOverrides) { Save-RetainOverride $override.Id $override.Declared $override.Observed }

    $changed = [Collections.Generic.List[object]]::new()
    $installItems = @($plan | Where-Object Action -eq 'install')
    foreach ($item in $installItems) {
        if ($item.Action -ne 'install') { continue }
        try {
            $dependency = $item.Dependency
            $target = $item.Target
            $archivePath = Get-StagedPath $item
            if ($dependency.id -eq 'wezterm') {
                $process = Start-Process -FilePath $archivePath -ArgumentList '/S' -Wait -PassThru
                if ($process.ExitCode -ne 0) { throw "WezTerm installer failed with exit code $($process.ExitCode)." }
            }
            else {
                $expanded = Join-Path $StageRoot "expanded-$($dependency.id)"
                Expand-Archive -LiteralPath $archivePath -DestinationPath $expanded -Force
                if ($dependency.kind -eq 'font') {
                    New-Item -ItemType Directory -Force -Path $FontRoot | Out-Null
                    New-Item -ItemType Directory -Force -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' | Out-Null
                    foreach ($property in $target.installedFiles.PSObject.Properties) {
                        $source = Get-ChildItem -LiteralPath $expanded -Recurse -File | Where-Object Name -eq $property.Name |
                            Select-Object -First 1
                        if (-not $source) { throw "Font archive member is missing: $($property.Name)" }
                        $actual = (Get-FileHash -LiteralPath $source.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
                        if ($actual -ne $property.Value) { throw "Installed font hash mismatch: $($property.Name)" }
                        Copy-Item -LiteralPath $source.FullName -Destination (Join-Path $FontRoot $property.Name) -Force
                        $installedFontPath = Join-Path $FontRoot $property.Name
                        New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' `
                            -Name "$($property.Name) (TrueType)" -Value $installedFontPath -PropertyType String -Force | Out-Null
                    }
                }
                else {
                    $sourcePath = Get-ArchiveMember $expanded $target.member
                    if (-not $sourcePath) { throw "$($dependency.displayName) archive member is missing: $($target.member)" }
                    $commandName = Get-CommandName $dependency.id
                    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $BinRoot $commandName) -Force
                    if ($dependency.id -eq 'helix') {
                        $runtime = Get-ChildItem -LiteralPath $expanded -Directory -Recurse | Where-Object Name -eq runtime |
                            Select-Object -First 1
                        if ($runtime) {
                            $runtimeTarget = Join-Path $HOME '.config\helix\runtime'
                            if (Test-Path -LiteralPath $runtimeTarget) { Remove-Item -LiteralPath $runtimeTarget -Recurse -Force }
                            New-Item -ItemType Directory -Force -Path (Split-Path $runtimeTarget) | Out-Null
                            Copy-Item -LiteralPath $runtime.FullName -Destination $runtimeTarget -Recurse
                        }
                    }
                }
            }
            $changed.Add($item)
        }
        catch {
            [Console]::Error.WriteLine('Dependency policy result: partial-failure.')
            [Console]::Error.WriteLine('Changed:')
            if ($changed.Count) {
                foreach ($changedItem in $changed) {
                    [Console]::Error.WriteLine("  $($changedItem.Dependency.displayName)")
                    [Console]::Error.WriteLine("  Removal guidance: $($changedItem.Dependency.removeGuidance.windows)")
                }
            }
            else { [Console]::Error.WriteLine('  (none)') }
            [Console]::Error.WriteLine('Failed:')
            [Console]::Error.WriteLine("  $($item.Dependency.displayName): $($_.Exception.Message)")
            [Console]::Error.WriteLine('Pending:')
            foreach ($pendingItem in $installItems) {
                if ($pendingItem -eq $item -or $changed -contains $pendingItem) { continue }
                [Console]::Error.WriteLine("  $($pendingItem.Dependency.displayName)")
            }
            [Console]::Error.WriteLine('The next chezmoi apply reassesses observed state and resumes convergence.')
            exit 1
        }
    }

    $verificationFailed = $false
    foreach ($item in $plan) {
        if ($item.Target.strategy -eq 'platform-exception') { continue }
        if ($item.Action -eq 'retain-unsupported') { continue }
        if ($item.Dependency.kind -eq 'font') {
            if (-not (Test-FontIdentity $item.Target)) { $verificationFailed = $true }
        }
        else {
            $observed = Get-ObservedExecutable $item.Dependency
            if ($observed.Version -ne $item.Dependency.version) { $verificationFailed = $true }
        }
    }
    if ($verificationFailed) { throw 'Dependency policy verification failed after installation.' }
    if ($unsupported) {
        Write-Host "Dependency policy result: unsupported (retained newer dependency; $TargetName/$RoleName)."
    }
    else {
        Write-Host "Dependency policy result: compatible ($TargetName/$RoleName)."
    }
}
finally {
    if (Test-Path -LiteralPath $StageRoot) { Remove-Item -LiteralPath $StageRoot -Recurse -Force }
}
