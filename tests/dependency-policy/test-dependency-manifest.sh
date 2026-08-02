#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
chezmoi_bin=${CHEZMOI:-chezmoi}

fail() {
    printf '%s\n' "Dependency policy validation failed: $*" >&2
    exit 1
}

command -v "$chezmoi_bin" >/dev/null 2>&1 || fail "chezmoi was not found; set CHEZMOI."

summary=$(
    "$chezmoi_bin" -S "$repo_root" execute-template \
        '{{ .dependencyPolicy.schema }}|{{ len .dependencyPolicy.dependencies }}|{{ len .dependencyPolicy.supportedTargets }}'
)
[ "$summary" = "1|8|7" ] || fail "unexpected schema/dependency/target counts: $summary"

records=$(
    "$chezmoi_bin" -S "$repo_root" execute-template \
        '{{ range $id, $dep := .dependencyPolicy.dependencies }}{{ $id }}|{{ $dep.version }}|{{ len $dep.targets }}|{{ len $dep.roles }}{{ "\n" }}{{ end }}'
)
printf '%s\n' "$records" | while IFS='|' read -r id version targets roles; do
    [ -n "$id" ] || continue
    [ -n "$version" ] || fail "$id has no version."
    [ "$targets" -eq 7 ] || fail "$id does not cover seven targets."
    [ "$roles" -gt 0 ] || fail "$id has no role."
done

target_records=$(
    "$chezmoi_bin" -S "$repo_root" execute-template \
        '{{ range $id, $dep := .dependencyPolicy.dependencies }}{{ range $targetName, $target := $dep.targets }}{{ $id }}|{{ $dep.version }}|{{ $targetName }}|{{ $target.strategy }}|{{ index $target "url" | default "" }}|{{ index $target "packageVersion" | default "" }}{{ "\n" }}{{ end }}{{ end }}'
)
printf '%s\n' "$target_records" | while IFS='|' read -r id version target strategy url package_version; do
    case "$strategy" in
        official-artifact)
            case "$url" in *"$version"*) ;; *) fail "$id/$target URL does not reference declared version $version." ;; esac
            ;;
        native-package)
            case "$package_version" in *"$version"*) ;; *) fail "$id/$target package version does not reference declared version $version." ;; esac
            ;;
    esac
done

if [ "${CHECK_CONSUMERS:-0}" = 1 ]; then
    versions=$(
        "$chezmoi_bin" -S "$repo_root" execute-template \
            '{{ range $dep := .dependencyPolicy.dependencies }}{{ $dep.version }}{{ "\n" }}{{ end }}'
    )
    for installer in \
        run_onchange_before_10-install-packages.cmd.tmpl \
        run_onchange_before_10-install-packages-darwin.sh.tmpl \
        run_onchange_before_10-install-packages-linux.sh.tmpl
    do
        printf '%s\n' "$versions" | while IFS= read -r version; do
            [ -n "$version" ] || continue
            if grep -F "$version" "$repo_root/$installer" >/dev/null 2>&1; then
                fail "$installer duplicates managed version $version."
            fi
        done
    done
fi

printf '%s\n' 'Dependency manifest valid: 8 dependencies, 7 targets.'
