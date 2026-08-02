# Windows x86_64 evidence

**Date**: 2026-08-02
**Host**: Windows 11 x86_64 development workstation  
**Status**: Interactive reconciliation completed; policy-upgrade reapply pending

| Dependency | Declared | Active observation |
|---|---:|---|
| Nushell | `0.114.1` | `0.114.1` at `C:\Program Files\nu\bin\nu.exe` |
| Zellij | `0.44.1` | `0.44.1` at `%LOCALAPPDATA%\Zellij\zellij.exe` |
| Helix | `25.07.1` | Missing |
| Starship | `1.26.0` | `1.26.0` observed during interactive reconciliation |
| zoxide | `0.10.0` | `0.10.0` observed during interactive reconciliation |
| fzf | `0.74.1` | Missing |
| WezTerm | `20240203-110809-5046fc22` | Exact at `C:\Program Files\WezTerm\wezterm.exe` |
| JetBrainsMono Nerd Font | `3.4.0` | Four exact user-font hashes; conflicting system installation removed manually |

The four files in `%LOCALAPPDATA%\Microsoft\Windows\Fonts` match the manifest. A previous system-wide
copy with different hashes correctly produced `duplicate-active-path`; the owner removed that copy
through Windows font settings, and the next apply completed.

The initial apply retained Starship 1.26.0 and zoxide 0.10.0 as newer unsupported versions. These
versions are now the declared compatibility targets. Run `chezmoi apply --verbose` again after this
policy update and record an unchanged second apply before marking the target fully verified.
Server-role rendering is covered statically but not applied to this workstation.
