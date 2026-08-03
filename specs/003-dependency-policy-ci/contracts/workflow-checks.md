# Contract: Workflow Checks

## Required checks

The workflow publishes stable, unique results:

```text
dependency-policy / Windows x86_64
dependency-policy / Linux x86_64
dependency-policy / macOS arm64
dependency-policy / macOS x86_64
dependency-policy / Release assets and repository quality
```

Repository branch protection can require these exact names after the workflow has run once on the
default branch.

## Trigger contract

- Pull requests targeting the default branch run all required checks without secrets.
- Pushes to the default branch run all required checks.
- Maintainers can request the workflow manually.
- A newer run for the same pull request cancels an older in-progress run.
- Each job has a 15-minute maximum duration.

## Permission contract

The workflow has read-only access to repository contents. It does not request write authority, release
authority, package authority, identity tokens, or repository secrets. Untrusted pull requests never use
a privileged target-branch event or persistent self-hosted runner.

## Result contract

A required job succeeds only when environment setup and its full committed entrypoint succeed. A
cancelled, timed-out, skipped, or failed required job is not merge-ready. Optional future smoke jobs
use different names and never impersonate required static checks.
