# dnf and apk evidence

**Status**: DNF/glibc received a basic manual smoke test; the version-upgrade reapply and apk/musl
target remain deferred.

No issue was observed during a basic apply on a DNF-based system before the Starship 1.26.0 and
zoxide 0.10.0 policy promotion. Re-run the active-path/version and second-apply commands from
`apt-glibc.md` after this upgrade. Run the same commands on one Alpine server. Also record:

```sh
. /etc/os-release
printf 'ID=%s ID_LIKE=%s VERSION_ID=%s\n' "$ID" "${ID_LIKE:-}" "$VERSION_ID"
uname -m
```

The Alpine check must confirm whether exact native package `helix=25.07.1-r0` remains available. If it
is unavailable, preflight must report the item and make no managed dependency changes; do not mark the
target verified or substitute another package version.
