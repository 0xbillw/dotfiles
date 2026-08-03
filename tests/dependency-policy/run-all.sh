#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=${1:-$(CDPATH= cd -- "$script_dir/../.." && pwd)}
base_ref=${2:-}
test_dir=${DEPENDENCY_POLICY_TEST_DIRECTORY:-$script_dir}

# Safety boundary: this static and contract suite never invokes production chezmoi apply.
inventory='test-dependency-manifest.sh
test-policy-upgrade.sh
test-darwin-dependency-install.sh
test-linux-dependency-install.sh
test-posix-reconciliation.sh'

printf '%s\n' "$inventory" | while IFS= read -r name
do
    [ -f "$test_dir/$name" ] || { printf '%s\n' "Missing expected test: $name" >&2; exit 1; }
done

passed=0
printf '%s\n' "$inventory" | while IFS= read -r name
do
    printf '%s\n' "==> $test_dir/$name"
    REPOSITORY_ROOT="$repo_root" sh "$test_dir/$name"
done
passed=5

if [ "${DEPENDENCY_POLICY_SKIP_QUALITY:-0}" != 1 ]; then
    printf '%s\n' '==> repository quality checks'
    git -C "$repo_root" diff --check
    if [ -n "$base_ref" ]; then
        git -C "$repo_root" rev-parse --verify "$base_ref" >/dev/null
        git -C "$repo_root" diff --check "$base_ref"
        if git -C "$repo_root" diff --unified=0 "$base_ref" -- . \
            ':(exclude)*.png' ':(exclude)*.jpg' ':(exclude)*.zip' |
            awk '/^\+[^+]/{ if ($0 ~ /[^\001-\177]/) { print; found=1 } } END { exit found ? 0 : 1 }' >"${TMPDIR:-/tmp}/dotfiles-non-english-$$"
        then
            cat "${TMPDIR:-/tmp}/dotfiles-non-english-$$" >&2
            rm -f "${TMPDIR:-/tmp}/dotfiles-non-english-$$"
            printf '%s\n' 'Non-English added lines detected.' >&2
            exit 1
        fi
        rm -f "${TMPDIR:-/tmp}/dotfiles-non-english-$$"
    else
        printf '%s\n' 'Changed-line checks skipped: no base revision supplied.'
    fi

    chezmoi_bin=${CHEZMOI:-chezmoi}
    "$chezmoi_bin" -S "$repo_root" managed | while IFS= read -r target
    do
        normalized=$(printf '%s' "$target" | tr '\\' '/' | sed 's|^\./||')
        case "$normalized" in
            .agents|.agents/*|.specify|.specify/*|specs|specs/*|tests|tests/*)
                printf '%s\n' "Development path is managed: $target" >&2
                exit 1
                ;;
        esac
    done
    sh -n "$0"
fi

printf '%s\n' "Dependency policy suite passed: $passed tests."
printf '%s\n' 'Evidence: static/contract only; no clean-install claim.'
