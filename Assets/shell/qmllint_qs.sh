#!/usr/bin/env bash
#
# CI has no running shell and therefore no .qmlls.ini. Set
# QMLLINT_IMPORT_PATHS to a colon-separated list of module roots to bypass
# .qmlls.ini entirely; the list must include a `qs` root, which
# Assets/shell/gen-qs-modules.sh produces:
#
#   QS_ROOT=$(Assets/shell/gen-qs-modules.sh Qml "$(mktemp -d)")
#   export QMLLINT_IMPORT_PATHS="${QS_ROOT}:$(nix eval --raw .#qmllintImportPaths.x86_64-linux)"
#   Assets/shell/qmllint_qs.sh
#
# With no file arguments the whole Qml/ tree is linted.

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
    mapfile -t -O "$#" all_qml < <(find "${ROOT}/Qml" -name '*.qml' | sort)
    set -- "${all_qml[@]}"
fi

exec qmllint "${ARGS[@]}" "$@" 2> >(grep -v 'Two plugins named' >&2)
