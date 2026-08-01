# Data Model: Align Dependency Versions

## ManagedDependency

The canonical policy record for one managed tool or asset.

| Field | Type | Rules |
|---|---|---|
| `id` | string | Stable lowercase identifier; unique. |
| `displayName` | string | English diagnostic name. |
| `version` | string | Exact upstream version; never `latest` or a range. |
| `kind` | enum | `executable` or `font`. |
| `roles` | list | Non-empty subset of `workstation`, `server`. |
| `versionProbe` | object | Command arguments and parser rule for executables. |
| `fontProbe` | object | Expected family/styles used to discover the active installed font files. |
| `targets` | map | One resolution entry for every supported applicable target. |
| `installOrder` | integer | Unique deterministic mutation order. |

Validation: exactly eight records exist for the specified set; versions are exact; workstation-only
entries are WezTerm and JetBrainsMono Nerd Font; each target has one install strategy or a complete
approved exception.

For a font, `fontProbe` discovers the active family/style files and each `TargetResolution` declares
the SHA-256 identity expected after its selected package or artifact is installed. Successful
verification requires both platform font discovery and equality of the actual discovered file hashes.
Family/style discovery alone is insufficient because those names can be shared by multiple releases.

## PlatformTarget

The normalized current machine identity used to select a manifest target.

| Field | Values |
|---|---|
| `os` | `windows`, `darwin`, `linux` |
| `family` | `winget`, `homebrew`, `apt`, `dnf`, `apk` |
| `arch` | `x86_64`, `aarch64` |
| `libc` | `glibc`, `musl`, or `none` |
| `role` | `workstation`, `server` |

The detector must reject an unsupported or ambiguous combination rather than guess. Role filtering
happens before availability preflight.

## TargetResolution

How one dependency/version is obtained for one target.

| Field | Type | Rules |
|---|---|---|
| `strategy` | enum | `native-package` or `official-artifact`. |
| `package` | object | Manager package ID and exact version expression, when used. |
| `artifact` | object | HTTPS URL, archive type, SHA-256, executable/font members. |
| `installedFiles` | map | Font-only filename-to-SHA-256 identities for this exact target and source. |
| `installLocation` | string | User-local or native managed location. |
| `removeGuidance` | object | Safe command template or official documentation URL. |
| `exception` | PlatformException? | Required only when exact equality is waived. |

## PlatformException

| Field | Type | Rules |
|---|---|---|
| `reason` | string | Concrete incompatibility or upstream limitation. |
| `scope` | PlatformTarget selector | Exact affected targets. |
| `compatibleVersion` | string | Exact version or explicit bounded range. |
| `evidence` | URL/list | Verification evidence. |
| `removalCondition` | string | Objective condition that retires the exception. |

No initial exception is implied. Adding one is a reviewed manifest change.

## ObservedInstallation

| Field | Type | Description |
|---|---|---|
| `dependencyId` | string | Managed dependency identity. |
| `path` | string/null | Active executable or discoverable font path. |
| `rawVersion` | string/null | Unmodified executable probe result or discovered font file identities. |
| `normalizedVersion` | string/null | Parsed executable version or manifest release version proven by matching font hashes. |
| `source` | enum | Managed location, native manager, competing PATH entry, font registry, absent, unknown. |
| `comparison` | enum | `missing`, `older`, `equal`, `newer`, `unparseable`. |
| `duplicates` | list | Other discovered candidates; never automatically removed. |

## RetainOverride

| Field | Type | Rules |
|---|---|---|
| `schema` | integer | Starts at `1`. |
| `dependencyId` | string | Must match the current dependency. |
| `declaredVersion` | string | Consent key; mismatch invalidates the record. |
| `observedVersion` | string | Newer version retained by the user. |
| `decision` | literal | `retain-unsupported`. |

State location:

- Windows: `%LOCALAPPDATA%\cross-platform-terminal-workspace\dependency-state\`
- macOS/Linux: `${XDG_STATE_HOME:-$HOME/.local/state}/cross-platform-terminal-workspace/dependency-state/`

The state directory is machine-local and must not be added to chezmoi source state.

## ReconciliationItem

| Field | Values |
|---|---|
| `desired` | Dependency plus selected target resolution |
| `observed` | ObservedInstallation |
| `action` | `none`, `install`, `upgrade`, `downgrade`, `retain`, `skip-role`, `block` |
| `status` | `planned`, `staged`, `changed`, `verified`, `failed`, `pending`, `unsupported` |
| `diagnostic` | Expected/observed/target/next-action message fields |

## State Transitions

```text
detect target
  -> observe all applicable dependencies
  -> resolve newer-version decisions
  -> preflight every planned payload
     -> any failure: BLOCKED (no mutation)
     -> all pass: apply in installOrder
        -> verify active result
           -> success: continue
           -> failure: PARTIAL_FAILURE (stop, journal, guidance)
  -> all verified: COMPATIBLE
  -> retained newer item present: UNSUPPORTED
```

Cancellation and non-interactive newer-version conflicts terminate before preflight and mutation.
