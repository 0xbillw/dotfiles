# Quickstart: Validate Dependency Version Alignment

This document is the implementation and release verification guide. Run only the sections applicable
to the platform under test and record untested cells explicitly.

## 1. Static checks on every change

1. Confirm only one committed version declaration exists for each managed dependency:

   ```powershell
   rg -n "0\.114\.1|0\.44\.1|25\.07\.1|1\.26\.0|0\.10\.0|0\.74\.1|20240203-110809-5046fc22|3\.4\.0" .
   ```

   Expected: authoritative values appear in `.chezmoidata/dependencies.yaml`; documentation may quote
   them, but installer templates do not define independent values.

2. Render each installer for representative workstation and server data. Confirm server output omits
   WezTerm and JetBrainsMono Nerd Font.
3. Run shell/batch syntax checks available on the development platform.
4. Search changed repository content for non-English diagnostics or comments.
5. Validate every target mapping, HTTPS URL, SHA-256, archive member, removal guidance, and exception
   field before real-machine installation.
6. Render unknown OS, manager, architecture, and libc fixtures and verify `target-unsupported` occurs
   before downloads or state writes.

## 2. Required scenario matrix

For each applicable dependency, exercise:

| Fixture | Expected result |
|---|---|
| Missing | Declared version installed and active path verified. |
| Older | Replaced by declared version. |
| Equal | No install or replacement. |
| Newer, choose downgrade | Declared version becomes active. |
| Newer, choose keep | Existing version remains; result unsupported; matching apply does not prompt. |
| Newer after declaration change | Previous retain override ignored; prompt appears again. |
| Newer, choose cancel | No dependency mutation. |
| Newer, non-interactive | Interaction-required result and no mutation. |
| Unavailable artifact/package | All unavailable items reported and no mutation. |
| Wrong architecture/hash | Preflight blocked and no mutation. |
| Duplicate PATH installation | Active competing path reported; unrelated copy untouched. |
| Unknown target tuple | Target-unsupported diagnostic and no network, install, or state mutation. |
| Dependency management disabled | No download, install, or retain-state write; shared configuration still renders. |
| Font with correct family but stale file hashes | Incompatible font result; exact version is not inferred. |
| Runtime failure after a change | Changed/failed/pending report plus safe removal guidance. |
| Second unchanged apply | Zero package or artifact changes. |

## 3. Real-platform coverage

Minimum representative evidence before claiming cross-platform compatibility:

| Platform | Architecture/runtime | Roles |
|---|---|---|
| Windows 11 | x86_64, winget | workstation and server-rendered profile |
| macOS | arm64 and x86_64 where available, Homebrew | workstation and server |
| Ubuntu | x86_64 glibc, apt | workstation and server |
| Fedora/RHEL-family | x86_64 glibc, dnf | server |
| Alpine | x86_64 musl, apk | server |
| Linux arm64 | one supported glibc target and Alpine if available | server |

If a real target is unavailable, record static rendering and the exact deferred manual steps. Do not
mark that target verified.

## 4. Active-version verification

After a successful workstation apply, capture:

```text
nu --version
zellij --version
hx --version
starship --version
zoxide --version
fzf --version
wezterm --version
```

Also capture the resolved executable path for every command (`Get-Command` on Windows, `command -v`
on POSIX), the platform font-discovery result for `JetBrainsMono Nerd Font`, and the SHA-256 of every
actual discovered managed font face. A server result omits WezTerm and the font.

The observed normalized versions must equal the manifest exactly unless a complete approved platform
exception exists. A retained newer version is recorded as unsupported, not passed.

## 5. Upgrade procedure

1. Change one dependency version and all of its target artifact coordinates/checksums in the manifest.
2. Review upstream release notes and configuration compatibility.
3. Confirm every applicable OS/architecture asset exists before any test install.
4. Run the scenario matrix for affected targets and both applicable roles.
5. Update README compatibility and exception information.
6. Commit verification evidence; list deferred real-machine tests explicitly.

## 6. Cleanup and recovery verification

Force a controlled failure after at least one staged change on a disposable machine. Confirm that the
report does not auto-roll back, provides safe removal guidance for each changed item, leaves unrelated
packages and configuration untouched, and that the next apply resumes from its newly observed state.
