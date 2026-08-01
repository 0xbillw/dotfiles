# Contract: Dependency Reconciliation

## Inputs

- Valid dependency compatibility manifest.
- Detected platform target and initialized machine role.
- Current active executable/font state.
- Machine-local retain overrides.
- Interactive capability (`stdin` and `stderr` attached to a terminal).

## Ordered behavior

1. Validate the manifest and detect the platform target.
2. If automatic dependency management is disabled, exit successfully before network access,
   installation, or retain-state writes; existing shared configuration remains managed.
3. If OS, package-manager family, architecture, or libc is unknown or has no exact manifest mapping,
   return `target-unsupported` with an actionable diagnostic and perform no mutation.
4. Filter dependencies by role and observe all active installations.
5. For each newer incompatible installation:
   - reuse a matching retain override; otherwise
   - interactively offer `downgrade`, `retain as unsupported`, or `cancel`; or
   - in non-interactive mode, block with rerun instructions.
6. Resolve every required package/artifact, download it to temporary staging, verify its SHA-256 and
   required contents, and collect every failure.
7. If any preflight item fails, report all failures and perform no mutations.
8. Apply planned changes in manifest order. After each change, resolve the active path/font again and
   verify the declared executable version or the discovered font files against their declared hashes.
9. On the first runtime failure, stop. Report changed, failed, and pending items and removal/rollback
   guidance for every item changed in this run. Do not roll back automatically.
10. On success, report compatible or explicitly unsupported status. Delete temporary staging data.
11. Downstream Starship/zoxide integration generation accepts either an exact active version or a
    matching retain override. A retained executable continues to produce an unsupported result and is
    never reclassified as compatible.

## Interactive newer-version prompt

The prompt must display dependency, expected version, observed version and path, target, and these
choices:

- `Downgrade`: replace with the declared version.
- `Keep unsupported`: leave it untouched, persist consent for this dependency and declared version,
  and finish with unsupported status.
- `Cancel`: stop dependency setup before mutation.

The prompt requires an explicit choice. Invalid input is explained and repeated; a single unrelated
keystroke must not silently accept a value.

## Result classes

| Result | Meaning | Mutation allowed |
|---|---|---|
| `compatible` | Every applicable active dependency matches policy. | Yes, completed |
| `unsupported` | At least one newer version was explicitly retained. | Other approved changes may complete |
| `cancelled` | User cancelled before mutation. | No |
| `preflight-blocked` | One or more applicable payloads unavailable/invalid. | No |
| `interaction-required` | Non-interactive run encountered newer version. | No |
| `partial-failure` | Mutation began and a later action or verification failed. | Completed changes remain |
| `target-unsupported` | Platform target has no declared mapping. | No |

## Required diagnostics

Every blocked item includes:

```text
Dependency: <name>
Expected: <version>
Observed: <version and path, or absent>
Target: <os/family/arch/libc/role>
Next action: <safe actionable instruction>
```

A partial-failure report additionally groups `Changed`, `Failed`, and `Pending`, supplies a safe
manual removal/rollback command or official documentation reference per changed dependency, and says
that the next `chezmoi apply` reassesses observed state and resumes convergence.

## Safety invariants

- Never remove competing or unrelated installations automatically.
- Never mutate before the complete applicable preflight succeeds.
- Never substitute an undeclared version or architecture.
- Never treat a retained newer version as compatible.
- Never install workstation-only dependencies for a server role.
- Never claim package success until the active executable/font verifies.
- Never infer an exact font version from family/style discovery without matching the declared installed
  file hashes.
- Never suggest a removal command that may remove unrelated dependencies; link official guidance and
  explain the limitation instead.
