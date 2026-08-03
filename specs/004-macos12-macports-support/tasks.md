# Tasks: macOS 12 MacPorts Support

**Input**: Design documents from `/specs/004-macos12-macports-support/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Tests are included because the specification requires fixture coverage, static checks, and real Mac mini validation evidence.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Repository-root dotfiles project with chezmoi templates, shell templates, Markdown documentation, and dependency-policy tests.
- Runtime entrypoints live at repository root and `.chezmoitemplates/`.
- Policy fixtures and evidence live under `tests/dependency-policy/`.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Inspect the current macOS dependency implementation and prepare the shared test/documentation surfaces.

- [ ] T001 Inspect current macOS dependency flow in `run_onchange_before_10-install-packages-darwin.sh.tmpl`
- [ ] T002 Inspect shared POSIX reconciliation behavior in `.chezmoitemplates/dependency-policy-posix.sh.tmpl`
- [ ] T003 Inspect existing shell PATH behavior in `.chezmoitemplates/nushell-config.nu`
- [ ] T004 [P] Inspect current dependency manifest target declarations in `.chezmoidata/dependencies.yaml`
- [ ] T005 [P] Inspect existing macOS fixture contract in `tests/dependency-policy/test-darwin-dependency-install.sh`
- [ ] T006 [P] Inspect current macOS evidence notes in `tests/dependency-policy/evidence/macos.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add shared target-selection, source-selection, and prerequisite semantics that all user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T007 Define macOS major-version detection and Monterey classification in `run_onchange_before_10-install-packages-darwin.sh.tmpl`
- [ ] T008 Define Monterey package-family selection and newer-macOS preservation in `run_onchange_before_10-install-packages-darwin.sh.tmpl`
- [ ] T009 Add MacPorts prerequisite detection helpers for `port` presence, path, and version in `run_onchange_before_10-install-packages-darwin.sh.tmpl`
- [ ] T010 Extend selected-target diagnostics with macOS release category and package-management path in `run_onchange_before_10-install-packages-darwin.sh.tmpl`
- [ ] T011 Extend native-package preflight to recognize MacPorts package declarations without affecting existing apk behavior in `.chezmoitemplates/dependency-policy-posix.sh.tmpl`
- [ ] T012 Extend native-package installation dispatch for MacPorts declarations without affecting existing apk behavior in `.chezmoitemplates/dependency-policy-posix.sh.tmpl`
- [ ] T013 Add MacPorts source classification for active executable paths under `/opt/local` in `.chezmoitemplates/dependency-policy-posix.sh.tmpl`
- [ ] T014 Add duplicate-safe MacPorts candidate paths `/opt/local/bin` and `/opt/local/sbin` in `.chezmoitemplates/nushell-config.nu`
- [ ] T015 Update dependency-policy fixture vocabulary for Monterey, MacPorts, and prerequisite-blocked states in `tests/dependency-policy/test-darwin-dependency-install.sh`

**Checkpoint**: Monterey target selection, MacPorts prerequisites, and shared source vocabulary are ready for story implementation.

---

## Phase 3: User Story 1 - Bootstrap a Monterey Mac mini (Priority: P1) 🎯 MVP

**Goal**: A macOS 12 Monterey Mac mini can use the documented dependency setup path and either reach compatibility or stop before mutation with a clear MacPorts prerequisite diagnostic.

**Independent Test**: Run the Monterey workstation fixture and the real-machine prerequisite/compatible-path commands from `specs/004-macos12-macports-support/quickstart.md`.

### Tests for User Story 1

- [ ] T016 [P] [US1] Add macOS 12 Intel workstation target-selection fixture in `tests/dependency-policy/test-darwin-dependency-install.sh`
- [ ] T017 [P] [US1] Add macOS 12 Apple Silicon workstation target-selection fixture in `tests/dependency-policy/test-darwin-dependency-install.sh`
- [ ] T018 [P] [US1] Add missing-MacPorts prerequisite-blocked fixture in `tests/dependency-policy/test-darwin-dependency-install.sh`
- [ ] T019 [P] [US1] Add MacPorts-not-on-PATH prerequisite diagnostic fixture in `tests/dependency-policy/test-darwin-dependency-install.sh`

### Implementation for User Story 1

- [ ] T020 [US1] Implement Monterey target key and package-family assignment in `run_onchange_before_10-install-packages-darwin.sh.tmpl`
- [ ] T021 [US1] Implement MacPorts prerequisite-blocked behavior before dependency preflight in `run_onchange_before_10-install-packages-darwin.sh.tmpl`
- [ ] T022 [US1] Implement Monterey official-artifact source preservation for compatible declared artifacts in `.chezmoitemplates/dependency-policy-posix.sh.tmpl`
- [ ] T023 [US1] Implement MacPorts native-package availability checks for exact declared packages in `.chezmoitemplates/dependency-policy-posix.sh.tmpl`
- [ ] T024 [US1] Update Monterey setup and prerequisite documentation in `README.md`
- [ ] T025 [US1] Record Monterey prerequisite and compatible-path validation instructions in `tests/dependency-policy/evidence/macos.md`
- [ ] T026 [US1] Run and record the User Story 1 fixture result in `tests/dependency-policy/README.md`

**Checkpoint**: User Story 1 is fully functional and testable independently as the MVP.

---

## Phase 4: User Story 2 - Preserve modern macOS behavior (Priority: P2)

**Goal**: Existing newer macOS x86_64 and arm64 behavior remains unchanged while Monterey uses its legacy path.

**Independent Test**: Run newer macOS fixture scenarios and confirm they do not enter Monterey-specific target selection or MacPorts prerequisite checks.

### Tests for User Story 2

- [ ] T027 [P] [US2] Add newer macOS x86_64 regression fixture in `tests/dependency-policy/test-darwin-dependency-install.sh`
- [ ] T028 [P] [US2] Add newer macOS arm64 regression fixture in `tests/dependency-policy/test-darwin-dependency-install.sh`
- [ ] T029 [P] [US2] Add dependency-management-disabled macOS fixture that exits before package-manager checks in `tests/dependency-policy/test-darwin-dependency-install.sh`

### Implementation for User Story 2

- [ ] T030 [US2] Guard Monterey-only logic so newer macOS keeps the existing target path in `run_onchange_before_10-install-packages-darwin.sh.tmpl`
- [ ] T031 [US2] Preserve existing macOS role filtering and official-artifact behavior in `.chezmoitemplates/dependency-policy-posix.sh.tmpl`
- [ ] T032 [US2] Update README compatibility wording for Monterey versus newer macOS behavior in `README.md`
- [ ] T033 [US2] Run and record newer macOS regression fixture results in `tests/dependency-policy/README.md`

**Checkpoint**: User Stories 1 and 2 both work independently without changing newer macOS behavior.

---

## Phase 5: User Story 3 - Diagnose mixed package-manager environments (Priority: P3)

**Goal**: Monterey users with Homebrew, MacPorts, and manual binaries receive active-path diagnostics without automatic removal of user-owned installations.

**Independent Test**: Run mixed-manager fixtures and confirm diagnostics include active path, selected package-management path, expected version/source, and safe next action.

### Tests for User Story 3

- [ ] T034 [P] [US3] Add Homebrew-plus-MacPorts active-path conflict fixture in `tests/dependency-policy/test-darwin-dependency-install.sh`
- [ ] T035 [P] [US3] Add manual-binary duplicate active-path fixture in `tests/dependency-policy/test-darwin-dependency-install.sh`
- [ ] T036 [P] [US3] Add macOS 12 server-role fixture that excludes WezTerm and JetBrainsMono Nerd Font in `tests/dependency-policy/test-darwin-dependency-install.sh`

### Implementation for User Story 3

- [ ] T037 [US3] Implement Homebrew, MacPorts, managed-user-local, manual, absent, and unknown active-source classification in `.chezmoitemplates/dependency-policy-posix.sh.tmpl`
- [ ] T038 [US3] Extend blocked diagnostics with active path and selected package-management path in `.chezmoitemplates/dependency-policy-posix.sh.tmpl`
- [ ] T039 [US3] Ensure competing Homebrew and manual installations are reported but never removed in `.chezmoitemplates/dependency-policy-posix.sh.tmpl`
- [ ] T040 [US3] Update troubleshooting guidance for mixed Homebrew, MacPorts, and manual installations in `README.md`
- [ ] T041 [US3] Record mixed-manager and server-role fixture results in `tests/dependency-policy/README.md`

**Checkpoint**: All user stories are independently functional and mixed-manager diagnostics are safe.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verify the full feature, update evidence boundaries, and prepare implementation for review.

- [ ] T042 [P] Run `sh tests/dependency-policy/test-darwin-dependency-install.sh` and record results in `tests/dependency-policy/README.md`
- [ ] T043 [P] Run `sh tests/dependency-policy/test-posix-reconciliation.sh` and record results in `tests/dependency-policy/README.md`
- [ ] T044 Run `sh tests/dependency-policy/test-dependency-manifest.sh` with `CHEZMOI` configured and record results in `tests/dependency-policy/README.md`
- [ ] T045 Run PowerShell dependency-policy validators and record results in `tests/dependency-policy/README.md`
- [ ] T046 Verify no unresolved placeholders or clarification markers remain in `specs/004-macos12-macports-support/`
- [ ] T047 Update real Mac mini verified or deferred evidence status in `tests/dependency-policy/evidence/macos.md`
- [ ] T048 Review implementation against constitution gates and record any deferred platform validation in `tests/dependency-policy/README.md`
- [ ] T049 Update `specs/004-macos12-macports-support/quickstart.md` if implemented commands differ from the planned validation flow

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion; blocks all user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational completion; MVP scope.
- **User Story 2 (Phase 4)**: Depends on Foundational completion; can run after or alongside US1 if file conflicts are coordinated.
- **User Story 3 (Phase 5)**: Depends on Foundational completion; can run after or alongside US1/US2 if file conflicts are coordinated.
- **Polish (Phase 6)**: Depends on all desired user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational; no dependency on US2 or US3.
- **User Story 2 (P2)**: Can start after Foundational; validates newer macOS non-regression independently.
- **User Story 3 (P3)**: Can start after Foundational; depends on shared active-source vocabulary but not on US2.

### Within Each User Story

- Fixture tasks should be added before implementation tasks where possible.
- Target selection precedes source selection.
- Prerequisite checks precede dependency preflight.
- Diagnostics are completed before evidence/documentation is marked verified.
- Story checkpoint must pass before claiming that story as complete.

### Parallel Opportunities

- T004, T005, and T006 can run in parallel during Setup.
- T016, T017, T018, and T019 can run in parallel after Foundational tasks complete.
- T027, T028, and T029 can run in parallel after Foundational tasks complete.
- T034, T035, and T036 can run in parallel after Foundational tasks complete.
- T042 and T043 can run in parallel during Polish.

---

## Parallel Example: User Story 1

```bash
Task: "T016 [US1] Add macOS 12 Intel workstation target-selection fixture in tests/dependency-policy/test-darwin-dependency-install.sh"
Task: "T017 [US1] Add macOS 12 Apple Silicon workstation target-selection fixture in tests/dependency-policy/test-darwin-dependency-install.sh"
Task: "T018 [US1] Add missing-MacPorts prerequisite-blocked fixture in tests/dependency-policy/test-darwin-dependency-install.sh"
Task: "T019 [US1] Add MacPorts-not-on-PATH prerequisite diagnostic fixture in tests/dependency-policy/test-darwin-dependency-install.sh"
```

## Parallel Example: User Story 2

```bash
Task: "T027 [US2] Add newer macOS x86_64 regression fixture in tests/dependency-policy/test-darwin-dependency-install.sh"
Task: "T028 [US2] Add newer macOS arm64 regression fixture in tests/dependency-policy/test-darwin-dependency-install.sh"
Task: "T029 [US2] Add dependency-management-disabled macOS fixture that exits before package-manager checks in tests/dependency-policy/test-darwin-dependency-install.sh"
```

## Parallel Example: User Story 3

```bash
Task: "T034 [US3] Add Homebrew-plus-MacPorts active-path conflict fixture in tests/dependency-policy/test-darwin-dependency-install.sh"
Task: "T035 [US3] Add manual-binary duplicate active-path fixture in tests/dependency-policy/test-darwin-dependency-install.sh"
Task: "T036 [US3] Add macOS 12 server-role fixture that excludes WezTerm and JetBrainsMono Nerd Font in tests/dependency-policy/test-darwin-dependency-install.sh"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: User Story 1.
4. Stop and validate Monterey workstation bootstrap independently.
5. Record real Mac mini validation or explicit deferral before claiming Monterey support.

### Incremental Delivery

1. Complete Setup + Foundational so target selection and source semantics are stable.
2. Add User Story 1 and validate Monterey MVP behavior.
3. Add User Story 2 and validate newer macOS behavior has not regressed.
4. Add User Story 3 and validate mixed-manager diagnostics.
5. Complete Polish checks and update evidence.

### Parallel Team Strategy

With multiple contributors:

1. Complete Setup + Foundational together.
2. After Foundational completion, one contributor can implement US1 fixtures/behavior, another can implement US2 regression fixtures/docs, and another can implement US3 mixed-manager diagnostics.
3. Coordinate shared-file edits in `run_onchange_before_10-install-packages-darwin.sh.tmpl`, `.chezmoitemplates/dependency-policy-posix.sh.tmpl`, `README.md`, and `tests/dependency-policy/test-darwin-dependency-install.sh` to avoid conflicting changes.

---

## Notes

- Every task uses the required checkbox, sequential task ID, optional `[P]`, story label where applicable, and exact file path.
- `[P]` tasks are limited to tasks that can be prepared independently, though edits to the same fixture file should still be merged carefully.
- User Story 1 is the recommended MVP because it makes the Monterey Mac mini path usable or safely blocked.
- Real Mac mini validation must be recorded as verified or deferred; fixture-only validation must not be described as full real-platform validation.
