# Implementation Plan: Align Dependency Versions

**Branch**: `feat/align-dependency-versions` | **Date**: 2026-08-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-align-dependency-versions/spec.md`

## Summary

Create one chezmoi data manifest for the eight managed dependencies and make every platform installer
consume it. Reconciliation will inspect the active executable or font, resolve an exact native package
when that is reliable and an official prebuilt artifact otherwise, stage and integrity-check every
role-applicable payload before mutation, then apply changes sequentially with resumable diagnostics.
Machine-local retain overrides let users explicitly keep newer unsupported versions without weakening
the shared compatibility declaration.

## Technical Context

**Language/Version**: chezmoi templates; POSIX `sh`; Windows batch/PowerShell invoked by batch; Nushell
0.114.1 for post-install integration generation  
**Primary Dependencies**: chezmoi template data/functions, `winget`, `apt`/`dnf`/`apk`, Homebrew,
official upstream release artifacts, OS archive/hash/font utilities  
**Storage**: committed `.chezmoidata/dependencies.yaml`; machine-local reconciliation state under the
platform state-data directory; temporary preflight staging directory  
**Testing**: template rendering and English/static checks on the development host; isolated installer
fixtures for decision logic; real-machine verification on representative Windows, macOS, glibc Linux,
and musl Linux targets  
**Target Platform**: existing repository scope only: Windows x86_64; macOS x86_64/arm64; supported
apt-, dnf-, and apk-based Linux x86_64/arm64; workstation and remote/server roles  
**Project Type**: cross-platform dotfiles and bootstrap scripts  
**Performance Goals**: unchanged second apply performs no installs; preflight fetches each applicable
artifact at most once per run; version inspection completes before mutation  
**Constraints**: exact versions, no source builds, no silent fallback, no irrelevant workstation
packages on servers, no automatic rollback after runtime partial failure, no modification of unrelated
software or user configuration  
**Scale/Scope**: eight dependencies, three OS families, five package-manager paths, two roles, two
principal CPU architectures, three platform installer templates

## Constitution Check

*GATE: Passed before Phase 0 and re-checked after Phase 1.*

| Principle | Design evidence | Result |
|---|---|---|
| Cross-Platform Consistency | One manifest and one reconciliation contract drive all platform scripts. | Pass |
| One-Command, Repeatable Setup | Full preflight precedes mutation; matching versions are no-ops; partial runs resume from observed state. | Pass |
| Native Package Management First | Exact native packages are preferred; official artifacts are used only where managers cannot guarantee the pin. | Pass |
| Pinned Critical Tool Versions | All eight dependencies have exact declarations and active-installation verification. | Pass |
| Workstation and Server Separation | WezTerm and the font are workstation-only manifest entries. | Pass |
| English Repository Content | Manifest fields, scripts, diagnostics, and documentation are English. | Pass |
| Platform-Specific Verification | Quickstart defines static and real-machine checks per platform, architecture, and role. | Pass |

Post-design re-check: the centralized manifest, reconciliation contract, state model, and verification
matrix preserve every gate. No constitution exception is required.

## Project Structure

### Documentation (this feature)

```text
specs/002-align-dependency-versions/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- dependency-manifest.md
|   `-- reconciliation.md
`-- tasks.md                 # Created later by $speckit-tasks
```

### Source Code (repository root)

```text
.chezmoidata/
`-- dependencies.yaml                         # Authoritative versions and target resolution

run_onchange_before_10-install-packages.cmd.tmpl
run_onchange_before_10-install-packages-darwin.sh.tmpl
run_onchange_before_10-install-packages-linux.sh.tmpl
run_after_generate-nushell-integrations.cmd.tmpl
run_after_generate-nushell-integrations.sh.tmpl

README.md
```

**Structure Decision**: Keep the repository's existing platform-template structure and add only a
shared chezmoi data declaration. Platform installers remain responsible for native package-manager,
archive, path, and privilege details but must render every managed version and artifact coordinate
from the shared declaration. Reconciliation rules are contractually identical across scripts.

## Implementation Phases

### Phase A - Declare and validate compatibility data

1. Add the eight dependency records and target mappings described by the manifest contract.
2. Add render-time/static validation for missing versions, target mappings, hashes, role applicability,
   exception fields, and duplicate identities.
3. Document the initial compatibility set and the deliberate update procedure.

### Phase B - Build platform reconciliation

1. Refactor each installer to create the same observed-state and requested-action model.
2. Reject unknown OS, package-manager, architecture, or libc combinations with an actionable
   target-unsupported result rather than guessing, and exit without downloads or state writes when
   automatic dependency management is disabled.
3. Prefer an exact native package transaction only when the platform manager can request and verify
   that exact version; otherwise select the declared official artifact.
4. Stage every applicable payload, verify checksums and archive contents, and report all preflight
   failures before any installation operation.
5. Reconcile in deterministic order, verify the active path/version after each change, and stop with a
   partial-state report and safe removal guidance on runtime failure.
6. Persist and invalidate machine-local retain overrides according to the declared-version key, and
   allow downstream integration generation to use an exact match or a matching retained executable
   while preserving unsupported status.

### Phase C - Verify and document

1. Exercise missing, older, matching, newer, unavailable, duplicate-path, wrong-architecture, role,
   second-apply, and partial-failure scenarios.
2. Record static checks plus real-platform evidence without claiming untested platforms.
3. Update README compatibility, verification, upgrade, exception, and troubleshooting sections.

## Complexity Tracking

No constitution violations require justification.
