# Data Model: macOS 12 MacPorts Support

## MacOSTarget

The normalized macOS machine identity used before dependency resolution.

| Field | Type | Rules |
|---|---|---|
| `os` | literal | Always `darwin` for this feature. |
| `majorVersion` | integer | `12` selects the Monterey legacy path; newer supported versions retain existing behavior. |
| `releaseName` | enum | `monterey` when `majorVersion` is `12`; otherwise `newer-macos` for this feature's regression scope. |
| `arch` | enum | `x86_64` or `aarch64`; unknown architecture is blocked before mutation. |
| `role` | enum | `workstation` or `server`; role filters dependencies before preflight. |
| `packageFamily` | enum | `macports` for Monterey when native package management is required; existing macOS family for newer releases. |

Validation rules:

- macOS 12 must not be routed through the newer macOS package-management path by default.
- Newer macOS must not enter the Monterey path unless explicitly selected by a documented override.
- Unknown macOS major version or CPU architecture must produce an actionable blocked diagnostic rather than
  guessing.

## LegacyPackagePrerequisite

The prerequisite state for Monterey package-management operations.

| Field | Type | Rules |
|---|---|---|
| `manager` | literal | `macports`. |
| `command` | string | `port`. |
| `expectedPrefix` | path | Default expected prefix is `/opt/local`. |
| `status` | enum | `available`, `missing`, `not-on-path`, `unusable`. |
| `observedPath` | path/null | The discovered `port` executable path when present. |
| `observedVersion` | string/null | Result of a version probe when available. |
| `nextAction` | string | English instruction for installing, opening a new shell, or fixing PATH. |

Validation rules:

- A missing or unusable prerequisite blocks before dependency preflight and mutation.
- The diagnostic must identify the selected package-management path and the next action.
- The prerequisite record must not imply that Homebrew is an acceptable Monterey fallback.

## DependencySourceSelection

The selected source for a managed dependency on a specific Monterey target.

| Field | Type | Rules |
|---|---|---|
| `dependencyId` | string | Must match an existing managed dependency ID. |
| `target` | MacOSTarget | Monterey target plus role and architecture. |
| `strategy` | enum | `official-artifact`, `native-package`, or `platform-exception`. |
| `manager` | enum/null | `macports` only when `strategy` is `native-package`; null for official artifacts. |
| `version` | string | Exact declared compatible version; never `latest`. |
| `verification` | object | Executable version probe or font hash requirements from the dependency policy. |
| `requiresPrerequisite` | boolean | True when the selected source needs MacPorts before mutation. |

Validation rules:

- Official artifacts remain valid on Monterey only when their declared archive and member are compatible with
  the target architecture and checksum verification passes.
- Native MacPorts package selections require an exact compatible package declaration and an available
  MacPorts prerequisite.
- A dependency may not silently switch to an undeclared source or version.

## ActiveMacOSInstallation

The active executable or asset observed on the Monterey machine.

| Field | Type | Rules |
|---|---|---|
| `dependencyId` | string | Managed dependency identity. |
| `activePath` | path/null | First executable or asset selected by the active environment. |
| `sourceClass` | enum | `managed-user-local`, `macports`, `homebrew`, `manual`, `font-registry`, `absent`, `unknown`. |
| `observedVersion` | string/null | Parsed executable version or verified font asset identity. |
| `comparison` | enum | `missing`, `equal`, `older`, `newer`, `unparseable`, `incompatible`. |
| `duplicates` | list | Additional candidate paths or assets; informational only. |

Validation rules:

- Competing Homebrew or manual installations are never automatically removed.
- A duplicate candidate must be reported when it affects active compatibility.
- A successful run verifies the active installation after mutation or confirms it was already compatible.

## MontereyDiagnostic

The user-facing and evidence-facing result for a blocked, compatible, unsupported, or partial Monterey run.

| Field | Type | Rules |
|---|---|---|
| `result` | enum | `compatible`, `prerequisite-blocked`, `preflight-blocked`, `target-unsupported`, `interaction-required`, `partial-failure`, `unsupported`. |
| `dependencyId` | string/null | Required for dependency-specific failures. |
| `expected` | string | Expected version, package path, or prerequisite. |
| `observed` | string | Observed version, path, missing state, or failure reason. |
| `target` | MacOSTarget | Exact macOS release category, architecture, role, and package-management path. |
| `nextAction` | string | Safe action the user can perform. |

Validation rules:

- `prerequisite-blocked`, `preflight-blocked`, `target-unsupported`, and `interaction-required` happen before
  dependency mutation.
- Partial failure reports changed, failed, and pending dependencies plus safe removal guidance.
- Compatible results require every role-applicable dependency to be verified.

## State Transitions

```text
detect macOS major version and architecture
  -> if macOS 12: select Monterey legacy path
  -> if newer macOS: retain existing macOS path
  -> filter dependencies by role
  -> resolve source selection for each applicable dependency
  -> if any selected source requires MacPorts: validate MacPorts prerequisite
     -> missing/unusable: PREREQUISITE_BLOCKED, no mutation
  -> observe active installations and duplicates
  -> preflight selected artifacts/packages
     -> any failure: PREFLIGHT_BLOCKED, no mutation
  -> apply changes in dependency order
     -> verify active result after each change
        -> failure: PARTIAL_FAILURE
  -> all verified: COMPATIBLE
```
