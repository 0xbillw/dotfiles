# dnf and apk evidence

**Status**: Deferred — no representative dnf/glibc or apk/musl host is available in this session.

Run the active-path/version and second-apply commands from `apt-glibc.md` on one supported dnf server
and one Alpine server. Also record:

```sh
. /etc/os-release
printf 'ID=%s ID_LIKE=%s VERSION_ID=%s\n' "$ID" "${ID_LIKE:-}" "$VERSION_ID"
uname -m
```

The Alpine check must confirm whether exact native package `helix=25.07.1-r0` remains available. If it
is unavailable, preflight must report the item and make no managed dependency changes; do not mark the
target verified or substitute another package version.
