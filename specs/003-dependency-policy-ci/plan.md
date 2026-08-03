# Implementation Plan: Dependency Policy CI

**Branch**: `ci/dependency-policy` | **Date**: 2026-08-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-dependency-policy-ci/spec.md`

## Summary

Turn the existing dependency-policy scripts into two stable repository test entrypoints and run them
on disposable Windows, Linux, Apple Silicon macOS, and Intel macOS environments for every pull
request. Add an authenticated-free verifier that compares each declared GitHub release URL and
SHA-256 digest with upstream release metadata, plus quality gates for managed targets, English-only
changes, shell syntax, and whitespace. Preserve existing manual evidence and keep automated real
installation smoke tests for a later, independently specified feature.

## Technical Context

**Language/Version**: PowerShell 7 on CI with Windows PowerShell 5.1 compatibility where required;
POSIX `sh`; GitHub Actions workflow YAML; chezmoi 2.71.1 as the pinned render prerequisite  
**Primary Dependencies**: existing dependency-policy tests, git, chezmoi, GitHub REST release metadata,
standard hosted runner utilities  
**Storage**: committed workflow, runner scripts, test reports in job logs; no persistent runtime state  
**Testing**: PowerShell/POSIX entrypoint self-tests, manifest and mutation tests, platform contract
tests, template parsing, quality checks, workflow matrix execution  
**Target Platform**: Windows x86_64, Ubuntu x86_64, macOS arm64, macOS x86_64 for required CI; DNF,
Alpine, Linux arm64, and workstation installation smoke tests deferred to phase two  
**Project Type**: cross-platform dotfiles repository automation  
**Performance Goals**: every required platform job completes within 15 minutes; duplicate pull-request
runs for the same branch are cancelled  
**Constraints**: read-only repository token, no secrets for pull requests, no `pull_request_target`, no
persistent self-hosted runner for untrusted code, no automatic `chezmoi apply` on user machines  
**Scale/Scope**: two test entrypoints, nine current dependency-policy tests, four required runner
environments, eight dependencies, seven normalized artifact targets

## Constitution Check

*GATE: Passed before research and re-checked after design.*

| Principle | Design evidence | Result |
|---|---|---|
| Cross-Platform Consistency | Required jobs cover Windows, Linux, macOS arm64, and macOS x86_64 with shared entrypoint contracts. | Pass |
| One-Command, Repeatable Setup | Local and CI execution use the same two committed commands and clean ephemeral state. | Pass |
| Native Package Management First | CI prerequisites use official portable artifacts where runner package history cannot guarantee the pin; managed runtime policy is unchanged. | Pass |
| Pinned Critical Tool Versions | The manifest remains authoritative and the render prerequisite is pinned. | Pass |
| Workstation and Server Separation | Required CI is non-mutating; future smoke tests start with server role and defer workstation installations. | Pass |
| English Repository Content | Added-line language validation is a required quality gate. | Pass |
| Platform-Specific Verification | Results name their environment and evidence class; unexecuted installation targets remain deferred. | Pass |

Post-design re-check: no constitution exception is required. The workflow adds verification only and
does not alter dependency installation or user configuration.

## Project Structure

### Documentation (this feature)

```text
specs/003-dependency-policy-ci/
|-- spec.md
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- validation-entrypoints.md
|   `-- workflow-checks.md
`-- tasks.md
```

### Source Code (repository root)

```text
.github/workflows/
`-- dependency-policy.yml

tests/dependency-policy/
|-- run-all.ps1
|-- run-all.sh
|-- Test-ReleaseAssets.ps1
|-- Test-RunnerEntrypoints.ps1
|-- test-runner-entrypoints.sh
|-- Test-DependencyManifest.ps1
|-- test-dependency-manifest.sh
`-- existing platform and reconciliation tests

README.md
```

**Structure Decision**: Workflow YAML owns triggers, permissions, environment setup, and job routing.
Committed runner scripts own the exact test inventory and failure semantics. Test logic stays in the
existing focused scripts, so local execution and CI cannot drift into separate suites.

## Implementation Phases

### Phase A - Stable local entrypoints

1. Add PowerShell and POSIX entrypoint contract tests that initially fail because no aggregate runner
   exists.
2. Add explicit ordered inventories for all current tests; fail if an expected file is missing and
   stop on the first failing test with its name preserved.
3. Add shared quality checks for stale managed targets, changed-line language, syntax, and whitespace,
   accepting an optional comparison base for local or pull-request use.

### Phase B - Artifact integrity verification

1. Render the central policy through chezmoi.
2. Group official GitHub release URLs by owner, repository, and tag.
3. Retrieve each release record without credentials and match exact asset URLs. Compare the published
   digest when present; otherwise download the exact historical asset to a disposable path and hash it.
4. Distinguish policy mismatch from transient upstream/network failure in diagnostics while failing
   both required checks.

### Phase C - Required cross-platform workflow

1. Add a least-privilege pull-request, main-push, and manual workflow with unique job names,
   concurrency cancellation, and 15-minute job timeouts.
2. Pin and install chezmoi before invoking repository entrypoints.
3. Run Windows tests on Windows and POSIX tests on Ubuntu plus both macOS architectures.
4. Run artifact and repository-quality checks once per revision without duplicating network work in
   every matrix cell.
5. Document the required branch-protection check names and local reproduction commands.

### Future Feature - Installation smoke tests

This work is out of scope and intentionally not part of this feature's implementation tasks. A later PR
will add scheduled/manual clean server installs, active path/version capture, and second-apply
idempotency for apt, DNF, apk, and available arm64 targets before adding workstation smoke tests.

## Complexity Tracking

No constitution violations require justification.
