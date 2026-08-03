# Tasks: Dependency Policy CI

**Input**: Design documents from `/specs/003-dependency-policy-ci/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: Test-first tasks are required because the feature exists to enforce validation behavior.
Every new entrypoint, asset verifier, and workflow contract must be observed failing before its
implementation is added.

**Organization**: Tasks are grouped by user story. Real installation smoke tests are explicitly out
of scope for this feature and receive no implementation tasks.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it changes different files and has no incomplete dependency.
- **[Story]**: Maps the task to a user story from `spec.md`.
- Every task names the exact file it creates or changes.

## Phase 1: Setup

**Purpose**: Establish CI test conventions without changing dependency installation behavior.

- [x] T001 Add aggregate-runner, release-metadata fixture, comparison-base, and no-host-mutation conventions to `tests/dependency-policy/README.md`
- [x] T002 [P] Add any CI-generated temporary and report paths required by the design to `.gitignore`

---

## Phase 2: Foundational

**Purpose**: Define contracts shared by all required platform jobs.

**CRITICAL**: User story implementation begins only after these contract tests exist and fail for the
missing entrypoints and workflow.

- [x] T003 [P] Add PowerShell contract tests for the explicit inventory, missing-test failure, stop-on-failure exit propagation, base-ref forwarding, suite count, and no production apply in `tests/dependency-policy/Test-RunnerEntrypoints.ps1`
- [x] T004 [P] Add POSIX contract tests for the explicit inventory, missing-test failure, stop-on-failure exit propagation, base-ref forwarding, suite count, and no production apply in `tests/dependency-policy/test-runner-entrypoints.sh`
- [x] T005 [P] Add release-asset verifier fixtures for matching, missing asset, digest mismatch, duplicate URL reuse, unsupported host, and upstream-unavailable diagnostics in `tests/dependency-policy/fixtures/release-assets.json`
- [x] T006 [P] Add static workflow contract assertions for triggers, read-only permissions, unique job names, runner architecture labels, timeouts, concurrency, pinned checkout, chezmoi setup, and entrypoint invocation in `tests/dependency-policy/Test-CIWorkflow.ps1`
- [x] T007 Run T003-T006 before implementation, confirm their first missing-artifact assertions fail, and record the red baseline in `tests/dependency-policy/README.md`

**Checkpoint**: The intended runner, verifier, and workflow behavior is executable as a failing
contract before production automation exists.

---

## Phase 3: User Story 1 - Trust Every Pull Request (Priority: P1) MVP

**Goal**: Every pull request receives stable required checks on Windows, Linux, macOS arm64, and macOS
x86_64 using the same committed commands maintainers run locally.

**Independent Test**: Run both aggregate entrypoints locally, introduce one disposable manifest error
and one missing inventory file, verify actionable failures, restore them, and verify all required jobs
pass on a pull request.

### Implementation for User Story 1

- [x] T008 [P] [US1] Implement the explicit PowerShell test inventory, environment setup, optional `-BaseRef`, per-test banner, stop-on-failure behavior, and exact success count in `tests/dependency-policy/run-all.ps1`
- [x] T009 [P] [US1] Implement the explicit POSIX test inventory, environment setup, optional base revision, per-test banner, stop-on-failure behavior, and exact success count in `tests/dependency-policy/run-all.sh`
- [x] T010 [US1] Implement changed-manifest detection, policy rendering, official GitHub release grouping, unique metadata retrieval, exact URL/digest comparison, historical-asset download fallback, fixture mode, and actionable result classes in `tests/dependency-policy/Test-ReleaseAssets.ps1`
- [x] T011 [P] [US1] Add changed-range English-only, whitespace, managed-target exclusion, stale installer-version, and available shell/template syntax checks to `tests/dependency-policy/run-all.ps1`
- [x] T012 [P] [US1] Add changed-range English-only, whitespace, managed-target exclusion, stale installer-version, and available shell/template syntax checks to `tests/dependency-policy/run-all.sh`
- [x] T013 [US1] Create least-privilege unfiltered pull-request-to-main, main-push, and manual required jobs with stable names, concurrency cancellation, 15-minute timeouts, four hosted platform environments, pinned chezmoi setup, and one asset/quality job in `.github/workflows/dependency-policy.yml`
- [x] T014 [US1] Run T003-T006 after implementation and correct all runner, release-asset, and workflow contract failures in `tests/dependency-policy/run-all.ps1`, `tests/dependency-policy/run-all.sh`, `tests/dependency-policy/Test-ReleaseAssets.ps1`, and `.github/workflows/dependency-policy.yml`
- [x] T015 [US1] Execute both aggregate entrypoints against the clean repository and a disposable stale-version mutation, then record green and failure evidence in `tests/dependency-policy/README.md`

**Checkpoint**: User Story 1 is independently usable as the MVP. Local commands and required hosted
checks execute the same repository-owned suites and reject an incomplete policy change.

---

## Phase 4: User Story 2 - Make Release Readiness Auditable (Priority: P2)

**Goal**: Maintainers can tell required static/contract evidence from deferred real installation
coverage and configure merge protection without ambiguous check names.

**Independent Test**: Review a completed workflow run and repository documentation, identify all five
required check names, reproduce each suite locally, and list every real-install target still deferred.

### Implementation for User Story 2

- [x] T016 [P] [US2] Add assertions that the workflow and documentation use the five stable required-check names and never label static checks as clean-install evidence in `tests/dependency-policy/Test-CIWorkflow.ps1`
- [x] T017 [P] [US2] Document local commands, required triggers/check names, branch-protection setup, evidence classes, failure interpretation, secretless fork safety, and the out-of-scope smoke-test matrix in `README.md`
- [x] T018 [US2] Update `tests/dependency-policy/README.md` with the automated evidence boundary and ensure every unexecuted DNF, apk, arm64, Windows workstation, and macOS workstation install remains explicitly deferred
- [x] T019 [US2] Run the workflow contract and both aggregate entrypoints after documentation changes and record the exact static, contract, existing manual, and deferred release-readiness result in `tests/dependency-policy/README.md`

**Checkpoint**: User Story 2 independently exposes what a green pull request proves and what still
requires later installation evidence.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Complete repository quality, security, and handoff gates.

- [x] T020 [P] Review all added workflow permissions, events, commands, and network calls for untrusted-fork safety using `specs/003-dependency-policy-ci/contracts/workflow-checks.md`
- [x] T021 [P] Review all added comments, diagnostics, documentation, and changed lines for English-only content using `.specify/memory/constitution.md`
- [x] T022 Run every command and mutation scenario in `specs/003-dependency-policy-ci/quickstart.md` that is available locally and record hosted-runner-only steps as pending pull-request evidence
- [x] T023 Validate workflow YAML, PowerShell parsing, POSIX shell syntax, chezmoi managed targets, `git diff --check`, task completion, and the constitution gates across `.github/workflows/dependency-policy.yml`, `tests/dependency-policy/`, and `specs/003-dependency-policy-ci/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup**: Starts immediately.
- **Foundational**: Depends on Setup and blocks both user stories.
- **User Story 1**: Depends on Foundational and supplies the required CI MVP.
- **User Story 2**: Depends on the workflow and entrypoints from User Story 1.
- **Polish**: Depends on both implemented user stories.

### User Story Dependency Graph

```text
Setup -> Foundation -> US1 (required CI) -> US2 (auditable readiness) -> Polish
```

### Within Each User Story

1. Run contract tests and observe the expected failure before implementation.
2. Implement repository entrypoints before workflow orchestration.
3. Verify failure propagation before accepting green-path results.
4. Update documentation only after check names and evidence classes stabilize.

## Parallel Opportunities

- T001 and T002 change separate files.
- T003-T006 create independent contract/fixture files.
- T008 and T009 implement separate shell-family entrypoints.
- T011 and T012 add separate shell-family quality checks.
- T016-T018 change separate test and documentation files.
- T020 and T021 are independent security and language reviews.

## Parallel Examples

### User Story 1

```text
Task T008: PowerShell aggregate entrypoint
Task T009: POSIX aggregate entrypoint

After both entrypoints exist:
Task T011: PowerShell quality gates
Task T012: POSIX quality gates
```

### User Story 2

```text
Task T016: evidence-name contract assertions
Task T017: maintainer README documentation
Task T018: test evidence boundary documentation
```

## Implementation Strategy

### MVP First

1. Complete Setup and Foundational contract tests.
2. Implement T008-T015 for User Story 1.
3. Open a draft pull request and verify the five hosted required checks.
4. Stop at the US1 checkpoint if branch protection is the immediate goal.

### Incremental Delivery

1. **Foundation**: failing runner, asset, and workflow contracts.
2. **US1**: shared local entrypoints plus required hosted CI.
3. **US2**: explicit evidence classes, required check names, and merge-protection instructions.
4. **Polish**: security, language, syntax, managed-target, and constitution verification.
5. **Future feature**: clean installation smoke tests on disposable server/workstation targets.

## Notes

- `[P]` never authorizes simultaneous edits to the same file.
- Runner tests use disposable fixture copies and must never call production `chezmoi apply`.
- Public release metadata checks must not depend on secrets.
- A green required workflow proves static and contract validation, not real installation.
- Commit after each logical phase and stop if a sequential contract test fails.
