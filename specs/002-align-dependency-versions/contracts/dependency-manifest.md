# Contract: Dependency Compatibility Manifest

## Location and ownership

`.chezmoidata/dependencies.yaml` is the sole authoritative declaration. Installer templates may render
its values but must not contain independent managed version literals.

## Required shape

```yaml
dependencyPolicy:
  schema: 1
  dependencies:
    <dependency-id>:
      displayName: <English name>
      version: <exact version>
      kind: executable | font
      roles: [server, workstation]
      installOrder: <integer>
      versionProbe:                 # executable only
        args: [<argument>]
        parser: <named parser>
      fontProbe:                    # font only
        family: <family name>
        styles: [<style>]
      targets:
        <target-key>:
          strategy: native-package | official-artifact
          package: { manager: <manager>, id: <id>, version: <exact expression> }
          artifact:
            url: <official HTTPS URL>
            sha256: <64 lowercase hex characters>
            archive: zip | tar.gz | tar.xz | raw
            members: [<required member>]
          installedFiles:           # font target only
            <installed filename>: <64 lowercase hex SHA-256>
          installLocation: <declared location class>
          removeGuidance: { command: <safe template> }
          # or removeGuidance: { documentation: <official HTTPS URL> }
          exception:                # omitted normally
            reason: <text>
            scope: <exact target selector>
            compatibleVersion: <exact version or bounded range>
            evidence: [<URL>]
            removalCondition: <objective condition>
```

Target keys must normalize OS, package-manager family, architecture, and libc where relevant. Role is
handled by dependency applicability unless a target artifact itself differs by role.

## Static validity rules

1. The manifest contains exactly the managed dependency IDs: `nushell`, `zellij`, `helix`, `starship`,
   `zoxide`, `fzf`, `wezterm`, and `jetbrainsmono-nerd-font`.
2. Each dependency has a non-empty exact version and unique install order.
3. Every applicable supported target resolves to exactly one strategy or a complete exception.
4. Artifact URLs use HTTPS and official upstream hosts; every artifact has SHA-256 and required member
   declarations.
5. A native-package entry includes an exact-version expression, not `latest` or an open range.
6. Every entry provides safe removal guidance or an official documentation reference.
7. Every font target declares each installed face and the SHA-256 expected from that exact package or
   artifact source; artifact-based targets require both archive and installed-file hashes.
8. WezTerm and JetBrainsMono Nerd Font apply only to `workstation`.
9. Exception records contain all five required fields and never silently alter the base version.

Any violation is a release-blocking error and must be found before an installer mutates a machine.

## Consumer contract

- Platform scripts select only the current target and role from this manifest.
- Version and URL values may not be shadowed by platform-local constants.
- A manifest version change invalidates the corresponding retain override automatically.
- Maintainer documentation and reported version tables are rendered or copied from this declaration.
- Font consumers must resolve the installed files backing the declared family/styles and compare their
  hashes with the selected target resolution; discovering the expected family name is not sufficient.
