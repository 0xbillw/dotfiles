# Windows x86_64 evidence

**Date**: 2026-08-01  
**Host**: Windows 11 x86_64 development workstation  
**Status**: Active-state audit completed; reconciliation apply deferred

| Dependency | Declared | Active observation |
|---|---:|---|
| Nushell | `0.114.1` | `0.114.1` at `C:\Program Files\nu\bin\nu.exe` |
| Zellij | `0.44.1` | `0.44.1` at `%LOCALAPPDATA%\Zellij\zellij.exe` |
| Helix | `25.07.1` | Missing |
| Starship | `1.25.1` | Newer `1.26.0` at `C:\Program Files\starship\bin\starship.exe` |
| zoxide | `0.9.9` | Missing |
| fzf | `0.74.1` | Missing |
| WezTerm | `20240203-110809-5046fc22` | Exact at `C:\Program Files\WezTerm\wezterm.exe` |
| JetBrainsMono Nerd Font | `3.4.0` | Four exact user-font hashes plus conflicting system-font copies |

The four files in `%LOCALAPPDATA%\Microsoft\Windows\Fonts` match the manifest. Files with the same
names under `%WINDIR%\Fonts` have different hashes, so the installer now reports
`duplicate-active-path` and blocks before mutation rather than guessing which font WezTerm selects.

The actual reconciliation apply is deferred because it would ask whether to downgrade Starship and
would install missing tools. The owner must run interactive `chezmoi apply --verbose`, resolve the
duplicate font installations in Windows Fonts settings, and record a second unchanged apply before
this target is marked fully verified. Server-role rendering is covered statically but not applied to
this workstation.
