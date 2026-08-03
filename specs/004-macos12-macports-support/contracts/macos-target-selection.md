# Contract: macOS Target Selection

## Purpose

The macOS dependency installer must classify the host before dependency preflight so Monterey receives the
legacy MacPorts-aware path and newer macOS releases keep their existing behavior.

## Inputs

- macOS product version.
- Machine architecture.
- Machine role selected during chezmoi initialization.
- Dependency-management enabled/disabled choice.
- Presence and discoverability of the MacPorts `port` command when the selected source requires MacPorts.

## Ordered behavior

1. If dependency management is disabled, exit successfully before package-manager checks, network access,
   installation, or state writes.
2. Detect macOS major version and CPU architecture.
3. If the major version is `12`, classify the target as Monterey legacy macOS and set the package-management
   path to MacPorts-aware.
4. If the major version is newer and already supported by the repository, retain the existing macOS path.
5. If the architecture is not `x86_64` or `aarch64`, return `target-unsupported` before mutation.
6. Apply workstation/server role filtering before resolving dependency sources.
7. When at least one selected source requires MacPorts, validate `port` availability before preflight.
8. Return a structured diagnostic that includes macOS release category, architecture, role, selected package
   path, and next action whenever target selection blocks setup.

## Result classes

| Result | Meaning | Mutation allowed |
|---|---|---|
| `target-selected` | A supported macOS target and role were selected. | Not yet; proceed to preflight |
| `disabled` | Dependency management is disabled. | No mutation; successful exit |
| `prerequisite-blocked` | Monterey selected a MacPorts-required path but `port` is missing, hidden, or unusable. | No |
| `target-unsupported` | macOS version or architecture has no declared handling. | No |

## Safety invariants

- Do not use Homebrew as an implicit fallback on Monterey.
- Do not route newer macOS releases into the Monterey path by accident.
- Do not mutate dependencies or machine-local state until target selection and prerequisites succeed.
- Do not install MacPorts automatically; provide documented user action instead.
