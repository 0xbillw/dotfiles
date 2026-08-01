# Tasks: Align Dependency Versions

**Input**: Design documents from `/specs/002-align-dependency-versions/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: Verification tasks are included because the specification and constitution require
platform-specific evidence, idempotency checks, and explicit reconciliation scenarios. Test tasks in
each story must be written and observed failing before the corresponding implementation tasks.

**Organization**: Tasks are grouped by user story so each story can be implemented and verified as an
independent increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it changes different files and does not depend on incomplete work.
- **[Story]**: Maps the task to its specification user story.
- Every task names the exact file or directory it changes.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish test locations and artifact hygiene without changing installation behavior.

- [ ] T001 Add generated dependency-test staging and fixture-state paths to `.gitignore`
- [ ] T002 [P] Create cross-platform test fixture conventions and required environment variables in `tests/dependency-policy/README.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Define the shared compatibility policy and validation infrastructure consumed by all
three platform installers.

**CRITICAL**: No user story implementation begins until this phase is complete.

- [ ] T003 Create all eight exact dependency records, role applicability, install order, executable probes, font family/style plus target-specific installed-file hashes, target mappings, official artifact coordinates, SHA-256 values, and removal guidance in `.chezmoidata/dependencies.yaml`
- [ ] T004 Add representative workstation/server and OS/architecture/libc rendering inputs in `tests/dependency-policy/fixtures/targets.json`
- [ ] T005 [P] Add manifest schema, exact-version, target coverage, official-HTTPS, archive and installed-font-file checksum, role, and removal-guidance checks in `tests/dependency-policy/Test-DependencyManifest.ps1`
- [ ] T006 [P] Add POSIX manifest-render coverage and duplicate installer-version-literal detection in `tests/dependency-policy/test-dependency-manifest.sh`
- [ ] T007 Run T005 and T006 against `.chezmoidata/dependencies.yaml`, correct all policy-data failures there, and record supported target coverage in `tests/dependency-policy/README.md`

**Checkpoint**: One valid manifest accounts for every managed dependency and applicable target; all
later installer work reads from it.

---

## Phase 3: User Story 1 - Reproduce the Same Toolchain Everywhere (Priority: P1) MVP

**Goal**: A clean supported workstation or server installs the exact declared applicable toolchain,
verifies the active result, and changes nothing on a second apply.

**Independent Test**: Render and apply representative Windows, macOS, apt, dnf, and apk profiles;
verify every active applicable version against the manifest, verify server profiles omit WezTerm and
the font, deliberately make one payload unavailable and confirm zero mutation, then run an unchanged
second apply and confirm zero installation transactions.

### Tests for User Story 1

- [ ] T008 [P] [US1] Add Windows fixtures for missing, matching, unavailable, bad artifact/font hash, duplicate-PATH/font, unknown architecture/manager, disabled management, workstation/server, and second-apply cases in `tests/dependency-policy/Test-WindowsDependencyInstall.ps1`
- [ ] T009 [P] [US1] Add macOS fixtures for missing, matching, unavailable, bad artifact/font hash, duplicate-PATH/font, unknown architecture/manager, disabled management, workstation/server, and second apply in `tests/dependency-policy/test-darwin-dependency-install.sh`
- [ ] T010 [P] [US1] Add apt/dnf/apk and glibc/musl fixtures for missing, matching, unavailable, wrong/unknown target, bad artifact/font hash, duplicate-PATH/font, disabled management, workstation/server, and second apply in `tests/dependency-policy/test-linux-dependency-install.sh`
- [ ] T011 [US1] Run T008-T010 before implementation, confirm the new behavioral assertions fail, and document the baseline failures in `tests/dependency-policy/README.md`

### Implementation for User Story 1

- [ ] T012 [P] [US1] Render Windows dependency versions exclusively from `.chezmoidata/dependencies.yaml`, exit without network/state mutation when management is disabled, reject unknown targets, detect active executable/font files, stage all payloads, verify archive and installed-font hashes, install in manifest order, and verify active results in `run_onchange_before_10-install-packages.cmd.tmpl`
- [ ] T013 [P] [US1] Render macOS dependency versions exclusively from `.chezmoidata/dependencies.yaml`, exit without network/state mutation when management is disabled, reject unknown targets, detect active executable/font files, prefer exact Homebrew packages or official artifacts, stage all payloads, verify archive and installed-font hashes, install in manifest order, and verify active results in `run_onchange_before_10-install-packages-darwin.sh.tmpl`
- [ ] T014 [P] [US1] Render Linux dependency versions exclusively from `.chezmoidata/dependencies.yaml`, exit without network/state mutation when management is disabled, reject unknown apt/dnf/apk architecture/libc targets, detect active executable/font files, prefer exact native packages or official artifacts, stage all payloads, verify archive and installed-font hashes, install in manifest order, and verify active results in `run_onchange_before_10-install-packages-linux.sh.tmpl`
- [ ] T015 [US1] Make Windows preflight aggregate every unavailable or invalid applicable payload and exit before mutation with dependency, expected version, observed state, target, and next action in `run_onchange_before_10-install-packages.cmd.tmpl`
- [ ] T016 [US1] Make POSIX preflight aggregate every unavailable or invalid applicable payload and exit before mutation with dependency, expected version, observed state, target, and next action in `run_onchange_before_10-install-packages-darwin.sh.tmpl` and `run_onchange_before_10-install-packages-linux.sh.tmpl`
- [ ] T017 [P] [US1] Make Nushell integration generation consume and verify manifest-matching Starship and zoxide executables in `run_after_generate-nushell-integrations.cmd.tmpl`
- [ ] T018 [P] [US1] Make Nushell integration generation consume and verify manifest-matching Starship and zoxide executables in `run_after_generate-nushell-integrations.sh.tmpl`
- [ ] T019 [US1] Run T008-T010 after implementation and record actual versus deferred Windows/macOS/Linux target results in `tests/dependency-policy/README.md`

**Checkpoint**: User Story 1 is independently usable as the MVP on clean machines and repeat applies.

---

## Phase 4: User Story 2 - Reconcile an Existing Machine Safely (Priority: P2)

**Goal**: Existing missing, older, matching, and newer installations converge predictably without
touching unrelated software; newer versions require explicit consent and runtime partial failures are
recoverable.

**Independent Test**: On disposable fixtures, cover older replacement, matching no-op, all three
interactive newer-version choices, non-interactive blocking, retained-choice reuse and invalidation,
competing installation preservation, and a forced failure after one successful change with complete
changed/failed/pending and removal guidance.

### Tests for User Story 2

- [ ] T020 [P] [US2] Add Windows older/newer/matching decision, invalid-input retry, retain persistence/invalidation, retained Starship/zoxide integration generation, cancellation, non-interactive, unrelated-installation, and partial-failure cases in `tests/dependency-policy/Test-WindowsReconciliation.ps1`
- [ ] T021 [P] [US2] Add POSIX older/newer/matching decision, invalid-input retry, retain persistence/invalidation, retained Starship/zoxide integration generation, cancellation, non-interactive, unrelated-installation, and partial-failure cases in `tests/dependency-policy/test-posix-reconciliation.sh`
- [ ] T022 [US2] Run T020-T021 before implementation, confirm the new reconciliation assertions fail, and document the baseline failures in `tests/dependency-policy/README.md`

### Implementation for User Story 2

- [ ] T023 [P] [US2] Implement exact version comparison, explicit downgrade/keep-unsupported/cancel prompting, invalid-input retry, non-interactive blocking, and per-dependency declared-version retain records under `%LOCALAPPDATA%` in `run_onchange_before_10-install-packages.cmd.tmpl`
- [ ] T024 [P] [US2] Implement exact version comparison, explicit downgrade/keep-unsupported/cancel prompting, invalid-input retry, non-interactive blocking, and per-dependency declared-version retain records under `XDG_STATE_HOME` in `run_onchange_before_10-install-packages-darwin.sh.tmpl`
- [ ] T025 [P] [US2] Implement exact version comparison, explicit downgrade/keep-unsupported/cancel prompting, invalid-input retry, non-interactive blocking, and per-dependency declared-version retain records under `XDG_STATE_HOME` in `run_onchange_before_10-install-packages-linux.sh.tmpl`
- [ ] T026 [US2] Add Windows sequential run journaling and stop-on-failure output grouping changed, failed, and pending dependencies with safe removal commands or official references in `run_onchange_before_10-install-packages.cmd.tmpl`
- [ ] T027 [US2] Add POSIX sequential run journaling and stop-on-failure output grouping changed, failed, and pending dependencies with safe removal commands or official references in `run_onchange_before_10-install-packages-darwin.sh.tmpl` and `run_onchange_before_10-install-packages-linux.sh.tmpl`
- [ ] T028 [P] [US2] Make Nushell integration generation accept valid retained Starship/zoxide executables while preserving unsupported status in `run_after_generate-nushell-integrations.cmd.tmpl`
- [ ] T029 [P] [US2] Make Nushell integration generation accept valid retained Starship/zoxide executables while preserving unsupported status in `run_after_generate-nushell-integrations.sh.tmpl`
- [ ] T030 [US2] Run T020-T021 after implementation and record preservation, override, retained-integration, non-interactive, retry, and partial-failure results in `tests/dependency-policy/README.md`

**Checkpoint**: User Story 2 independently reconciles an existing machine and clearly represents
unsupported or partial states.

---

## Phase 5: User Story 3 - Upgrade the Stack Deliberately (Priority: P3)

**Goal**: A maintainer changes a version once and receives complete target, artifact, exception, and
verification feedback before release.

**Independent Test**: In a temporary working copy, change one manifest version, omit one target asset,
and confirm validation reports the dependency/version/platform/architecture; restore it, add a complete
temporary exception, and confirm every installer render consumes the new declaration without editing
platform-local version constants.

### Tests for User Story 3

- [ ] T031 [P] [US3] Add a mutation-based single-version update, missing-target, stale retain-key, and complete/incomplete exception validation harness in `tests/dependency-policy/Test-PolicyUpgrade.ps1`
- [ ] T032 [P] [US3] Add POSIX rendered-installer parity checks proving all platform templates consume one changed manifest version in `tests/dependency-policy/test-policy-upgrade.sh`
- [ ] T033 [US3] Run T031-T032 before implementation, confirm the update-governance assertions fail, and document the baseline failures in `tests/dependency-policy/README.md`

### Implementation for User Story 3

- [ ] T034 [US3] Extend `tests/dependency-policy/Test-DependencyManifest.ps1` and `tests/dependency-policy/test-dependency-manifest.sh` so a changed manifest version requires complete target artifacts and every exception requires rationale, exact scope, compatibility bound, evidence, and objective removal condition
- [ ] T035 [US3] Add the authoritative version table, source policy, exception format, upgrade workflow, and active-version commands to `README.md`
- [ ] T036 [US3] Run T031-T032 after implementation and record the successful single-declaration propagation and release-blocking failure diagnostics in `tests/dependency-policy/README.md`

**Checkpoint**: User Story 3 makes future compatibility updates reviewable and blocks incomplete
cross-platform claims.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Complete cross-platform quality gates and release evidence.

- [ ] T037 [P] Review all new script output, comments, identifiers, manifest text, tests, and `README.md` changes for English-only repository content
- [ ] T038 [P] Verify the implementation did not introduce MacPorts, new OS families, Git/SSH/PowerShell management, fallback CJK fonts, or automatic removal of competing installations using `specs/002-align-dependency-versions/spec.md`
- [ ] T039 Run every static and fixture command in `specs/002-align-dependency-versions/quickstart.md` and update expected commands or outcomes there if implementation details changed
- [ ] T040 [P] Execute Windows x86_64 workstation and server-profile commands and record machine identity, active versions/paths/font hashes, idempotency, and verified/deferred status in `tests/dependency-policy/evidence/windows-x86_64.md`
- [ ] T041 [P] Execute macOS x86_64/arm64 workstation and server commands where available and record machine identity, active versions/paths/font hashes, idempotency, and verified/deferred status in `tests/dependency-policy/evidence/macos.md`
- [ ] T042 [P] Execute apt-based glibc workstation and server commands and record machine identity, active versions/paths/font hashes, idempotency, and verified/deferred status in `tests/dependency-policy/evidence/apt-glibc.md`
- [ ] T043 [P] Execute dnf-based glibc and apk-based musl server commands and record machine identity, active versions/paths, idempotency, and verified/deferred status in `tests/dependency-policy/evidence/dnf-apk.md`
- [ ] T044 [P] Execute one supported Linux arm64 target and record machine identity, active versions/paths, idempotency, and every deferred arm64 target in `tests/dependency-policy/evidence/linux-arm64.md`
- [ ] T045 Consolidate T040-T044 and perform final idempotency, safe-path, user-state preservation, checksum, active-PATH/font, unsupported-target, disabled-management, and constitution review in `tests/dependency-policy/README.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Starts immediately.
- **Foundational (Phase 2)**: Depends on Phase 1 and blocks every user story.
- **User Story 1 (Phase 3)**: Depends on the foundation and supplies the MVP exact-install path.
- **User Story 2 (Phase 4)**: Depends on the foundation and integrates with the platform installers
  changed by US1; execute after US1 when one developer owns those files.
- **User Story 3 (Phase 5)**: Depends on the foundation; its validation harness can start alongside
  US1/US2, while final parity verification runs after their installer refactors.
- **Polish (Phase 6)**: Depends on every story selected for the release; T040-T044 may run in parallel
  on separate representative machines before T045 consolidates the release decision.

### User Story Dependency Graph

```text
Setup -> Foundation -> US1 (MVP) -> US2 -> Polish
                    `-> US3 -----------^
```

US3 test scaffolding is parallelizable after the foundation, but its final proof observes the US1/US2
installer consumers. US2 remains independently testable with prepared existing-machine fixtures even
though it builds on the same platform files.

### Within Each User Story

1. Write fixture tests and confirm they fail for the missing behavior.
2. Implement manifest consumers and platform behavior.
3. Run the story tests and record real versus deferred platform evidence.
4. Stop at the checkpoint and verify the story independently before continuing.

## Parallel Opportunities

- T002 can run while T001 is completed.
- T005 and T006 can run in parallel after T003-T004 define the data shape.
- T008-T010 cover different platform test files and can run in parallel.
- T012-T014 modify different platform installers and can run in parallel.
- T017-T018 modify different integration generators and can run in parallel.
- T020-T021 and T023-T025 divide work by platform and can run in parallel.
- T028-T029 modify different integration generators and can run in parallel.
- T031-T032 use different test runners and can run in parallel.
- T037-T038 are independent review passes.
- T040-T044 collect evidence on separate platform targets and can run in parallel.

## Parallel Examples

### User Story 1

```text
Task T008: Windows exact-install fixtures
Task T009: macOS exact-install fixtures
Task T010: Linux exact-install fixtures

After fixture failures are recorded:
Task T012: Windows manifest consumer
Task T013: macOS manifest consumer
Task T014: Linux manifest consumer
```

### User Story 2

```text
Task T020: Windows reconciliation fixtures
Task T021: POSIX reconciliation fixtures

After fixture failures are recorded:
Task T023: Windows decisions and retain state
Task T024: macOS decisions and retain state
Task T025: Linux decisions and retain state
```

### User Story 3

```text
Task T031: PowerShell manifest mutation validation
Task T032: POSIX rendered-installer parity validation
```

## Implementation Strategy

### MVP First: User Story 1

1. Complete Setup and Foundational phases.
2. Write and fail T008-T010.
3. Implement T012-T018.
4. Run T019 and stop for clean-machine, role, preflight, active-version, and second-apply validation.
5. Ship only after actual platform evidence is accurately scoped.

### Incremental Delivery

1. **Foundation**: one validated compatibility declaration.
2. **US1**: exact, role-aware clean installation with full preflight and active verification.
3. **US2**: safe existing-machine reconciliation and recoverable partial failures.
4. **US3**: deliberate maintainer upgrades and release-blocking compatibility validation.
5. **Polish**: cross-platform evidence and constitution review.

## Notes

- `[P]` never means two tasks may concurrently edit the same file.
- Tests use disposable fixture/staging paths and must not install onto the development host unless the
  task explicitly calls for a disposable real-machine test.
- Do not hard-code an independent managed version in an installer or test; fixtures receive expected
  versions from the manifest.
- Do not mark a platform verified from template rendering alone.
- Commit after each task or logical group and stop at any checkpoint for independent validation.
