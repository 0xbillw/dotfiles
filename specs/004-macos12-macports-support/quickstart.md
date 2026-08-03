# Quickstart: Validate macOS 12 MacPorts Support

## Prerequisites

- Repository checkout with the feature implementation applied.
- For static checks: a development host capable of running the existing dependency-policy test scripts.
- For real-machine validation: a Mac mini running macOS 12 Monterey, with both workstation and server role
  scenarios available through fresh or reset chezmoi initialization data.
- MacPorts installed on the real Monterey validation host when testing the compatible path.

## Static and fixture validation

### 1. Confirm the active feature directory

```sh
cat .specify/feature.json
```

Expected: the feature directory is `specs/004-macos12-macports-support`.

### 2. Run dependency-policy manifest checks

```sh
sh tests/dependency-policy/test-dependency-manifest.sh
```

Expected: the manifest is valid, all supported target declarations are complete, and any Monterey-specific
source additions use exact versions.

### 3. Run macOS installer fixtures

```sh
sh tests/dependency-policy/test-darwin-dependency-install.sh
```

Expected fixture coverage:

- macOS 12 Intel workstation selects the Monterey legacy path.
- macOS 12 Apple Silicon workstation selects the Monterey legacy path.
- missing `port` produces prerequisite-blocked without mutation when a MacPorts source is required.
- `port` installed outside PATH produces a next-action diagnostic.
- Homebrew and MacPorts both present produces an active-path diagnostic without deleting either source.
- dependency management disabled exits before package-manager checks.
- server role excludes WezTerm and JetBrainsMono Nerd Font.
- newer macOS x86_64 and arm64 fixtures keep the existing macOS path.

### 4. Run POSIX reconciliation checks

```sh
sh tests/dependency-policy/test-posix-reconciliation.sh
```

Expected: Monterey changes do not regress shared retain, newer-version, preflight, or partial-failure
semantics.

### 5. Run repository quality checks

```sh
pwsh -NoLogo -NoProfile -File tests/dependency-policy/Test-DependencyManifest.ps1
pwsh -NoLogo -NoProfile -File tests/dependency-policy/Test-CIWorkflow.ps1
```

Expected: PowerShell validators continue to pass with the updated support matrix and CI expectations.

## Real Mac mini validation

Run these commands on the macOS 12 Monterey Mac mini and record results in
`tests/dependency-policy/evidence/macos.md`.

### 1. Record host identity

```sh
sw_vers
uname -m
command -v port || true
port version || true
```

Expected: `sw_vers` reports macOS 12.x, `uname -m` is `x86_64` or `arm64`, and `port version` succeeds for
the compatible-path scenario.

### 2. Validate prerequisite-blocked path

Temporarily run with `port` unavailable from PATH, then apply the dotfiles with dependency management
enabled.

Expected: setup stops before dependency mutation and reports the missing MacPorts prerequisite, selected
Monterey package-management path, and next action.

### 3. Validate workstation compatible path

With MacPorts available, apply the dotfiles as a workstation.

Expected: every workstation-applicable managed dependency is installed or verified; WezTerm and
JetBrainsMono Nerd Font are included; the final result is compatible or an explicitly documented retained
unsupported state.

### 4. Validate idempotency

Run the same apply command a second time.

Expected: no compatible managed dependency is reinstalled, no duplicate PATH entries are created, and the
same active versions/assets are reported.

### 5. Validate server role

Apply the dotfiles with the server role on the same macOS 12 host or a reset local state.

Expected: shared CLI tools are handled, while WezTerm and JetBrainsMono Nerd Font are excluded.

### 6. Validate mixed-manager diagnostics

If Homebrew is also installed, place a Homebrew-managed executable ahead of the expected active path and
run dependency verification.

Expected: setup reports the active Homebrew path and selected Monterey package-management path, does not
remove the Homebrew installation, and provides a safe next action.

## Evidence boundary

If no macOS 12 Mac mini is available during implementation, the PR must explicitly mark real Monterey
validation as deferred and include the exact commands above for the user to run. Fixture-only evidence must
not be described as full real-platform validation.
