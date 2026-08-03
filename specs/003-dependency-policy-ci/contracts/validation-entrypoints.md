# Contract: Validation Entrypoints

## Commands

Windows/PowerShell:

```powershell
./tests/dependency-policy/run-all.ps1 [-RepositoryRoot <path>] [-BaseRef <revision>]
```

POSIX:

```sh
sh tests/dependency-policy/run-all.sh [repository-root] [base-revision]
```

Both commands default the repository root from their own location. The comparison base is optional;
checks that require changed-line context print an explicit skip locally when no base is supplied, while
CI always supplies one.

## Required PowerShell inventory

```text
Test-DependencyManifest.ps1
Test-PolicyUpgrade.ps1
Test-WindowsDependencyInstall.ps1
Test-WindowsReconciliation.ps1
Test-ReleaseAssets.ps1
```

## Required POSIX inventory

```text
test-dependency-manifest.sh
test-policy-upgrade.sh
test-darwin-dependency-install.sh
test-linux-dependency-install.sh
test-posix-reconciliation.sh
```

Platform filtering may skip a test only when its declared contract does not apply to the current
shell family. A missing inventory file is always a failure.

## Output contract

Each test begins with:

```text
==> <test path>
```

Success ends with:

```text
Dependency policy suite passed: <count> tests.
```

Failure ends immediately with the underlying diagnostic and nonzero exit code. Entrypoints do not
swallow stderr or convert a failed command into success.

## Safety contract

- Tests use only repository files and disposable temporary paths.
- The entrypoints do not invoke production `chezmoi apply`.
- Public metadata verification uses no credentials.
- No test writes to package databases, user font registries, shell profiles, or system paths.
