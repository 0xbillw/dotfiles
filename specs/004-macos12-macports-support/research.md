# Research: macOS 12 MacPorts Support

## Decision 1: Treat macOS 12 Monterey as a legacy macOS path

**Decision**: Detect macOS 12 separately from newer macOS and route it through a Monterey-specific legacy
macOS package-management path.

**Rationale**: Homebrew 4.4.0 announced that macOS Monterey 12 is no longer supported and no longer a CI
target. Homebrew's support-tier documentation also classifies Tier 3 configurations as unsupported,
unstable, lacking CI coverage, and candidates for migration to non-Homebrew tools. This makes Monterey a
bad default for Homebrew-based dependency management even if some commands still work.

Sources:

- https://brew.sh/2024/10/01/homebrew-4.4.0/
- https://docs.brew.sh/Support-Tiers

**Alternatives considered**:

- Keep treating all macOS versions the same: rejected because Monterey-specific Homebrew failures would be
  surprising and hard to diagnose.
- Mark Monterey unsupported: rejected because the feature goal is to support the user's Mac mini.
- Use MacPorts for all macOS releases: rejected because the feature must preserve newer macOS behavior.

## Decision 2: Use MacPorts as the legacy macOS manager prerequisite

**Decision**: For macOS 12, use MacPorts as the declared legacy macOS package-management path whenever a
native package manager is required.

**Rationale**: MacPorts publishes an installer for macOS 12 Monterey and installs to `/opt/local` by
default. Its guide says the macOS package installer sets up the shell environment and recommends checking
installation with `port version`. This makes it a suitable documented prerequisite for Monterey users.

Source:

- https://guide.macports.org/chunked/installing.macports.html

**Alternatives considered**:

- Ask users to keep using Homebrew: rejected because Monterey is no longer a suitable supported Homebrew
  target.
- Vendor all dependencies into the repository: rejected due to repository size, trust, update, and security
  costs.
- Build from source on Monterey: rejected because source builds are slower, harder to reproduce, and contrary
  to the existing dependency policy.

## Decision 3: Keep official artifacts preferred when compatible on Monterey

**Decision**: Do not replace official artifacts with MacPorts packages merely because the host is Monterey.
Use the existing checksum-verified official artifact strategy when the artifact is compatible and already
covers the Monterey architecture. Add MacPorts native-package entries only for dependencies where the
official artifact is unavailable, incompatible, or otherwise less reliable on Monterey.

**Rationale**: The current dependency policy already values exact versions and checksum-verified official
artifacts when package managers cannot guarantee the required version. Keeping compatible artifacts avoids
unnecessary package-source churn and limits the MacPorts change to the legacy package-management gap.

**Alternatives considered**:

- Convert every macOS dependency to MacPorts: rejected because MacPorts package versions may not match the
  declared versions and would increase migration risk.
- Convert every dependency to official artifacts unconditionally: rejected because native package ownership
  remains valuable when an exact compatible package is available.

## Decision 4: Block before mutation when MacPorts is required but unavailable

**Decision**: If a Monterey run requires MacPorts and `port` is missing, not discoverable, or unusable, the
installer reports `prerequisite-blocked` or the existing nearest blocked result before downloads, installs,
state writes, or PATH mutation.

**Rationale**: The specification requires prerequisite failures to make no managed dependency changes. Early
blocking keeps the setup safe on machines with partial Homebrew/MacPorts/manual installations.

**Alternatives considered**:

- Attempt to install MacPorts automatically: rejected because installing a system package manager requires
  user trust, privileges, and Xcode Command Line Tools state that should be documented prerequisites.
- Fall back to Homebrew when MacPorts is missing: rejected because that reintroduces unsupported Homebrew
  behavior on Monterey.

## Decision 5: Add MacPorts paths as candidate paths without changing ownership semantics

**Decision**: Add `/opt/local/bin` and `/opt/local/sbin` to macOS shell candidate paths, while keeping the
managed user-local bin directory first and avoiding duplicate entries.

**Rationale**: MacPorts defaults to `/opt/local`, and users need the `port` command and MacPorts-provided
executables discoverable in interactive shells. Keeping `$HOME/.local/bin` first preserves the existing
managed-artifact acceptance path.

**Alternatives considered**:

- Put `/opt/local/bin` ahead of `$HOME/.local/bin`: rejected because it could shadow managed official
  artifacts and change active-version verification.
- Do not add MacPorts paths: rejected because MacPorts installed by package may not be discoverable in every
  shell launched after chezmoi renders shared configuration.

## Decision 6: Verify newer macOS remains unchanged through fixtures

**Decision**: Add regression fixtures that render newer macOS x86_64 and arm64 profiles and assert they do
not enter the Monterey-specific path.

**Rationale**: The constitution requires platform-specific verification and the spec requires Monterey
support not to regress newer macOS behavior.

**Alternatives considered**:

- Test only Monterey fixtures: rejected because the primary risk of legacy branching is accidental behavior
  changes for existing macOS targets.
