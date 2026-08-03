# Cross-platform terminal workspace

This repository builds a consistent, ready-to-use terminal workspace across
Windows, macOS, and Linux. It uses `chezmoi` to turn a fresh workstation or
remote server into the same familiar environment with one configuration and a
repeatable installation flow.

It solves the common problems of maintaining terminal configuration by hand:

- Different shells, paths, and configuration locations on each operating
  system.
- Reinstalling programs, fonts, prompt integrations, and helper tools on every
  new machine.
- Keeping terminal, shell, multiplexer, navigation, proxy, and editor behavior
  synchronized.
- Rebuilding a productive remote-server environment without installing local
  GUI components on the server.

The resulting stack combines WezTerm, Nushell, Zellij, Helix, Starship, and
zoxide.
Machine-specific choices such as editors, fonts, proxy settings, and whether a
machine is a graphical workstation or a headless server remain local, while the
shared behavior stays version-controlled and portable.

## Platform scope

| Platform | Workstation | Headless/server | Dependency automation |
| --- | --- | --- | --- |
| Windows | WezTerm, font, and CLI stack | CLI stack | winget |
| macOS | WezTerm, font, and CLI stack | CLI stack | Homebrew |
| Linux | CLI stack and Nerd Font; GUI terminal package is distribution-specific | CLI stack | apt, dnf, or apk plus official binaries |

On supported Linux graphical workstations, the Nerd Font is installed
automatically. WezTerm remains distribution-managed; the shared terminal and
shell configuration remains the same.

## Design

```text
WezTerm
  └─ Nushell
      └─ Zellij
          ├─ tabs
          └─ panes
```

Responsibilities:

- **WezTerm**: rendering, fonts, clipboard, window behavior, launching Nushell.
- **Nushell**: cross-platform interactive shell, environment, helper commands.
- **Zellij**: sessions, tabs, panes, layouts.
- **Helix**: the default cross-platform terminal editor with modern built-in
  language and navigation features.
- **Starship**: a consistent cross-platform prompt.
- **zoxide**: frecency-based directory navigation with `z` and `zi`.
- **chezmoi**: deployment, templates, per-OS paths, machine-specific values.

WezTerm's own tabs are disabled so that Zellij remains the only workspace layer.

## Bootstrap

The commands below install this configuration on a new machine. Replace
`YOUR_NAME` with the GitHub owner of the published repository.

### Linux/macOS

Install chezmoi and apply:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- \
  -b "$HOME/.local/bin" \
  -- \
  init --apply YOUR_NAME
```

For a private repository:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- \
  -b "$HOME/.local/bin" \
  -- \
  init --apply git@github.com:YOUR_NAME/dotfiles.git
```

To test a branch before merging it, pass the branch to `chezmoi init`:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- \
  -b "$HOME/.local/bin" \
  -- \
  init --branch BRANCH_NAME --apply YOUR_NAME
```

The explicit `-b` path keeps the chezmoi binary out of the current directory.
The shared Nushell configuration includes `~/.local/bin` in `PATH`.

### Windows PowerShell

```powershell
winget install twpayne.chezmoi
chezmoi init --apply YOUR_NAME
```

For a private repository:

```powershell
chezmoi init --apply git@github.com:YOUR_NAME/dotfiles.git
```

## Managed dependencies

During `chezmoi init`, choose whether chezmoi should manage the required
programs. Package installation is implemented as a change-triggered script, so
ordinary `chezmoi apply` runs do not reinstall everything.

For an existing checkout that predates these questions, refresh the local
machine data first:

```sh
chezmoi init --prompt
chezmoi apply
```

The `--prompt` flag is important: it forces chezmoi's `prompt*Once` functions
to ask again instead of silently preserving previously saved answers.

Two machine roles are supported:

- A **Windows or macOS workstation** installs the CLI tools plus WezTerm and
  the Nerd Font. A supported Linux workstation installs the CLI stack and Nerd
  Font, while leaving the WezTerm package to the distribution.
- A **remote/headless server** installs Nushell, Zellij, Helix, Starship,
  zoxide, and fzf. WezTerm and fonts belong on the local computer displaying
  the SSH session, not on the server.

Windows uses `winget` and macOS uses Homebrew. Linux deliberately does not use
Homebrew. The automatic installer dispatches by distribution family:

- Ubuntu 22.04/24.04 uses apt.
- Fedora, RHEL, CentOS Stream, Rocky Linux, AlmaLinux, Alibaba Cloud Linux,
  and OpenAnolis use dnf.
- Alpine Linux uses apk and musl-compatible binaries.

Native packages are preferred. Official prebuilt binaries are used where an
enabled repository has no suitable package; Rust tools are never compiled from
source. CentOS Linux 7 is EOL and is not supported by this installer.

The managed programs are:

- WezTerm
- Nushell
- Zellij
- Helix
- Starship
- zoxide
- fzf (used by `zi`)
- A Nerd Font, preferably JetBrainsMono Nerd Font

### Compatibility manifest

`.chezmoidata/dependencies.yaml` is the only authoritative dependency-version declaration. Platform
installers render versions, official release URLs, checksums, role applicability, and removal guidance
from that file; they do not maintain independent version constants.

| Dependency | Declared version | Roles |
|---|---:|---|
| Nushell | `0.114.1` | workstation and server |
| Zellij | `0.44.1` | workstation and server |
| Helix | `25.07.1` | workstation and server |
| Starship | `1.26.0` | workstation and server |
| zoxide | `0.10.0` | workstation and server |
| fzf | `0.74.1` | workstation and server |
| WezTerm | `20240203-110809-5046fc22` | workstation only |
| JetBrainsMono Nerd Font | `3.4.0` | workstation only |

An exact native package is preferred when the platform package manager can guarantee the declared
version. Otherwise the installer uses a checksum-verified official prebuilt artifact. It never builds
these tools from source or silently substitutes another version.

Linux WezTerm is the only initial platform exception: WezTerm remains distribution-managed on Linux
workstations because upstream does not publish one portable artifact covering every supported Linux
target. This exception ends when an upstream portable artifact is available and verified across the
declared glibc/musl and x86_64/arm64 targets. Servers never install WezTerm or fonts.

Before changing any managed dependency, setup stages and verifies every applicable package/artifact.
An unavailable asset blocks all managed changes. If execution fails after mutation begins, successful
changes remain; the report lists changed, failed, and pending dependencies plus safe removal guidance.
The next `chezmoi apply` reassesses the observed machine and resumes convergence.

If an installed executable is newer than the declaration, interactive setup offers downgrade, keep as
unsupported, or cancel. A keep decision is stored locally for that dependency and declared version;
changing the declaration invalidates the decision. Non-interactive setup never downgrades a newer
version without consent.

### Verify the active toolchain

Run the version commands in the shell that will use the tools, and also inspect the resolved paths:

```nu
which nu
which zellij
which hx
which starship
which zoxide
which fzf
nu --version
zellij --version
hx --version
starship --version
zoxide --version
fzf --version
```

On a workstation, also run `wezterm --version`. Font verification checks the four actual installed
JetBrainsMono Nerd Font files against the target-specific SHA-256 identities in the manifest; matching
the family name alone is not sufficient.

### Update a managed version

1. Change the dependency version once in `.chezmoidata/dependencies.yaml`.
2. Update every applicable official URL, archive member, SHA-256, exact native package version, and
   installed font-file hash in the same record.
3. Review upstream release notes and shared configuration compatibility.
4. Run the PowerShell and POSIX manifest validators plus the policy-upgrade mutation tests.
5. Execute the affected real-platform checks and record verified and deferred targets separately.
6. Update this table and any approved platform exception before merging.

An exception must declare its rationale, exact target scope, compatible version/range, verification
evidence, and objective removal condition. Incomplete exceptions fail manifest validation.

### Dependency policy CI

Pull requests targeting `main`, pushes to `main`, and manual runs execute the same committed validation
entrypoints available to maintainers:

```powershell
./tests/dependency-policy/run-all.ps1 -RepositoryRoot $PWD
```

```sh
sh tests/dependency-policy/run-all.sh "$PWD"
```

The required branch-protection checks are:

```text
dependency-policy / Windows x86_64
dependency-policy / Linux x86_64
dependency-policy / macOS arm64
dependency-policy / macOS x86_64
dependency-policy / Release assets and repository quality
```

After the workflow has run once on `main`, add these five names to the default branch ruleset or to
`Settings > Branches > Branch protection rules > Require status checks to pass before merging`.

These jobs use read-only permissions and no repository secrets. They validate manifest structure,
version propagation, reconciliation and installer contracts, managed targets, changed-line language,
whitespace, syntax available on each runner, and official GitHub release asset digests. A failure names
the platform or test; reproduce it with the corresponding entrypoint and the pull request base SHA.

A green workflow is static and contract evidence only. It does not prove a clean installation or apply
the dotfiles to any workstation or server. DNF, apk, Linux arm64, Windows workstation, and macOS
workstation installation evidence remains recorded separately under
`tests/dependency-policy/evidence/`; targets without completed evidence remain deferred. Automated
clean-install smoke tests require a later feature using disposable environments.

## Font installation notes

For JetBrainsMono Nerd Font, a terminal setup normally needs these four faces:

```text
JetBrainsMonoNerdFont-Regular.ttf
JetBrainsMonoNerdFont-Bold.ttf
JetBrainsMonoNerdFont-Italic.ttf
JetBrainsMonoNerdFont-BoldItalic.ttf
```

Install multiple files at once by selecting them in File Explorer and choosing
`Install` or `Install for all users`, or drag them into Windows Settings under
`Personalization > Fonts`.

The `Propo` files are proportional variants and should not be used as the main
terminal font. If WezTerm reports that `JetBrainsMono Nerd Font` cannot be
loaded with `weight="Regular"`, verify that
`JetBrainsMonoNerdFont-Regular.ttf` is installed. Installing only the bold,
italic, or light weights is not sufficient.

After installing fonts, close every WezTerm process and start it again. Verify
font discovery with:

```sh
wezterm ls-fonts --text test
```

Suggested commands:

### macOS

```sh
brew install --cask wezterm font-jetbrains-mono-nerd-font
brew install helix zellij starship zoxide
# The automatic installer pins Nushell 0.114.1 from its official release.
```

### Windows

```powershell
winget install wez.wezterm
winget install --exact --id Nushell.Nushell --version 0.114.1
winget install Helix.Helix
winget install Starship.Starship
winget install ajeetdsouza.zoxide
winget install Zellij.Zellij
winget install junegunn.fzf
winget install DEVCOM.JetBrainsMonoNerdFont
```

### Supported Linux distributions

For the automatic flow, choose `1 - Install automatically` during `chezmoi
init`. Ubuntu uses its apt repositories and the documented Helix PPA. DNF
systems install Helix and fzf from enabled repositories, with official release
binaries as fallbacks. Alpine installs Helix and fzf from apk's community
repository and selects the musl Nushell build.

Nushell 0.114.1, Starship, zoxide, and the pinned compatible Zellij release are
installed under `~/.local/bin`. A graphical Linux workstation also installs the
four JetBrainsMono Nerd Font faces under `~/.local/share/fonts`. WezTerm itself
remains distribution-managed.

Nushell is pinned to 0.114.1 on every platform because its configuration API
changes between releases. Zellij remains pinned to 0.44.1 because later 0.44.x
releases have the reattach regression described below.

Unsupported distribution families stop with an explicit message instead of
guessing a package manager, installing Homebrew, or attempting a source build.

## Starship and zoxide

After each `chezmoi apply`, chezmoi generates version-matched Nushell scripts in:

```text
~/.starship.nu
~/.zoxide.nu
```

Starship and zoxide are sourced explicitly by `config.nu`. Starship is enabled
for local terminals and SSH sessions launched with `wssh`; other SSH clients
use Nushell's default prompt. zoxide remains available in every session.

Open a new Nushell after applying the dotfiles. Validate the integrations with:

```nu
which starship
which zoxide
which z
starship --version
zoxide --version
```

Use `z` for ranked directory navigation:

```nu
z dotfiles
z workspace
```

The interactive `zi` command additionally requires `fzf`.

## Nushell compatibility shortcuts

The shared Nushell configuration includes a conservative compatibility layer
for familiar navigation and Git commands:

```text
l, la, ll       Directory listings
.., ...         Parent directory navigation
g               git
ga              git add
gc              git commit
gd              git diff
gl              Compact graph log
gp              git push
gpl             git pull --rebase
gs              Short branch-aware status
gsw             git switch
cls             clear
md              mkdir
```

Many common commands already exist natively in Nushell, including `ls`, `cp`,
`mv`, `rm`, `mkdir`, `touch`, `ps`, and `kill`. Commands such as Bash/Zsh
`grep`, `find`, `curl`, and `export` are intentionally not aliased because their
Nushell equivalents use structured data and have different semantics:

```nu
ls | where name =~ "pattern"
open data.json | get users
http get https://example.com/api
$env.NAME = "value"
```

## Helix editor

Helix is the default terminal editor and uses the cross-platform command `hx`.
It includes Tree-sitter syntax support, multiple selections, a fuzzy picker,
and an LSP client without requiring an editor plugin framework. Language
servers are separate tools and can be added later for the languages used on a
particular machine.

Start with the interactive tutor, then open a file:

```sh
hx --tutor
hx README.md
```

Essential commands:

```text
i           Enter insert mode
Esc         Return to normal mode
:w          Save
:q          Quit
:wq         Save and quit
Space f     Open the file picker
```

Users who prefer another editor can set `terminalEditor` to `nvim`, `vim`, or
another command during `chezmoi init`; Helix is only the portable default.

## First run

Open WezTerm. It launches Nushell.

### Zellij 0.44 compatibility note

Zellij 0.44.2 and 0.44.3 have a known regression where OSC color-query
responses can leak into shell input when attaching to a session. It appears as
garbled text containing fragments such as `rgb:0808/0808/0808`. The Windows
installer temporarily pins Zellij 0.44.1, which does not have this regression.
Remove the pin after an upstream release containing the fix is available.

Validate:

```nu
version
which wezterm
which zellij
$nu.default-config-dir
$env.ZELLIJ_CONFIG_DIR
```

Enter a Zellij session:

```nu
zj dotfiles
```

Enter or create a development session using the `dev` layout:

```nu
zjd risk
```

List sessions:

```nu
zls
```

## Daily chezmoi workflow

Edit a managed target through chezmoi:

```nu
chezmoi edit ~/.wezterm.lua
chezmoi edit $nu.config-path
```

Inspect and apply:

```nu
chezmoi diff
chezmoi apply
```

Commit:

```nu
chezmoi cd
git status
git add .
git commit -m "chore: update terminal configuration"
git push
exit
```

Update another machine:

```nu
chezmoi update
```

## Machine-specific values

During `chezmoi init`, `.chezmoi.toml.tmpl` presents numbered choices for the
machine role, package setup, proxy behavior, and Zellij startup instead of
ambiguous `true`/`false` questions. Type `1` or `2`; chezmoi accepts the unique
choice immediately without requiring Enter. When the proxy is enabled, its URL
is always shown for confirmation with the saved value as the default. It also
asks for:

- terminal editor
- whether this machine is a graphical workstation or a headless server
- whether chezmoi should install and update the required programs
- terminal proxy URL
- whether the terminal proxy should be enabled by default

Graphical workstations are additionally asked for:

- GUI editor
- preferred font
- font size
- color scheme
- whether WezTerm should start Zellij automatically

Headless servers skip these GUI questions and do not deploy `.wezterm.lua`.
Their GUI editor value falls back to the selected terminal editor.

Re-run initialization questions:

```nu
chezmoi init --prompt
chezmoi apply
```

After Nushell is installed, the equivalent shortcut is:

```nu
cconfigure
capply
```

### PuTTY and limited terminal clients

Some terminal clients can mishandle chezmoi's interactive prompt UI, causing a
single keypress to submit a field. Do not use `init --prompt` in that session.
Machine values are ordinary TOML entries and can be changed directly instead.

For example, to enable dependency installation on a headless Linux server:

```sh
config="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml"
sed -i -E \
  -e 's/^(installPackages[[:space:]]*=[[:space:]]*)false/\1true/' \
  -e 's/^(workstation[[:space:]]*=[[:space:]]*)true/\1false/' \
  "$config"

"$HOME/.local/bin/chezmoi" apply --verbose
```

Review the values before applying:

```sh
grep -E '^(installPackages|workstation)[[:space:]]*=' "$config"
```

## Terminal proxy

The proxy endpoint is stored as machine-specific chezmoi data. The default is:

```text
http://127.0.0.1:7890
```

During initialization, answer `false` to the proxy question if the machine does
not use a network proxy. The proxy URL question will then be skipped.

The proxy is enabled by default for new shells. Toggle it at any time:

```nu
proxy-on
proxy-off
```

`proxy-on` exports uppercase and lowercase HTTP, HTTPS, and ALL proxy variables.
Localhost addresses are excluded through `NO_PROXY` and `no_proxy`.

## Automatic Zellij startup

The default is intentionally `false`.

When enabled, WezTerm starts:

```text
zellij attach main --create
```

This is convenient on a personal workstation, but a plain Nushell startup is
easier to troubleshoot and supports multiple named project sessions naturally.

## Platform-specific Nushell paths

Nushell uses different default configuration directories:

- Linux: `~/.config/nushell`
- macOS: `~/Library/Application Support/nushell`
- Windows: `~/AppData/Roaming/nushell`

chezmoi deploys one shared Nushell template to the correct native path.

Zellij is normalized to `~/.config/zellij` on every platform by setting
`ZELLIJ_CONFIG_DIR` in both WezTerm and Nushell.

## Linux login shell bridge

Linux keeps Bash as the account's system login shell for compatibility with
SSH commands, SCP, and automation. A managed block in `~/.bashrc` replaces only
interactive Bash sessions with Nushell when `nu` is available. This makes PuTTY
and other SSH clients enter the configured Nushell environment without using
`chsh`.

The bridge does not run for non-interactive shells. From Nushell, the managed
`bash` wrapper automatically bypasses the bridge, so switching shells works as
expected:

```nu
bash
bash -l
```

From another POSIX shell, the equivalent explicit bypass is:

```sh
DOTFILES_NO_AUTO_NU=1 bash
```

For an SSH session that preserves the full WezTerm-oriented Starship prompt,
connect from WezTerm with:

```nu
wssh user@host
```

The helper passes an explicit terminal marker because SSH does not forward a
reliable WezTerm identifier by default. PuTTY, Xshell, and ordinary `ssh`
sessions use Nushell's default prompt and continue to load zoxide. Bash fallback
sessions initialize zoxide from the managed `.bashrc` block as well.

The block is maintained with chezmoi's `modify_` mechanism, so existing Bash
configuration outside the marked section is preserved.

## Publishing your own fork

This section is for repository maintainers, not for installing the dotfiles on
a new machine. If this directory is not already a Git repository, publish it
with commands such as:

```sh
git init
git add .
git commit -m "feat: bootstrap terminal dotfiles"
git branch -M main
git remote add origin git@github.com:YOUR_NAME/dotfiles.git
git push -u origin main
```

After publishing, replace the placeholder repository owner in the Bootstrap
examples with the actual GitHub account or organization.
