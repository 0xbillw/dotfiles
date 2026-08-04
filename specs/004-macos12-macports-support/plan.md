# Implementation Plan: macOS 12 MacPorts Support

**Branch**: `004-macos12-macports-support` | **Date**: 2026-08-03 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-macos12-macports-support/spec.md`

## Summary

Add a Monterey-specific macOS dependency path for Mac mini systems that treats Homebrew as unsuitable
for macOS 12 while preserving the current macOS behavior for newer releases. The implementation will
keep checksum-verified official artifacts as the preferred source when they remain compatible on
Monterey, introduce MacPorts-aware target selection and prerequisite diagnostics for legacy macOS, add
MacPorts PATH awareness, extend fixtures for blocked and mixed-manager states, and document real Mac
mini validation without claiming unperformed platform verification.

## Technical Context

**Language/Version**: chezmoi templates; POSIX `sh`; YAML dependency data; Markdown documentation;
PowerShell and shell-based policy tests where existing test harnesses require them
**Primary Dependencies**: chezmoi template data/functions, macOS `sw_vers` and `uname`, MacPorts `port`,
existing official upstream release artifacts, POSIX archive/hash utilities, dependency-policy fixtures
**Storage**: committed `.chezmoidata/dependencies.yaml`; generated shell configuration templates;
machine-local dependency state under `${XDG_STATE_HOME:-$HOME/.local/state}`; committed evidence notes
**Testing**: static/template checks on the development host; macOS installer fixtures for Monterey and
newer macOS target selection; existing dependency-policy tests; real-machine validation on a macOS 12
Monterey Mac mini when available
**Target Platform**: macOS 12 Monterey x86_64 and arm64 Mac mini workstation/server roles, with regression
coverage for existing newer macOS x86_64 and arm64 targets
**Project Type**: cross-platform dotfiles and dependency bootstrap scripts
**Performance Goals**: second apply performs no dependency mutation; prerequisite failure stops before
network or installation work; target detection completes before dependency preflight
**Constraints**: official artifact compatibility remains preferred, MacPorts is a legacy macOS path rather
than the new default for every macOS release, no silent version substitution, no automatic removal of
Homebrew/manual installations, no GUI/font installation for server role, English-only repository content
**Scale/Scope**: existing eight managed dependencies, one additional legacy macOS version category,
two macOS CPU architectures, two roles, existing macOS installer and shared POSIX reconciliation logic

## Constitution Check

*GATE: Passed before Phase 0 and re-checked after Phase 1.*

| Principle | Design evidence | Result |
|---|---|---|
| Cross-Platform Consistency | Monterey uses the same declared dependency policy and compatibility reporting model while adding a legacy macOS target-selection branch. | Pass |
| One-Command, Repeatable Setup | Missing MacPorts prerequisites block before mutation; successful second applies are no-ops; PATH updates must be duplicate-safe. | Pass |
| Native Package Management First | MacPorts becomes the appropriate supported manager for legacy macOS, while official artifacts remain allowed when native packages cannot provide the required compatible version. | Pass |
| Pinned Critical Tool Versions | Monterey must not accept undeclared replacement versions and must verify active versions/assets before reporting compatibility. | Pass |
| Workstation and Server Separation | WezTerm and font handling remain workstation-only on Monterey; server role keeps CLI-only behavior. | Pass |
| English Repository Content | All planned specs, diagnostics, tests, and docs are English. | Pass |
| Platform-Specific Verification | Fixture coverage is required for macOS target-selection behavior; real Mac mini evidence is recorded as verified or explicitly deferred. | Pass |

Post-design re-check: the research decisions, data model, contracts, and quickstart preserve every gate.
No constitution exception is required.

## Project Structure

### Documentation (this feature)

```text
specs/004-macos12-macports-support/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- macos-target-selection.md
|   `-- monterey-reconciliation.md
`-- tasks.md                 # Created later by $speckit-tasks
```

### Source Code (repository root)

```text
.chezmoidata/
`-- dependencies.yaml                         # Extend target/source declarations only if Monterey needs source-specific overrides

.chezmoitemplates/
|-- dependency-policy-posix.sh.tmpl           # Shared preflight/reconciliation support for any MacPorts native-package entries
`-- nushell-config.nu                         # Add MacPorts executable paths without duplicating entries

run_onchange_before_10-install-packages-darwin.sh.tmpl
                                                # Detect macOS major version and select legacy/newer macOS package family

README.md                                      # Document Monterey prerequisite, setup path, and troubleshooting

tests/dependency-policy/
|-- test-darwin-dependency-install.sh          # Add Monterey and mixed-manager fixtures
|-- README.md                                  # Record fixture coverage and real-machine boundary
`-- evidence/
    `-- macos.md                               # Record Monterey Mac mini verification or explicit deferral
```

**Structure Decision**: Keep the repository's existing dotfiles layout. Add Monterey-aware behavior to the
macOS entrypoint and shared POSIX policy logic instead of creating a separate installer. Use the existing
manifest and fixture directories so Monterey support is reviewed alongside current dependency-policy
coverage.

## Implementation Phases

### Phase A - Target selection and source policy

1. Classify macOS 12 as `darwin-monterey` plus architecture and role while leaving newer macOS targets on
   the existing path.
2. Select MacPorts as the legacy macOS package-management family for Monterey prerequisite diagnostics and
   any exact native package entries.
3. Continue selecting official artifacts for Monterey when the declared artifact is compatible and
   checksum-verifiable.
4. Fail before mutation when MacPorts is required but `port` is missing, not discoverable, or not usable.

### Phase B - Reconciliation, PATH, and diagnostics

1. Add MacPorts-aware native package preflight and install behavior only for manifest entries that declare
   a MacPorts package source.
2. Add `/opt/local/bin` and `/opt/local/sbin` as macOS candidate paths without creating duplicates or
   demoting the managed user-local bin directory.
3. Extend blocked diagnostics with selected package-management path, missing prerequisite, active path, and
   next action.
4. Preserve user-owned Homebrew and manual installations: report conflicts, never remove them automatically.

### Phase C - Fixtures, evidence, and docs

1. Add macOS fixture scenarios for Monterey Intel/arm64, missing MacPorts, MacPorts not on PATH,
   Homebrew-plus-MacPorts conflict, dependency management disabled, workstation, and server roles.
2. Re-run existing dependency-policy checks and confirm newer macOS x86_64/arm64 behavior remains unchanged.
3. Update README setup/troubleshooting sections with Monterey-specific prerequisites and validation steps.
4. Record real Mac mini validation in `tests/dependency-policy/evidence/macos.md`, or explicitly mark it
   deferred with commands the user can run on the Monterey machine.

## Complexity Tracking

No constitution violations require justification.
