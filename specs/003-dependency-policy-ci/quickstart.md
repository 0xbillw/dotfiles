# Quickstart: Validate Dependency Policy CI

## Prerequisites

- Git repository checkout with the active feature branch.
- chezmoi 2.71.1 available through `CHEZMOI` or `PATH`.
- PowerShell for Windows tests and a POSIX shell for POSIX tests.
- Network access to public GitHub release metadata for artifact verification.

## 1. Run locally

PowerShell:

```powershell
./tests/dependency-policy/run-all.ps1 -RepositoryRoot $PWD
```

POSIX:

```sh
sh tests/dependency-policy/run-all.sh "$PWD"
```

Expected: every inventory item is announced and the final line reports the exact number of passed
tests.

## 2. Prove inventory enforcement

In a disposable working copy, temporarily rename one listed test and run its entrypoint.

Expected: the entrypoint fails before reporting suite success and names the missing test. Restore the
file before continuing.

## 3. Prove artifact mismatch detection

In a disposable working copy, replace one declared SHA-256 value with 64 zeroes and run the PowerShell
entrypoint.

Expected: release verification reports the dependency, target, asset URL, declared digest, and
published digest, then exits nonzero. Restore the manifest before continuing.

## 4. Validate changed-line quality checks

Run both entrypoints with the merge base used for the pull request:

```powershell
./tests/dependency-policy/run-all.ps1 -RepositoryRoot $PWD -BaseRef <base-revision>
```

```sh
sh tests/dependency-policy/run-all.sh "$PWD" <base-revision>
```

Expected: English-only added-line and whitespace checks inspect the requested revision range. The
managed-target check confirms `.agents`, `.specify`, `specs`, and `tests` are not deployed.

## 5. Validate workflow behavior

Open a pull request containing only the completed CI implementation.

Expected required results:

```text
dependency-policy / Windows x86_64
dependency-policy / Linux x86_64
dependency-policy / macOS arm64
dependency-policy / macOS x86_64
dependency-policy / Release assets and repository quality
```

Push a second revision while the first run is active and confirm the older run is cancelled. Confirm
that a failure in any required result prevents merge readiness after branch protection is configured.

## 6. Deferred smoke-test evidence

Do not treat the required checks above as real installation evidence. Until phase-two workflows exist,
continue recording DNF, apk, arm64, Windows workstation, and macOS workstation execution under
`tests/dependency-policy/evidence/` with untested targets explicitly marked deferred.
