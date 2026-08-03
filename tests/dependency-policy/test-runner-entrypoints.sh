#!/bin/sh
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
runner="$script_dir/run-all.sh"
[ -f "$runner" ] || { printf '%s\n' 'POSIX aggregate runner is missing.' >&2; exit 1; }
for expected in test-dependency-manifest.sh test-policy-upgrade.sh test-darwin-dependency-install.sh test-linux-dependency-install.sh test-posix-reconciliation.sh
do
    grep -F "$expected" "$runner" >/dev/null || { printf '%s\n' "POSIX inventory omits $expected." >&2; exit 1; }
done
grep -F 'Dependency policy suite passed:' "$runner" >/dev/null
grep -F 'DEPENDENCY_POLICY_TEST_DIRECTORY' "$runner" >/dev/null
grep -F 'chezmoi apply' "$runner" >/dev/null
grep -F 'CHECK_CONSUMERS=1 sh "$script_dir/test-dependency-manifest.sh"' \
    "$script_dir/test-policy-upgrade.sh" >/dev/null || {
    printf '%s\n' 'Nested POSIX tests must use an explicit sh interpreter.' >&2
    exit 1
}
temporary=${TMPDIR:-/tmp}/dotfiles-runner-$$
mkdir -p "$temporary"
output=${TMPDIR:-/tmp}/dotfiles-runner-output-$$
trap 'rm -rf "$temporary"; rm -f "$output"' EXIT HUP INT TERM
if DEPENDENCY_POLICY_TEST_DIRECTORY="$temporary" DEPENDENCY_POLICY_SKIP_QUALITY=1 sh "$runner" >"$output" 2>&1; then
    printf '%s\n' 'POSIX runner accepted a missing inventory file.' >&2
    exit 1
fi
grep -F 'Missing expected test' "$output" >/dev/null
printf '%s\n' 'POSIX aggregate runner contract passed.'
