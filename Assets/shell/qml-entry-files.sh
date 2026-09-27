#!/usr/bin/env bash

# Print the QML files an entry point can reach, one per line, relative to
# Qml/ and sorted.
#
#   qml-entry-files.sh shell.qml
#   qml-entry-files.sh greeter.qml

set -euo pipefail

ENTRY="${1:?usage: qml-entry-files.sh <entry-point.qml>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QML_ROOT="$(cd "${SCRIPT_DIR}/../../Qml" && pwd)"

if [ ! -f "${QML_ROOT}/${ENTRY}" ]; then
    echo "ERROR: no such entry point: Qml/${ENTRY}" >&2
    exit 1
fi

cd "${QML_ROOT}" || exit 1

declare -A seen=()
queue=("${ENTRY}")
seen["${ENTRY}"]=1

enqueue() {
    local spec="$1" abs rel f r

    [ -n "${spec}" ] || return 0
    case "${spec}" in
        /*) abs="${spec}" ;;                   # absolute
        qs/*) abs="${QML_ROOT}/${spec#qs/}" ;; # module import
        *) abs="${QML_ROOT}/${spec}" ;;        # relative to Qml/
    esac

    # Normalise, and reject anything that lands outside Qml/.
    rel="$(realpath --relative-to="${QML_ROOT}" "${abs}" 2>/dev/null || true)"
    if [ -z "${rel}" ] || [ "${rel}" = ".." ] || [[ "${rel}" == ../* ]]; then
        return 0
    fi
    if [ -d "${QML_ROOT}/${rel}" ]; then
        for f in "${QML_ROOT}/${rel}"/*.qml; do
            [ -e "${f}" ] || continue
            r="${rel}/$(basename "${f}")"
            if [ -z "${seen[${r}]+x}" ]; then
                seen["${r}"]=1
                queue+=("${r}")
            fi
        done
    elif [ -f "${QML_ROOT}/${rel}" ] && [ "${rel}" = "${rel%.qml}.qml" ] && [ "${rel}" != "${ENTRY}" ]; then
        if [ -z "${seen[${rel}]+x}" ]; then
            seen["${rel}"]=1
            queue+=("${rel}")
        fi
    fi
}

while [ "${#queue[@]}" -gt 0 ]; do
    file="${queue[0]}"
    queue=("${queue[@]:1}")

    # Module imports: `import qs.A.B` -> qs/A/B -> Qml/A/B/
    while IFS= read -r mod; do
        [ -n "${mod}" ] || continue
        enqueue "${mod//./\/}"
    done < <(grep -oE '^[[:space:]]*import[[:space:]]+qs\.[A-Za-z0-9_.]+' "${file}" | awk '{print $2}')

    # Relative imports: `import "../Base"` -> resolved against this file's dir
    while IFS= read -r rel; do
        [ -n "${rel}" ] || continue
        enqueue "$(dirname "${file}")/${rel}"
    done < <(grep -oE '^[[:space:]]*import[[:space:]]+"[^"]+"' "${file}" | sed 's/.*"\(.*\)"/\1/')
done

printf '%s\n' "${!seen[@]}" | sort
