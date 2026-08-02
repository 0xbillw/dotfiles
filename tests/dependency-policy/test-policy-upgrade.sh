#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
chezmoi_bin=${CHEZMOI:-chezmoi}

CHECK_CONSUMERS=1 "$script_dir/test-dependency-manifest.sh"

for installer in \
    run_onchange_before_10-install-packages.cmd.tmpl \
    run_onchange_before_10-install-packages-darwin.sh.tmpl \
    run_onchange_before_10-install-packages-linux.sh.tmpl
do
    grep -F '.dependencyPolicy' "$repo_root/$installer" "$repo_root/.chezmoitemplates/dependency-policy-posix.sh.tmpl" >/dev/null 2>&1 || {
        printf '%s\n' "$installer does not consume dependencyPolicy." >&2
        exit 1
    }
done

grep -F 'does not reference declared version' "$script_dir/Test-DependencyManifest.ps1" >/dev/null 2>&1 || {
    printf '%s\n' 'The shared validator does not enforce version-to-artifact parity.' >&2
    exit 1
}

printf '%s\n' 'Rendered installer parity checks passed.'
