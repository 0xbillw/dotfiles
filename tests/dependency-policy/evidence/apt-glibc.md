# apt/glibc evidence

**Status**: Deferred — no Ubuntu 22.04/24.04 host is available in this implementation session.

Run the following on one workstation and one server profile:

```sh
chezmoi apply --verbose
command -v nu zellij hx starship zoxide fzf
nu --version
zellij --version
hx --version
starship --version
zoxide --version
fzf --version
chezmoi apply --verbose
```

The second apply must perform no managed replacement. A workstation must additionally verify the four
font hashes and the Linux WezTerm exception; a server must not stage workstation dependencies.
