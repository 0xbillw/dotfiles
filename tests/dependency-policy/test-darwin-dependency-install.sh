#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
installer="$repo_root/run_onchange_before_10-install-packages-darwin.sh.tmpl"
common="$repo_root/.chezmoitemplates/dependency-policy-posix.sh.tmpl"
combined="$installer $common"

require_pattern() {
    pattern=$1
    scenario=$2
    grep -F "$pattern" $combined >/dev/null 2>&1 || {
        printf '%s\n' "macOS dependency fixture '$scenario' is not implemented (missing $pattern)." >&2
        exit 1
    }
}

require_pattern '.dependencyPolicy.dependencies' manifest-consumer
require_pattern DOTFILES_DEPENDENCY_TEST isolated-fixture-mode
require_pattern target-unsupported unknown-target
require_pattern preflight-blocked unavailable-and-bad-hash
require_pattern installedFiles font-file-identity
require_pattern 'dependency management is disabled' disabled-management
require_pattern already-compatible matching-and-second-apply
require_pattern duplicate-active-path duplicate-path
require_pattern workstation-only workstation-server-filter

printf '%s\n' 'macOS dependency install fixture contract is present.'
