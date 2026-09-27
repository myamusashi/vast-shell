#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -n "${QMLLINT_IMPORT_PATHS:-}" ]; then
    ARGS=()
    while IFS= read -r path; do
        ARGS+=("-I" "${path}")
    done < <(printf '%s' "${QMLLINT_IMPORT_PATHS}" | tr ':' '\n' | sed '/^$/d')
else
    INI="${QMLLS_INI:-${ROOT}/Qml/.qmlls.ini}"

    if [ ! -f "${INI}" ]; then
        echo "ERROR: .qmlls.ini not found at ${INI}. Is quickshell running with this checkout?" >&2
        echo "       In CI (or headless), set QMLLINT_IMPORT_PATHS instead — see the header of this script." >&2
        exit 1
    fi
    BUILDDIR=$(grep buildDir "${INI}" | cut -d'"' -f2)

    if [ ! -d "${BUILDDIR}/qs" ]; then
        echo "ERROR: Quickshell buildDir not available. Is qs running?" >&2
        exit 1
    fi

    ARGS=("-I" "${ROOT}/Qml" "-I" "${BUILDDIR}")
    while IFS= read -r path; do
        ARGS+=("-I" "${path}")
    done < <(grep importPaths "${INI}" | cut -d'"' -f2 | tr ':' '\n' | sed '/^$/d')
fi

if [ "$#" -eq 0 ]; then
    cd "${ROOT}" || exit 1
    mapfile -t all_qml < <(find Qml -name '*.qml' | sort)
    set -- "${all_qml[@]}"
fi

exec qmllint "${ARGS[@]}" "$@" 2> >(grep -v 'Two plugins named' >&2)
