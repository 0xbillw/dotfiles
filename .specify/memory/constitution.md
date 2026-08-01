<!--
Sync Impact Report
- Version change: template (unratified) -> 1.0.0
- Modified principles: none; initial ratification
- Added principles:
  - I. Cross-Platform Consistency
  - II. One-Command, Repeatable Setup
  - III. Native Package Management First
  - IV. Pinned Critical Tool Versions
  - V. Workstation and Server Separation
  - VI. English Repository Content
  - VII. Platform-Specific Verification
- Added sections:
  - Platform and Dependency Constraints
  - Development Workflow and Quality Gates
- Removed sections: none; template placeholders were replaced
- Follow-up TODOs: none
-->
# Cross-Platform Terminal Workspace Constitution

## Core Principles

### I. Cross-Platform Consistency
Shared terminal behavior MUST remain functionally consistent across Windows, macOS, and supported
Linux distributions. Platform-specific implementations MAY differ where operating-system conventions
require it, but they MUST produce the same documented user-facing behavior unless a limitation is
explicitly recorded. A change for one platform MUST account for its effect on every other supported
platform.

Rationale: The repository exists to provide one familiar terminal workspace rather than independent,
diverging configurations for each operating system.

### II. One-Command, Repeatable Setup
A supported machine MUST be configurable through the documented bootstrap and `chezmoi` apply flow
with the fewest practical manual steps. Installation and configuration operations MUST be idempotent:
re-running them MUST preserve valid user state, avoid duplicate configuration, and converge on the
declared result. Any unavoidable manual prerequisite MUST be documented before the command that
depends on it.

Rationale: A fresh installation, rebuild, or additional machine must be predictable and inexpensive.

### III. Native Package Management First
Dependency installation MUST prefer the platform's native or established package manager: `winget`
on Windows, an appropriate supported manager on macOS, and the distribution's native manager on
Linux. Official prebuilt binaries MAY be used when the native repository lacks a required or
compatible version. Source compilation and third-party repositories require an explicit rationale,
including maintenance, security, disk-space, and compatibility trade-offs.

Rationale: Native package management reduces unnecessary dependencies and follows platform
administration conventions.

### IV. Pinned Critical Tool Versions
Tools whose configuration formats or runtime behavior affect the shared workspace MUST use explicit,
compatible versions across platforms. Version updates MUST be deliberate changes with release-note
review and platform verification. Installers MUST NOT silently substitute an incompatible version;
when an exact version is unavailable, they MUST fail clearly or use a documented compatible fallback.

Rationale: Version drift has previously caused configuration failures and inconsistent behavior.

### V. Workstation and Server Separation
The configuration model MUST distinguish graphical workstations from remote or headless servers.
Workstation-only dependencies, including GUI terminals and local display fonts, MUST NOT be installed
or configured on headless systems. Shared CLI tools and shell behavior MUST remain available in both
roles, subject to documented terminal-client compatibility constraints.

Rationale: Remote servers need a lightweight, reliable environment without irrelevant GUI artifacts.

### VI. English Repository Content
All committed code comments, configuration comments, identifiers, user-facing script output, and
maintainer documentation MUST be written in English. External product names and commands retain their
canonical spelling. Contributions MUST update existing nearby text to remain internally consistent.

Rationale: English repository content keeps the public project accessible to a broad contributor and
user community.

### VII. Platform-Specific Verification
Every behavioral change MUST define and perform verification appropriate to each affected platform
and machine role. Automated checks are preferred; where real-platform testing is unavailable, the
change MUST include static validation plus explicit manual test instructions, and the untested scope
MUST be disclosed before merge. A fix validated on only one operating system MUST NOT be represented
as cross-platform validation.

Rationale: Template rendering and package availability differ enough that success on one platform is
not evidence of success on another.

## Platform and Dependency Constraints

- Supported platform families and versions MUST be explicit in the README or feature specification.
- Platform detection MUST use stable operating-system or package-manager signals and MUST fail with an
  actionable message rather than guessing on unsupported systems.
- Shared configuration MUST use native paths and MUST NOT create irrelevant platform directories.
- Machine-specific choices and secrets MUST remain outside committed shared configuration.
- Critical dependencies MUST have one declared compatibility matrix covering package source, version,
  architecture, operating-system family, and workstation/server applicability.
- Package installation MUST be non-interactive where practical after initialization choices have been
  recorded, while preserving clear diagnostics when privileges or prerequisites are missing.
- Existing user configuration outside explicitly managed blocks MUST be preserved.

## Development Workflow and Quality Gates

1. Specify the user-visible outcome, supported platforms, machine roles, dependency sources, failure
   behavior, and acceptance scenarios before implementation.
2. Plan platform-specific implementation paths while keeping shared logic and configuration unified
   wherever practical.
3. Break work into independently verifiable tasks, including documentation and test tasks for every
   affected platform.
4. Render or inspect generated templates and run available syntax, formatting, and static checks
   before applying them to a real machine.
5. Test on representative affected platforms. Record deferred real-machine tests and do not merge
   them as fully verified work.
6. Review changes for idempotency, safe path handling, preservation of user state, dependency version
   parity, workstation/server separation, and English-only repository content.
7. Update bootstrap, compatibility, troubleshooting, or migration documentation whenever observable
   behavior or prerequisites change.

## Governance

This constitution governs specifications, plans, tasks, implementation, review, and documentation in
this repository. When another project document conflicts with it, this constitution takes precedence.

Amendments MUST be proposed as explicit documentation changes with a rationale and an impact review
covering existing specifications, templates, scripts, tests, and user workflows. An amendment is
ratified when it is reviewed and committed to the repository. Materially affected work MUST be updated
or accompanied by a documented migration plan.

Constitution versions follow semantic versioning:

- MAJOR for removing or redefining a principle in a backward-incompatible way.
- MINOR for adding a principle or materially expanding governance requirements.
- PATCH for clarifications and non-semantic wording corrections.

Every feature specification and implementation review MUST include an explicit constitution check.
Exceptions require written justification, limited scope, a named verification or remediation path,
and approval before merge. Reviewers MUST reject changes that claim unsupported platform coverage or
omit required validation evidence.

**Version**: 1.0.0 | **Ratified**: 2026-08-01 | **Last Amended**: 2026-08-01
