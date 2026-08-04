# Feature Specification: macOS 12 MacPorts Support

**Feature Branch**: `004-macos12-macports-support`

**Created**: 2026-08-03

**Status**: Draft

**Input**: User description: "让我的 Mac mini running macOS 12 Monterey also use this terminal workspace; Homebrew is no longer a suitable supported package manager for that legacy macOS version, so use MacPorts where appropriate."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bootstrap a Monterey Mac mini (Priority: P1)

As a Mac mini owner running macOS 12 Monterey, I want dependency setup to recognize my system as a supported legacy macOS workstation and guide me through using a suitable package manager so I can install the shared terminal workspace without relying on unsupported Homebrew behavior.

**Why this priority**: The feature exists to make the user's actual Mac mini a first-class supported target instead of leaving it blocked by Homebrew's legacy macOS support boundary.

**Independent Test**: Can be fully tested by running the documented bootstrap and dependency setup flow on a macOS 12 Monterey Mac mini configured as a workstation and confirming it reaches a declared compatibility result with clear package-manager diagnostics.

**Acceptance Scenarios**:

1. **Given** a macOS 12 Monterey Mac mini workstation with dependency management enabled and the appropriate legacy macOS package manager available, **When** the user applies the dotfiles, **Then** setup installs or verifies every workstation-applicable managed dependency and reports the declared result for Monterey.
2. **Given** a macOS 12 Monterey Mac mini workstation without the required legacy package manager available, **When** dependency setup starts, **Then** setup stops before changing managed dependencies and tells the user which prerequisite is missing and what action to take next.
3. **Given** a macOS 12 Monterey Mac mini workstation where a managed dependency is already present at the declared compatible version, **When** setup runs again, **Then** setup leaves the dependency unchanged and reports it as compatible.

---

### User Story 2 - Preserve modern macOS behavior (Priority: P2)

As a user of newer macOS machines, I want the existing macOS setup behavior to remain stable so that adding Monterey support does not regress Apple Silicon or newer Intel macOS workstations.

**Why this priority**: Legacy macOS support must not destabilize already supported macOS targets or change their package source unexpectedly.

**Independent Test**: Can be tested by rendering or running the dependency setup flow for newer macOS x86_64 and arm64 workstation profiles and confirming they retain their declared package-source behavior and compatibility reporting.

**Acceptance Scenarios**:

1. **Given** a supported newer macOS workstation, **When** dependency setup runs, **Then** it continues using the declared package source for that newer macOS target and does not switch to the Monterey-specific path.
2. **Given** a newer macOS workstation with dependency management disabled, **When** setup runs, **Then** shared configuration remains managed while dependency installation remains skipped.

---

### User Story 3 - Diagnose mixed package-manager environments (Priority: P3)

As a user who may have Homebrew, MacPorts, and manually installed binaries on the same Mac, I want setup to identify which executable is active so I can fix PATH conflicts without accidental duplicate or shadowed installations.

**Why this priority**: Legacy macOS users often accumulate multiple package managers over time; the feature must keep setup explainable and safe.

**Independent Test**: Can be tested by preparing a Monterey environment with conflicting executable locations and confirming setup reports the active path, expected source, and safe next action without deleting unrelated user-managed software.

**Acceptance Scenarios**:

1. **Given** a Monterey Mac with multiple installations of the same managed tool, **When** setup verifies the active environment, **Then** it reports the active executable path and whether it matches the declared compatible dependency.
2. **Given** a conflicting user-managed installation outside the managed location, **When** setup detects it, **Then** setup provides guidance without removing or overwriting unrelated user-owned software.

---

### Edge Cases

- The machine reports macOS 12 Monterey but uses either Intel or Apple Silicon hardware.
- The required legacy package manager is installed but not discoverable on the user's active PATH.
- Homebrew and MacPorts are both installed, and the active executable comes from the non-selected package manager.
- A declared official artifact is unavailable, fails integrity verification, or is incompatible with macOS 12.
- A package-manager package exists but does not provide the declared compatible version.
- The user applies a server role on macOS 12; workstation-only GUI terminal and font dependencies must remain excluded.
- Dependency management is disabled; shared configuration must still render without attempting package-manager operations.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST recognize macOS 12 Monterey as an explicitly handled legacy macOS target for both Intel and Apple Silicon Mac mini hardware.
- **FR-002**: The system MUST select a package-management path for macOS 12 that does not depend on unsupported Homebrew behavior.
- **FR-003**: The system MUST document any manual prerequisite required before dependency setup can proceed on macOS 12 Monterey.
- **FR-004**: The system MUST stop before making dependency changes when the required Monterey prerequisite is absent, unavailable, or not discoverable.
- **FR-005**: The system MUST keep existing newer macOS behavior separate from the Monterey-specific path unless a user explicitly chooses otherwise.
- **FR-006**: The system MUST preserve the existing workstation/server role split on macOS 12, including excluding GUI terminals and fonts from server role setup.
- **FR-007**: The system MUST verify the active installed version or asset for every managed dependency applicable to macOS 12 before reporting compatibility.
- **FR-008**: The system MUST report actionable diagnostics that identify the dependency, expected version, observed version or absence, active path when available, selected package-management path, and next action whenever setup is blocked.
- **FR-009**: The system MUST avoid deleting or overwriting user-managed installations outside explicitly managed locations.
- **FR-010**: The system MUST remain idempotent: repeated successful setup on the same Monterey Mac mini MUST not reinstall compatible dependencies or duplicate PATH entries.
- **FR-011**: The system MUST not silently substitute a different dependency version when the declared compatible version is unavailable on Monterey.
- **FR-012**: The system MUST provide maintainer-facing verification evidence or manual test instructions for macOS 12 Monterey, covering both successful setup and blocked prerequisite scenarios.
- **FR-013**: The system MUST update user documentation so Monterey users know when to use the legacy macOS path and how it differs from newer macOS setup.
- **FR-014**: The system MUST retain English-only repository content for all committed documentation, script output, configuration comments, and test evidence.

### Key Entities

- **macOS Target**: A supported macOS operating-system version category, CPU architecture, and machine role used to decide dependency applicability and compatibility reporting.
- **Package Management Path**: The declared source family used for setup on a macOS target, including its prerequisite state and user-facing diagnostics.
- **Managed Dependency**: A tool or asset controlled by this repository's dependency policy, with declared version, role applicability, verification method, and source strategy.
- **Active Installation**: The executable or asset currently discovered by the user's environment and used as the acceptance source for compatibility checks.
- **Prerequisite Diagnostic**: A blocking message that explains what is missing or unsupported before dependency mutation begins.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A macOS 12 Monterey Mac mini user can reach either a compatible setup result or a prerequisite-blocked result with a specific next action in one documented apply attempt.
- **SC-002**: Re-running setup after a successful Monterey installation reports no required dependency changes for already compatible managed dependencies.
- **SC-003**: 100% of Monterey blocked-prerequisite cases identify the missing prerequisite and make no managed dependency changes.
- **SC-004**: 100% of managed dependencies applicable to Monterey report their expected version and observed compatibility state in setup output or recorded evidence.
- **SC-005**: Existing newer macOS workstation checks continue to report the same package-source category and role applicability as before the feature.
- **SC-006**: Documentation includes a Monterey-specific setup path, prerequisite list, troubleshooting guidance, and validation instructions before the feature is considered ready.

## Assumptions

- The primary user is a Mac mini owner running macOS 12 Monterey who wants the same terminal workspace experience as newer macOS, Windows, and Linux users.
- macOS 12 Monterey should be treated as a legacy macOS support path rather than as the default behavior for all macOS releases.
- A legacy macOS package manager is acceptable as a manual prerequisite when it is documented before commands that depend on it.
- Existing official prebuilt artifact usage remains acceptable on Monterey when the artifact is compatible, checksum-verifiable, and declared in the dependency policy.
- The feature focuses on this repository's managed terminal workspace dependencies and does not add management for unrelated system tools, secrets, or user-specific configuration.
