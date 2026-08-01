# Feature Specification: Align Dependency Versions

**Feature Branch**: `feat/align-dependency-versions`

**Created**: 2026-08-01

**Status**: Draft

**Input**: User description: "Make the managed terminal dependencies version-consistent across
Windows, macOS, and supported Linux distributions before adding the MacPorts fallback."

## Clarifications

### Session 2026-08-01

- Q: Should the choice to retain a newer incompatible version be remembered? -> A: Remember it per
  dependency and declared version; ask again when the declared version changes.
- Q: Must setup verify that every required declared version is available before changing any installed
  dependency? -> A: Yes; complete a full role-applicable preflight and make no changes if any item is
  unavailable.
- Q: What should happen when execution fails after some dependency changes succeed? -> A: Stop
  immediately without automatic rollback, report the partial state, and provide manual removal or
  rollback guidance for each changed dependency so the next apply can resume safely.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reproduce the Same Toolchain Everywhere (Priority: P1)

As a user who applies the dotfiles on multiple supported platforms, I receive a declared compatible
version of every managed terminal dependency so the shared configuration behaves consistently.

**Why this priority**: The repository promises one familiar environment across platforms; unmanaged
version drift directly breaks that promise and has already caused configuration and terminal
regressions.

**Independent Test**: Bootstrap representative Windows, macOS, and Linux profiles, record all managed
dependency versions, and verify that every version matches the repository's declared compatibility
manifest or an explicitly declared platform exception.

**Acceptance Scenarios**:

1. **Given** clean supported Windows, macOS, and Linux machines with the same machine role, **When**
   automatic dependency setup completes, **Then** every managed dependency reports the version
   declared for that release of the dotfiles.
2. **Given** a workstation profile, **When** setup completes, **Then** GUI terminal and font versions
   are included in the version report alongside the shared CLI tools.
3. **Given** a headless profile, **When** setup completes, **Then** only role-applicable CLI
   dependencies are required and workstation-only dependencies remain absent.
4. **Given** the same configuration is applied again without a declared version change, **When** setup
   completes, **Then** no managed dependency is upgraded, downgraded, or reinstalled.
5. **Given** any role-applicable declared version or platform artifact is unavailable, **When**
   preflight runs, **Then** setup reports every unavailable item and changes no managed dependency.
6. **Given** preflight succeeded but a runtime failure occurs after one or more dependency changes,
   **When** setup stops, **Then** it preserves completed changes, identifies changed and pending
   dependencies, provides manual removal or rollback guidance for each changed item, and explains that
   the next apply resumes from observed state.

---

### User Story 2 - Reconcile an Existing Machine Safely (Priority: P2)

As a user with existing dependency versions, I can apply the dotfiles and have incompatible managed
versions reconciled predictably without changing unrelated software or user configuration.

**Why this priority**: Most users apply updates to an existing environment rather than only to clean
machines, and silent drift must not persist indefinitely.

**Independent Test**: Prepare machines with older, newer, missing, and matching versions of each
managed dependency, apply the configuration, and verify the declared reconciliation behavior plus
preservation of unrelated packages and configuration.

**Acceptance Scenarios**:

1. **Given** an older incompatible managed dependency, **When** setup runs, **Then** it is replaced by
   the declared compatible version and the change is reported.
2. **Given** a newer incompatible managed dependency, **When** setup runs interactively, **Then** the
   user is warned and can downgrade to the declared version, retain the newer version with an
   unsupported-environment result, or cancel dependency setup without changing it.
3. **Given** a newer incompatible managed dependency in a non-interactive run, **When** setup cannot
   obtain a choice, **Then** it stops without downgrading and explains how to rerun interactively.
4. **Given** the user previously chose to retain a newer incompatible version for the current declared
   version, **When** setup runs again, **Then** that choice is reused without prompting.
5. **Given** the repository changes the declared version after a retain choice was recorded, **When**
   setup runs, **Then** the prior choice is invalidated and the user is asked again.
6. **Given** a dependency already at the declared version, **When** setup runs, **Then** it is left
   untouched.
7. **Given** unrelated software or user-owned configuration, **When** managed dependencies are
   reconciled, **Then** those unrelated resources are not removed, migrated, or overwritten.

---

### User Story 3 - Upgrade the Stack Deliberately (Priority: P3)

As a maintainer, I can update dependency versions through one reviewable declaration and understand
which platforms and configurations must be validated before the new set is released.

**Why this priority**: Version alignment is sustainable only if future upgrades are deliberate,
auditable, and do not require hunting through unrelated platform scripts.

**Independent Test**: Change one declared dependency version in a review branch and verify that all
affected installation paths, compatibility checks, documentation, and platform-validation
requirements identify the change consistently.

**Acceptance Scenarios**:

1. **Given** a maintainer proposes a dependency update, **When** the version declaration changes,
   **Then** every platform installation path resolves the same declared version or an explicit
   platform exception.
2. **Given** a proposed version is unavailable on one supported platform, **When** validation runs,
   **Then** release readiness is blocked with the dependency, platform, architecture, and unavailable
   version identified.
3. **Given** a platform exception is necessary, **When** it is declared, **Then** its reason,
   compatibility range, validation evidence, and removal condition are documented.

### Edge Cases

- A package manager reports success but the executable on `PATH` resolves to a different installation.
- Multiple installations of the same dependency exist under different package managers or prefixes.
- A tool emits a decorated or non-semantic version string that cannot be compared directly.
- An exact declared version has been removed from a package repository or upstream release page.
- A declared artifact exists for one CPU architecture but not another.
- A workstation font is installed but the terminal cannot discover its expected family name.
- A dependency is in use and cannot be replaced until a terminal or multiplexer session exits.
- Network or package-index failure occurs after some, but not all, dependencies are reconciled.
- A manual removal command is unavailable or would also remove unrelated dependencies; the diagnostic
  must use a documentation reference or explain the limitation instead of suggesting an unsafe command.
- A user disables automatic dependency management while retaining the shared configuration.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The project MUST maintain one authoritative compatibility declaration for every managed
  runtime dependency: Nushell, Zellij, Helix, Starship, zoxide, fzf, WezTerm, and JetBrainsMono Nerd
  Font.
- **FR-002**: The compatibility declaration MUST record the expected version, applicable machine
  roles, supported platforms and architectures, and any approved platform exception for each managed
  dependency.
- **FR-003**: The project MUST require exact version equality for all eight managed runtime
  dependencies on every applicable platform target unless an explicit platform exception is
  approved.
- **FR-004**: Every automatic installation path MUST resolve versions from the authoritative
  declaration rather than maintaining independent unconnected version values.
- **FR-005**: After setup, the executable or installed asset actually selected by the user's
  environment MUST be verified, not merely the package-manager transaction result.
- **FR-018**: Before changing any managed dependency, setup MUST verify availability of every declared
  version and platform asset applicable to the current platform, architecture, and machine role. If
  any item is unavailable, setup MUST report all unavailable items and make no dependency changes.
- **FR-019**: If execution fails after one or more dependency changes, setup MUST stop immediately,
  MUST NOT automatically roll back successful changes, and MUST report the changed, pending, and
  failed dependencies. The report MUST include a safe manual removal or rollback command or
  documentation reference for every dependency changed during that run and MUST explain that a later
  apply resumes from observed state.
- **FR-006**: Missing and older incompatible managed dependencies MUST be installed or replaced with
  the declared compatible version when automatic dependency management is enabled.
- **FR-007**: When a newer incompatible managed dependency is detected interactively, setup MUST warn
  the user and offer three choices: downgrade to the declared version, retain it with an explicitly
  unsupported-environment result, or cancel dependency setup without changing it. A retain choice
  MUST be stored per dependency and declared version, reused on unchanged applies, and invalidated
  when that dependency's declared version changes.
- **FR-008**: In a non-interactive run, a newer incompatible managed dependency MUST stop setup without
  an automatic downgrade and MUST explain how to rerun interactively.
- **FR-009**: Reconciliation MUST NOT remove or migrate unrelated packages, package managers, or
  user-owned configuration.
- **FR-010**: Matching dependencies MUST be left unchanged, and a second unchanged apply MUST perform
  no managed dependency replacements.
- **FR-011**: If the declared version is unavailable for a supported platform or architecture, setup
  MUST fail with an actionable English diagnostic and MUST NOT silently substitute another version.
- **FR-012**: The project MUST identify the dependency, expected version, observed version or absence,
  platform, architecture, and next action whenever version reconciliation is blocked.
- **FR-013**: Workstation-only dependencies MUST be excluded from headless/server reconciliation and
  verification.
- **FR-014**: A dependency version update MUST include compatibility review and verification evidence
  for every affected supported platform, architecture, and machine role before it is represented as
  cross-platform compatible.
- **FR-015**: Approved platform exceptions MUST state their rationale, exact affected scope,
  compatible version or range, verification evidence, and objective removal condition.
- **FR-016**: User and maintainer documentation MUST expose the declared dependency set, version policy,
  exceptions, update procedure, and commands for verifying the active environment.
- **FR-017**: The version-alignment feature MUST NOT add MacPorts, expand the supported operating-system
  matrix, or begin managing currently optional external tools such as Git, SSH clients, PowerShell,
  or fallback CJK fonts.

### Key Entities

- **Managed Dependency**: A tool or asset intentionally installed by this repository, with a canonical
  name, expected version, role applicability, and verification identity.
- **Platform Target**: A supported operating-system family, release category, CPU architecture, and
  machine role against which a dependency is resolved and validated.
- **Compatibility Declaration**: The authoritative set of managed dependency versions and approved
  exceptions for a dotfiles release.
- **Observed Installation**: The executable or asset actually active after setup, including its path,
  reported version, source, and compatibility result.
- **Platform Exception**: A temporary, documented divergence from the normal version policy with a
  bounded scope and removal condition.
- **Reconciliation Result**: The outcome for a dependency: already compatible, installed, upgraded,
  downgraded, skipped by role, or blocked with a reason.
- **Retain Override**: A machine-local choice to keep a newer incompatible dependency, keyed by the
  dependency identity and the declared version that was rejected; it expires when that declaration
  changes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The authoritative declaration accounts for 100% of the eight managed runtime
  dependencies and every supported platform and machine role applicable to each one.
- **SC-002**: On every validated platform target, 100% of active managed dependencies match the
  declared policy after a successful automatic setup.
- **SC-003**: A second unchanged apply performs zero dependency upgrades, downgrades, removals, or
  reinstalls.
- **SC-004**: Tests covering missing, older, newer, matching, unavailable, duplicate-path, and
  wrong-architecture cases produce the documented reconciliation result for every managed dependency
  category.
- **SC-005**: Every blocked reconciliation identifies all five diagnostic elements: dependency,
  expected version, observed state, platform target, and next action.
- **SC-006**: A maintainer can identify and update the authoritative version of any managed dependency
  in one location, and all affected platform paths consume that declaration without independent
  manual version edits.
- **SC-007**: Version-alignment validation produces zero changes to unrelated packages, package
  managers, user-owned configuration, Windows/Linux support scope, or the existing macOS package
  manager.

## Assumptions

- The managed dependency set is limited to the eight tools and assets already installed by the
  project; chezmoi, operating-system package managers, system shells, Git, SSH clients, PowerShell,
  and fallback fonts remain prerequisites or optional external tools.
- NuShell 0.114.1 and Zellij 0.44.1 are the initial known compatibility anchors until the planning
  phase validates a complete declared version set.
- A tool version is not considered compatible merely because its installation command succeeded; the
  active executable or discoverable asset is the acceptance source.
- Exact package availability and artifact integrity mechanisms are planning decisions, not reasons to
  weaken the declared compatibility outcome.
- Availability preflight covers only dependencies applicable to the current platform, architecture,
  and machine role; workstation-only dependencies do not block a headless run.
- Retaining a newer incompatible version is an explicit user override and MUST NOT be reported as a
  compatible or fully successful dependency setup.
- Retain overrides are machine-local state and are not committed to shared repository configuration.
- Cancellation or a non-interactive newer-version conflict leaves the observed installation unchanged
  and does not continue with additional dependency mutations.
- Runtime failures after mutation are recoverable convergence points, not transactions: successful
  changes remain, and the next apply reassesses observed state before continuing.
- MacPorts selection and legacy macOS support remain deferred to `001-macports-fallback` and will
  consume the version policy produced by this feature after it is complete.
