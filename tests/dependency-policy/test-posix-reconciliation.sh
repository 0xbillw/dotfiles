#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
policy="$repo_root/.chezmoitemplates/dependency-policy-posix.sh.tmpl"
integration="$repo_root/run_after_generate-nushell-integrations.sh.tmpl"

require_pattern() {
    file=$1
    pattern=$2
    scenario=$3
    grep -F "$pattern" "$file" >/dev/null 2>&1 || {
        printf '%s\n' "POSIX reconciliation '$scenario' is not implemented (missing $pattern)." >&2
        exit 1
    }
}

require_pattern "$policy" downgrade newer-downgrade
require_pattern "$policy" retain-unsupported newer-retain
require_pattern "$policy" cancelled newer-cancel
require_pattern "$policy" interaction-required newer-non-interactive
require_pattern "$policy" declaredVersion retain-declaration-key
require_pattern "$policy" observedVersion retain-observed-version
require_pattern "$policy" 'Invalid choice' invalid-input-retry
require_pattern "$policy" 'Changed:' partial-failure-changed
require_pattern "$policy" 'Failed:' partial-failure-failed
require_pattern "$policy" 'Pending:' partial-failure-pending
require_pattern "$policy" removeGuidance safe-removal-guidance
require_pattern "$policy" duplicate-active-path unrelated-installation-preservation
require_pattern "$integration" retain-unsupported retained-integration-generation

printf '%s\n' 'POSIX reconciliation fixture contract is present.'
