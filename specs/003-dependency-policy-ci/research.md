# Research: Dependency Policy CI

## Decision 1: Keep test orchestration in repository scripts

**Decision**: Add one PowerShell and one POSIX entrypoint with explicit test inventories. The workflow
invokes these scripts but does not duplicate their test lists.

**Rationale**: Maintainers need the same command locally and in automation. Explicit inventories also
detect accidental test omission instead of silently accepting whatever a glob happens to find.

**Alternatives considered**:

- List every test in workflow YAML: rejected because local and automated execution would drift.
- Discover every matching filename: rejected because an accidental rename or deletion could reduce
  coverage while the runner still succeeds.
- Introduce a general-purpose test framework: rejected because the existing scripts already express
  the required behavior without another bootstrap dependency.

## Decision 2: Use four required hosted environments

**Decision**: Require Windows x86_64, Ubuntu x86_64, macOS arm64, and macOS x86_64 checks.

**Rationale**: They cover both shell families, Windows-specific behavior, both supported macOS
architectures, and the primary Linux render environment using disposable machines. GitHub currently
publishes standard hosted labels for these environments.

**Alternatives considered**:

- Only Windows and Ubuntu: rejected because macOS template regressions would remain invisible.
- A single matrix job name: rejected because required checks and failures are less clear.
- Persistent self-hosted machines for pull requests: rejected because untrusted contributions could
  execute with persistent machine access.

**Source**: [GitHub-hosted runners reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

## Decision 3: Separate required static CI from installation smoke tests

**Decision**: The first delivery makes existing tests, artifact identity, syntax, language, managed
scope, and whitespace required. Clean installation is a later scheduled/manual phase.

**Rationale**: Real installation is slower, network-sensitive, and can require privileges or GUI
behavior. It should not delay establishing reliable merge gates, and its result must remain a distinct
evidence class.

**Alternatives considered**:

- Run every installation on every pull request: rejected for cost, latency, and fragility.
- Never automate installation: rejected because static contracts cannot prove downloadable assets and
  active runtime paths.
- Treat containers as full workstation evidence: rejected because containers do not represent login
  shells, font registries, GUI terminals, or system services.

## Decision 4: Verify release assets from authoritative metadata

**Decision**: When the manifest changes, render the policy and match every GitHub release asset URL
against its upstream release record. Compare published digests when present; for historical assets
without API digests, download the exact official URL and calculate SHA-256 in disposable storage.

**Rationale**: The manifest validators currently prove shape and version parity but cannot detect a
copied wrong digest. Public release metadata is credential-free, but GitHub does not backfill the
`digest` field for every historical asset. Exact-download hashing preserves verification without
pretending missing metadata is a policy failure. Limiting the expensive fallback to manifest changes
keeps ordinary pull requests fast.

**Alternatives considered**:

- Download every asset on every pull request: rejected because it is slower and wastes bandwidth;
  download fallback is limited to changed manifests and assets lacking a published digest.
- Trust committed hashes indefinitely: rejected because transcription errors would remain undetected.
- Use a repository secret for metadata reads: rejected because public metadata does not require one
  and forked pull requests must remain secretless.

## Decision 5: Use least-privilege pull-request automation

**Decision**: Use read-only repository permissions and the ordinary pull-request event. Do not use a
privileged target-branch event and do not route untrusted pull requests to persistent runners.

**Rationale**: The workflow needs only checked-out content and public upstream metadata. Broader
permissions provide no benefit and increase supply-chain risk.

**Alternatives considered**:

- Privileged pull-request execution: rejected because contributed workflow code could gain target
  repository authority.
- Store GitHub credentials for release checks: rejected as unnecessary.

## Decision 6: Treat publication as release metadata, not remote deployment

**Decision**: A future release workflow may create a tag or release only after required checks pass;
it will never remotely apply dotfiles to user machines.

**Rationale**: Shell, font, and executable changes require machine-owner control. For this repository,
continuous delivery means a validated revision is available for `chezmoi update`, not forced rollout.

## Research Outcome

No planning clarification remains. Runner labels and action versions must be pinned and reviewed at
implementation time; unavailable real-platform targets remain explicitly deferred.
