# Research: Align Dependency Versions

## Decision 1: Use chezmoi data as the single source of truth

**Decision**: Store the compatibility declaration in `.chezmoidata/dependencies.yaml` and consume it
from all installer templates.

**Rationale**: chezmoi merges structured files in `.chezmoidata` into template data, so one committed,
reviewable declaration can drive Windows, macOS, and Linux without a new runtime parser.

**Alternatives considered**:

- Duplicate constants in each script: rejected because drift is the defect being removed.
- Parse a standalone JSON file at runtime: rejected because it adds parser prerequisites during
  bootstrap.
- Put all data in `.chezmoi.toml.tmpl`: rejected because machine prompts and compatibility policy have
  different lifecycles.

**Sources**: [chezmoi `.chezmoidata` reference](https://www.chezmoi.io/reference/special-directories/chezmoidata/),
[chezmoi templating guide](https://www.chezmoi.io/user-guide/templating/).

## Decision 2: Pin the initial compatibility set

| Dependency | Declared version | Applicability | Initial source policy |
|---|---:|---|---|
| Nushell | `0.114.1` | all roles | exact native package if available; official artifact otherwise |
| Zellij | `0.44.1` | all roles | exact native package if available; official artifact otherwise |
| Helix | `25.07.1` | all roles | exact native package if available; official artifact otherwise |
| Starship | `1.25.1` | all roles | exact native package if available; official artifact otherwise |
| zoxide | `0.9.9` | all roles | exact native package if available; official artifact otherwise |
| fzf | `0.74.1` | all roles | exact native package if available; official artifact otherwise |
| WezTerm | `20240203-110809-5046fc22` | workstation | exact native package if available; official artifact otherwise |
| JetBrainsMono Nerd Font | `3.4.0` | workstation | exact native package if available; official release archive otherwise |

**Rationale**: Nu and Zellij preserve already tested compatibility anchors. Helix, zoxide, fzf, and
Nerd Fonts use verified upstream releases already represented in the repository's installation paths.
Starship uses the latest upstream release verified during research rather than the unpinned installer.
WezTerm uses its current stable release identifier. Every future change is a compatibility update, not
an implicit package-manager upgrade.

**Alternatives considered**:

- Always install latest: rejected because configuration behavior has already drifted across platforms.
- Pin only Nushell and Zellij: rejected because all eight tools affect the shared runtime or rendering.
- Pin to whatever is currently installed on the development PC: rejected because local PATH state is
  not cross-platform release evidence.

**Upstream references**: [Zellij releases](https://github.com/zellij-org/zellij/releases),
[Helix releases](https://github.com/helix-editor/helix/releases),
[Starship releases](https://github.com/starship/starship/releases),
[zoxide releases](https://github.com/ajeetdsouza/zoxide/releases),
[fzf releases](https://github.com/junegunn/fzf/releases),
[WezTerm releases](https://github.com/wezterm/wezterm/releases), and
[Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases).

## Decision 3: Package-manager first means exact-version capable first

**Decision**: Use the native/established manager only when it can resolve the declared exact version
for the current target and the active installation can be verified. Otherwise download the declared
official prebuilt artifact. Do not build from source.

**Rationale**: winget, Homebrew, apt, dnf, and apk do not share a reliable historical-version model.
Allowing them to install an arbitrary current version would violate exact equality. The constitution
explicitly permits official prebuilt binaries when a native repository lacks the required version.

**Alternatives considered**:

- Force all installs through package managers: rejected because exact historical versions may vanish
  or be unavailable on one distribution.
- Use official artifacts for everything unconditionally: rejected because it needlessly abandons
  native ownership where an exact package is available.
- Add third-party repositories or source compilation: rejected due to trust, maintenance, disk-space,
  and bootstrap-time costs.

## Decision 4: Stage the entire applicable install set before mutation

**Decision**: Preflight resolves every role-applicable target, downloads packages/artifacts into a
temporary staging directory, verifies declared hashes and basic archive contents, and collects all
failures. Installation begins only when the complete set passes.

**Rationale**: Metadata-only checks can succeed while a later download fails. Staging is the strongest
practical guarantee that an unavailable version does not leave a partially changed machine.

**Alternatives considered**:

- Check URLs then download during installation: rejected because availability can differ between the
  check and mutation.
- Install one dependency immediately after checking it: rejected because it violates zero-change
  preflight failure behavior.
- Transactional rollback: rejected by the clarified requirement and unsafe across unrelated package
  managers and in-use executables.

## Decision 5: Verify the active runtime, not package ownership alone

**Decision**: Capture the resolved command path before and after reconciliation and run the declared
version probe through that path. Font verification first discovers every expected family/style and
then hashes the actual resolved font files; each hash must match the installed-file identity declared
for the selected platform target and package/artifact source. This permits an exact native package to
have different bytes from the official archive without weakening verification. Multiple candidates
are reported when PATH or font discovery selects a non-managed copy.

**Rationale**: A successful transaction does not prove that the user's shell invokes that copy.

**Alternatives considered**:

- Trust package-manager success: rejected because duplicate installations are a specified edge case.
- Trust font family/style alone: rejected because the same family name is reused across Nerd Fonts
  releases and therefore cannot prove exact version equality.
- Delete competing copies: rejected because they may be user-owned or managed by unrelated software.

## Decision 6: Keep overrides in simple machine-local state

**Decision**: Store one English, line-oriented record per retained dependency in the platform's local
state directory. The record includes schema version, dependency ID, rejected declared version,
observed version, and decision. It is ignored when the declared-version key no longer matches.

**Rationale**: Per-file records are atomic, readable from POSIX shell and Windows PowerShell without an
extra JSON parser, and remain outside committed chezmoi source state.

**Alternatives considered**:

- Commit overrides into `.chezmoidata`: rejected because choices are machine-specific.
- Mutate chezmoi config: rejected because installer scripts should not rewrite initialization answers.
- Remember forever by dependency ID only: rejected because it would silently carry consent across a
  future compatibility target.

## Decision 7: Runtime failure is a resumable convergence point

**Decision**: Apply in manifest order. After each verified success, append a run-journal entry. On
failure, stop and report changed, failed, and pending items plus a safe package-specific removal or
rollback command; use an official documentation reference when an automatic command could affect
unrelated packages. The next apply observes reality from scratch.

**Rationale**: Cross-manager rollback is unreliable, but an explicit journal makes partial state
understandable and repeatable without pretending the run was transactional.

## Decision 8: Preserve the existing support boundary

**Decision**: This feature covers Windows x86_64, macOS x86_64/arm64, and the repository's existing
apt/dnf/apk Linux x86_64/arm64 targets. Linux target resolution distinguishes glibc from musl where
upstream artifacts do. MacPorts and additional OS families remain deferred.

**Rationale**: Version alignment must not silently become a platform-expansion feature. A target with
no verified artifact is blocked rather than assigned an unverified substitute.

## Research Outcome

There are no unresolved planning clarifications. Exact asset filenames and SHA-256 values are
manifest data to be populated and mechanically validated during implementation; a missing mapping or
hash is a validation failure, never a runtime fallback.
