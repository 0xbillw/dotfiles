# macOS evidence

**Status**: Deferred — no macOS x86_64 or arm64 host is available in this implementation session.

Required verification on each available architecture:

```sh
chezmoi apply --verbose
command -v nu zellij hx starship zoxide fzf wezterm
nu --version
zellij --version
hx --version
starship --version
zoxide --version
fzf --version
wezterm --version
chezmoi apply --verbose
```

Run once with workstation data and once with server data. The workstation must verify the four font
file hashes; the server must omit WezTerm and fonts. Record machine/OS/architecture, command paths,
both apply logs, and whether any target remains deferred.
