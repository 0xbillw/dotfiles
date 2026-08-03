# Feature Specification: Dependency Policy CI

**Feature Branch**: `ci/dependency-policy`

**Created**: 2026-08-02

**Status**: Draft

**Input**: User description: "Continuously validate the cross-platform dependency policy, run the
existing automated checks consistently, and separate required pull-request checks from slower real
installation smoke tests."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Trust Every Pull Request (Priority: P1)

As a maintainer reviewing a pull request, I receive one consistent pass or failure result for the
dependency policy on each primary operating-system family before merging.

**Why this priority**: The repository already has automated checks, but an undocumented local command
sequence is easy to skip or run differently. Required automation provides the minimum reliable merge
gate.

**Independent Test**: Introduce a harmless policy error in a test branch and verify that the relevant
cross-platform checks fail with an actionable diagnostic; restore the policy and verify that every
required check passes.

**Acceptance Scenarios**:

1. **Given** a pull request changes the dependency manifest, templates, tests, or feature documents,
   **When** validation runs, **Then** all existing policy, upgrade, reconciliation, installer-contract,
   syntax, managed-target, language, and whitespace checks execute through committed test entrypoints.
2. **Given** one required check fails, **When** a maintainer views the pull request, **Then** the failed
   platform and check are identifiable and the pull request is not release-ready.
3. **Given** all required checks pass, **When** the same entrypoints run locally, **Then** they execute
   the same test groups with the same success criteria.

---

### User Story 2 - Make Release Readiness Auditable (Priority: P2)

As a maintainer preparing a release, I can distinguish required automated checks, existing manual
platform evidence, and deferred targets before publishing a compatibility claim.

**Why this priority**: A green static test suite must not be confused with complete real-platform
verification.

**Independent Test**: Review one completed validation run and the committed evidence summary, then
determine without inspecting test implementation which platforms passed static or contract
validation, which have separately recorded manual evidence, and which remain deferred.

**Acceptance Scenarios**:

1. **Given** all required pull-request checks pass but a real-install target has no committed evidence,
   **When** release readiness is reviewed, **Then** that target is reported as deferred rather than
   passed.
2. **Given** existing manual smoke evidence records a failure, **When** maintainers review the evidence,
   **Then** the affected target, phase, expected version, and next action are available.
3. **Given** a validated revision, **When** maintainers publish it, **Then** publishing never applies
   dotfiles automatically to personal workstations or remote servers.

### Edge Cases

- A dependency release asset is removed or its published digest changes after the manifest is merged.
- A test runner image changes a preinstalled tool or default command path.
- A pull request comes from an untrusted fork and must not receive repository secrets or access to
  persistent machines.
- One platform check is cancelled, times out, or is unavailable while other checks pass.
- A scheduled validation is delayed or skipped.
- A clean-environment installation requires interaction, elevated privileges, or a graphical session.
- Multiple validation definitions accidentally publish the same required-check name.
- A test entrypoint succeeds without discovering or running one of the expected test files.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST provide one committed Windows validation entrypoint and one committed
  POSIX validation entrypoint that discover and run their complete expected test sets.
- **FR-002**: Each entrypoint MUST fail when any invoked check fails and MUST identify the failed test.
- **FR-003**: Every pull request targeting the default branch MUST run required validation on Windows,
  Linux, Apple Silicon macOS, and Intel macOS environments without path-based exclusions.
- **FR-004**: Required validation MUST cover manifest structure, declared-version propagation, policy
  mutation safeguards, reconciliation contracts, platform installer contracts, template or script
  syntax available on the current environment, managed-target exclusions, English-only additions,
  and repository whitespace integrity.
- **FR-005**: When the dependency manifest changes, validation MUST verify every official artifact URL
  and digest against authoritative upstream release metadata, or against the downloaded bytes from
  that exact official URL when historical metadata has no published digest, without storing credentials.
- **FR-006**: Required checks MUST use stable, unique names suitable for merge protection.
- **FR-007**: Clean-install smoke tests MUST use disposable environments and MUST NOT run against a
  maintainer's persistent workstation or production server when implemented by a later feature.
- **FR-008**: Required validation MUST explicitly state that it does not constitute clean-install or
  workstation verification.
- **FR-009**: Documentation MUST preserve the future smoke-test coverage matrix without implementing
  or claiming that coverage in this delivery.
- **FR-010**: Workflow names, job output, and the committed evidence summary MUST distinguish static,
  contract, manually verified, and deferred evidence; `clean-install` MUST be reserved for a future
  workflow that actually performs it.
- **FR-011**: Automation triggered by untrusted contributions MUST NOT expose secrets or dispatch work
  to persistent privileged environments.
- **FR-012**: Publishing automation MUST NOT remotely execute `chezmoi apply` on user-owned machines.
- **FR-013**: Maintainer documentation MUST describe local test commands, automated triggers, required
  checks, scheduled checks, failure interpretation, and deferred coverage.
- **FR-014**: This delivery MUST establish required cross-platform validation and artifact
  verification; real-install smoke tests are out of scope and require a later independently
  reviewable feature.

### Key Entities

- **Validation Entrypoint**: A committed command that runs a defined complete test set and returns one
  reliable success or failure result.
- **Validation Target**: An operating-system, architecture, and role combination covered by a static,
  contract, or installation check.
- **Evidence Class**: The level of confidence represented by a result: static, contract,
  clean-install, manual, or deferred.
- **Required Check**: A uniquely named validation result that must pass before a pull request is
  considered merge-ready.
- **Smoke-Test Run**: A disposable installation attempt containing target identity, active versions,
  first-apply result, second-apply result, and failure diagnostics.
- **Release Readiness Result**: The consolidated set of passed and deferred evidence for one revision.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every pull request receives required validation results for four primary platform
  environments without maintainers manually starting tests.
- **SC-002**: One local command per shell family runs 100% of the expected automated dependency-policy
  tests and returns a nonzero result for any failing test.
- **SC-003**: A stale version, incomplete target mapping, bad digest, duplicated installer version,
  unmanaged development directory, non-English added line, or whitespace error prevents a successful
  required validation result.
- **SC-004**: Required validation completes within 15 minutes per platform under normal service and
  network conditions.
- **SC-005**: Required validation labels 100% of its results with the correct evidence class and makes
  no clean-install claim.
- **SC-006**: Every reported compatibility summary identifies all unexecuted real-platform targets as
  deferred; zero unexecuted targets are labeled verified.
- **SC-007**: No automated validation or publication run modifies a maintainer-owned or production
  machine unless that machine was explicitly registered for an isolated manual validation workflow.

## Assumptions

- The repository remains hosted on GitHub and may use its native pull-request status checks.
- Standard disposable Windows, Linux, Apple Silicon macOS, and Intel macOS environments are available.
- Existing dependency-policy tests remain the initial source of truth and can be wrapped without
  rewriting their assertions.
- Upstream GitHub release metadata exposes artifact URLs without authentication; newer assets may
  expose SHA-256 digests, while historical assets can require downloading the exact official URL.
- Required pull-request validation is intentionally lighter than the complete real-install coverage
  matrix.
- Clean server and workstation installation workflows are out of scope for this feature.
- Linux distribution and architecture coverage may combine hosted environments, containers, and
  explicitly documented manual evidence.
- Branch protection configuration is a repository-owner action documented by this feature but is not
  modified by repository code alone.
