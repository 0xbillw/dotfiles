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
| Linux | CLI stack; GUI/font packages are distribution-specific | CLI stack | apt plus official binaries (Ubuntu 22.04/24.04) |

On Linux graphical workstations, WezTerm and the Nerd Font are installed with
the distribution's preferred package mechanism; the shared terminal and shell
configuration remains the same.

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
  init --apply YOUR_NAME
```

For a private repository:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- \
  -b "$HOME/.local/bin" \
  init --apply git@github.com:YOUR_NAME/dotfiles.git
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
  the Nerd Font. A Linux workstation automates the CLI stack and leaves the GUI
  and font packages to the distribution.
- A **remote/headless server** installs Nushell, Zellij, Helix, Starship,
  zoxide, and fzf. WezTerm and fonts belong on the local computer displaying
  the SSH session, not on the server.

Windows uses `winget` and macOS uses Homebrew. Linux deliberately does not use
Homebrew: the automatic installer currently targets Ubuntu 22.04 and 24.04,
uses apt for system packages and project-documented repositories, and downloads
official prebuilt binaries only where Ubuntu LTS has no suitable package. It
does not compile the Rust tools from source.

The managed programs are:

- WezTerm
- Nushell
- Zellij
- Helix
- Starship
- zoxide
- fzf (used by `zi`)
- A Nerd Font, preferably JetBrainsMono Nerd Font

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
brew install nushell helix zellij starship zoxide
```

### Windows

```powershell
winget install wez.wezterm
winget install Nushell.Nushell
winget install Helix.Helix
winget install Starship.Starship
winget install ajeetdsouza.zoxide
winget install Zellij.Zellij
winget install junegunn.fzf
winget install DEVCOM.JetBrainsMonoNerdFont
```

### Ubuntu 22.04/24.04

For the automatic flow, answer `true` to package management during `chezmoi
init`. The installer uses Ubuntu apt, the Nushell apt repository documented by
the Nushell project, and the Helix PPA documented by Helix. Starship, zoxide,
and the pinned compatible Zellij release are installed as official prebuilt
binaries under `~/.local/bin`. A Linux graphical workstation still needs
WezTerm and the Nerd Font from its distribution because GUI/font packaging
differs between distributions.

Other Linux distributions currently stop with an explicit unsupported-platform
message instead of installing Homebrew or attempting a source build.

## Starship and zoxide

After each `chezmoi apply`, chezmoi generates version-matched Nushell scripts in:

```text
$nu.data-dir/vendor/autoload/starship.nu
~/.zoxide.nu
```

Starship is loaded through Nushell's vendor autoload directory. zoxide follows
its official integration method and is sourced explicitly by `config.nu`.

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

During `chezmoi init`, `.chezmoi.toml.tmpl` asks for:

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

The bridge does not run for non-interactive shells. To deliberately open an
interactive Bash session without being redirected back to Nushell, use:

```sh
DOTFILES_NO_AUTO_NU=1 bash
```

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
