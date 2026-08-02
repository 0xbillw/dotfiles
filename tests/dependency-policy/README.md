# Dependency policy verification

These fixtures validate the dependency compatibility manifest and rendered installers without
installing software on the development host.

## Safety boundary

- Tests must use a disposable directory supplied through `DOTFILES_TEST_ROOT`.
- Tests must set `DOTFILES_DEPENDENCY_TEST=1` before invoking a rendered installer.
- Network and package-manager commands are replaced by fixture commands under
  `tests/dependency-policy/fixtures/bin`.
- Tests must never write to the real user profile, package database, font registry, or system path.
- Real-machine validation is recorded separately under `tests/dependency-policy/evidence/`.

## Fixture environment

| Variable | Purpose |
|---|---|
| `DOTFILES_DEPENDENCY_TEST` | Must equal `1` for fixture-only installer execution. |
| `DOTFILES_TEST_ROOT` | Disposable root containing fake home, state, staging, and command logs. |
| `DOTFILES_TEST_TARGET` | Optional normalized target override used only by fixture builds. |
| `DOTFILES_TEST_SCENARIO` | Scenario name such as `missing`, `matching`, or `unavailable`. |
| `DOTFILES_TEST_INPUT` | Newline-delimited interactive answers for deterministic prompt tests. |

Production installer templates must ignore all `DOTFILES_TEST_*` variables unless
`DOTFILES_DEPENDENCY_TEST=1` is rendered into an isolated test copy.

## Evidence status

Static fixture results and real-machine results are different evidence classes. A target is marked
`verified` only after the commands in the feature quickstart run on that target. Otherwise it remains
`deferred` with the exact manual commands needed to verify it.

## Declared target coverage

| Target | CLI role | Workstation additions | Status |
|---|---|---|---|
| `windows-x86_64` | Six CLI dependencies | WezTerm and JetBrainsMono Nerd Font | Manifest validated |
| `darwin-x86_64` | Six CLI dependencies | WezTerm and JetBrainsMono Nerd Font | Manifest validated |
| `darwin-aarch64` | Six CLI dependencies | WezTerm and JetBrainsMono Nerd Font | Manifest validated |
| `linux-x86_64-gnu` | Six CLI dependencies | Nerd Font; WezTerm platform exception | Manifest validated |
| `linux-aarch64-gnu` | Six CLI dependencies | Nerd Font; WezTerm platform exception | Manifest validated |
| `linux-x86_64-musl` | Six CLI dependencies | Nerd Font; WezTerm platform exception | Manifest validated |
| `linux-aarch64-musl` | Six CLI dependencies | Nerd Font; WezTerm platform exception | Manifest validated |

Windows ARM64 is intentionally not declared because Zellij 0.44.1 and Helix 25.07.1 do not both
publish the required Windows ARM64 artifacts. Static manifest validation passed on 2026-08-01 with
both PowerShell and POSIX validators. Real-platform status remains deferred until evidence files are
completed.

## TDD baseline

On 2026-08-01, the Windows, macOS, and Linux installer contract fixtures all failed at their first
assertion because the existing platform scripts did not consume `.dependencyPolicy.dependencies`.
This is the expected pre-implementation baseline for User Story 1. The fixtures also require isolated
test mode, unsupported-target blocking, full preflight, installed font-file verification, disabled
management, matching-version no-op behavior, duplicate-path reporting, and role filtering.

## User Story 1 checkpoint

The post-implementation PowerShell and POSIX manifest validators, consumer-literal checks, platform
fixture contracts, PowerShell parser, rendered POSIX shell syntax check, and Windows template render
all pass on the Windows development host. The implementation now consumes the shared manifest,
performs full artifact staging and checksum validation before managed mutations, filters workstation
dependencies, and verifies installed executables/font files.

Real Windows installation is deferred until the workstation owner approves changing installed tool
versions. Real macOS, apt, dnf, apk, and Linux arm64 execution is deferred to the corresponding
evidence tasks; static rendering is not represented as real-platform verification.

## User Story 2 checkpoint

The Windows and POSIX reconciliation contracts failed before implementation because no downgrade,
retain, cancellation, non-interactive, or journal behavior existed. After implementation, both
contracts and both script parsers pass. Retain records are keyed by dependency, declared version, and
observed version; invalid input retries; non-interactive newer versions stop before preflight; partial
failures report changed, failed, and pending items without automatic rollback. Starship and zoxide
integration generation accepts only an exact version or a matching retain record.

Interactive and forced runtime-failure execution remains part of disposable real-machine evidence;
the Windows development host was not mutated for this static checkpoint.

## User Story 3 checkpoint

Before the shared upgrade validator was extended, both policy-upgrade tests failed: PowerShell lacked
mutation input and POSIX could not prove consumer parity. They now pass. A version-only mutation with
stale artifact URLs is rejected, incomplete exceptions are rejected, retain records are keyed by both
declared and observed versions, and all platform installers consume the shared declaration.

## Release decision

**Implementation status**: Ready for review; not yet cross-platform verified.

All manifest, mutation, consumer-literal, Windows/POSIX fixture-contract, PowerShell parser, rendered
shell syntax, chezmoi managed-target, English-only added-line, and Git whitespace checks pass. The
implementation preserves unrelated installations, never removes duplicate command/font copies,
stages and checks every applicable payload before managed mutation, records retain consent outside the
repository, and reports unsupported targets or partial failures explicitly.

The Windows audit found exact Nushell, Zellij, WezTerm, and user-font files; missing Helix/zoxide/fzf;
a newer Starship; and conflicting system-level font copies. Reconciliation was deliberately not
applied because it requires an interactive downgrade/retain decision and user review of duplicate
fonts. macOS, apt, dnf, apk, and Linux arm64 evidence remains deferred in the platform evidence files.
Do not represent this branch as fully cross-platform verified until those commands are executed and
the evidence statuses are updated.
