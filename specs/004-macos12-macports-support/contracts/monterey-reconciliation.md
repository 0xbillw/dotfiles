# Contract: Monterey Dependency Reconciliation

## Purpose

Monterey dependency reconciliation extends the existing policy model with MacPorts-aware prerequisites and
conflict diagnostics while preserving official artifact compatibility and user-owned software.

## Inputs

- Selected macOS target from the macOS target-selection contract.
- Valid dependency compatibility manifest.
- Role-filtered managed dependency list.
- Active executable/font state, including candidate duplicate paths.
- MacPorts prerequisite state when a selected dependency source requires it.
- Machine-local retain override state.

## Ordered behavior

1. Select each applicable dependency source from the manifest.
2. Prefer a declared official artifact when it is compatible with Monterey and checksum-verifiable.
3. Use a MacPorts native package only when the manifest explicitly declares a MacPorts source for that
   dependency and target.
4. If a MacPorts source is selected, verify the MacPorts prerequisite before package or artifact preflight.
5. Observe active installations and classify each active path as managed user-local, MacPorts, Homebrew,
   manual, font registry, absent, or unknown.
6. Report active Homebrew/manual conflicts when they affect compatibility; do not remove them automatically.
7. Preflight every selected artifact/package and collect all failures before mutation.
8. Apply changes in manifest order only after the complete applicable preflight succeeds.
9. Verify the active executable version or font asset after each change.
10. On success, report compatible or explicitly unsupported status according to retained-version state.

## Required diagnostics

Every blocked Monterey diagnostic includes:

```text
Dependency: <name or prerequisite>
Expected: <declared version, package, or prerequisite>
Observed: <observed version/path/state>
Target: macOS 12 Monterey/<architecture>/<role>/<package-management-path>
Next action: <safe user action>
```

Mixed-manager diagnostics additionally include the active path and the selected package-management path so
users can understand whether Homebrew, MacPorts, a managed artifact, or a manual binary is currently taking
precedence.

## Safety invariants

- Never silently substitute Homebrew for MacPorts on Monterey.
- Never silently substitute a different package or artifact version.
- Never remove Homebrew, MacPorts, or manual installations outside explicitly managed locations.
- Never install workstation-only GUI terminals or fonts for the server role.
- Never claim Monterey compatibility until every applicable active dependency is verified or a documented
  unsupported-retain state exists.
