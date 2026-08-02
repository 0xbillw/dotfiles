#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
installer="$repo_root/run_onchange_before_10-install-packages-linux.sh.tmpl"
common="$repo_root/.chezmoitemplates/dependency-policy-posix.sh.tmpl"
combined="$installer $common"

require_pattern() {
    pattern=$1
    scenario=$2
    grep -F "$pattern" $combined >/dev/null 2>&1 || {
        printf '%s\n' "Linux dependency fixture '$scenario' is not implemented (missing $pattern)." >&2
        exit 1
    }
}

require_pattern '.dependencyPolicy.dependencies' manifest-consumer
require_pattern DOTFILES_DEPENDENCY_TEST isolated-fixture-mode
require_pattern target-unsupported unknown-os-arch-libc
require_pattern preflight-blocked unavailable-wrong-architecture-and-bad-hash
require_pattern installedFiles font-file-identity
require_pattern 'dependency management is disabled' disabled-management
require_pattern already-compatible matching-and-second-apply
require_pattern duplicate-active-path duplicate-path
require_pattern workstation-only workstation-server-filter
require_pattern 'package_family=apt' apt-family
require_pattern 'package_family=dnf' dnf-family
require_pattern 'package_family=apk' apk-family

printf '%s\n' 'Linux dependency install fixture contract is present.'
