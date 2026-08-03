# Data Model: Dependency Policy CI

## ValidationEntrypoint

| Field | Type | Rules |
|---|---|---|
| `shellFamily` | enum | `powershell` or `posix` |
| `tests` | ordered list | Explicit, non-empty, every path must exist |
| `comparisonBase` | optional revision | Used by changed-line and whitespace checks |
| `result` | enum | `passed` or `failed` |
| `failedTest` | optional path | Required when result is failed |

An entrypoint stops at the first failure, preserves the underlying exit code, prints the test name,
and never mutates the host outside disposable test paths.

## ValidationTarget

| Field | Type | Description |
|---|---|---|
| `id` | string | Stable unique check name |
| `os` | enum | Windows, Linux, or macOS |
| `arch` | enum | x86_64 or arm64 |
| `role` | optional enum | server or workstation for smoke tests |
| `evidenceClass` | enum | static, contract, clean-install, manual, deferred |
| `requiredForMerge` | boolean | Whether failure blocks merge readiness |

## ArtifactIdentityCheck

| Field | Type | Rules |
|---|---|---|
| `dependencyId` | string | Must exist in the dependency policy |
| `targetId` | string | Must exist under the dependency |
| `releaseOwner` | string | Derived from the official URL |
| `releaseRepository` | string | Derived from the official URL |
| `releaseTag` | string | Exact version-bearing tag |
| `assetUrl` | HTTPS URL | Must exactly match one published asset |
| `declaredDigest` | SHA-256 | 64 lowercase hex characters |
| `publishedDigest` | SHA-256 | Must equal declared digest |
| `result` | enum | matching, missing-asset, digest-mismatch, upstream-unavailable |

Repeated target mappings may share one asset URL. The verifier retrieves each unique release once and
checks every target declaration independently.

## EvidenceRecord

| Field | Type | Description |
|---|---|---|
| `revision` | string | Validated repository revision |
| `targetId` | string | Validation target identity |
| `evidenceClass` | enum | Confidence level of the result |
| `status` | enum | passed, failed, cancelled, timed-out, deferred |
| `startedAt` | timestamp | Start time supplied by automation |
| `diagnostic` | optional string | Failed phase and next action |

## ReleaseReadinessResult

| Field | Type | Rules |
|---|---|---|
| `revision` | string | One immutable revision |
| `requiredChecks` | list | All must pass |
| `optionalChecks` | list | May pass, fail, or remain deferred |
| `deferredTargets` | list | Every unexecuted real target must appear |
| `status` | enum | merge-ready, not-ready, statically-ready-real-platforms-deferred |

## State Transitions

```text
revision proposed
  -> required checks pending
     -> any failed/cancelled/timed-out: NOT_READY
     -> all passed: MERGE_READY
        -> optional smoke evidence complete: VERIFIED_FOR_RECORDED_TARGETS
        -> optional smoke evidence missing: STATICALLY_READY_REAL_PLATFORMS_DEFERRED
```

No state permits an unexecuted target to transition directly to verified.
