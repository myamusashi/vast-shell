#!/usr/bin/env bash
#
# Generate the `qs` QML module tree that quickshell normally materialises at
# runtime inside its per-shell vfs build dir.
#
# At runtime quickshell mirrors the shell's Qml/ directory into
# $XDG_RUNTIME_DIR/quickshell/vfs/<id>/qs/ as a proper QML module tree: a
# `module qs.<dotted.path>` qmldir per directory, with the sources symlinked
# in. .qmlls.ini points qmllint at that directory, which is how the developer
# wrapper Assets/shell/qmllint_qs.sh resolves `qs.*` imports.
#
# That directory only exists while a shell instance is running, so CI has to
# build it. This script does the same mirroring without a compositor, which is
# all qmllint needs (it reads the qmldir files and the sources).
#
# Usage: gen-qs-modules.sh <qml-root-dir> <output-dir>
#   Writes <output-dir>/qs/... and prints <output-dir> on stdout.

set -euo pipefail

QML_ROOT="$(cd "${1:?usage: gen-qs-modules.sh <qml-root-dir> <output-dir>}" && pwd)"
OUT_DIR="${2:?usage: gen-qs-modules.sh <qml-root-dir> <output-dir>}"
QS_DIR="${OUT_DIR}/qs"

mkdir -p "${QS_DIR}"
printf 'module qs\n' >"${QS_DIR}/qmldir"

# Every directory holding QML sources becomes a `qs.<dotted.path>` module.
# `LC_ALL=C` + sort keeps the generated tree reproducible across machines.
export LC_ALL=C

while IFS= read -r dir; do
    if [ "${dir}" = "${QML_ROOT}" ]; then
        rel=""
        module="qs"
    else
        rel="${dir#"${QML_ROOT}/"}"
        module="qs.$(printf '%s' "${rel}" | tr '/' '.')"
    fi

    target="${QS_DIR}${rel:+/${rel}}"
    mkdir -p "${target}"

    # A qmldir checked into the source tree wins: it carries declarations
    # (singletons, versions) that cannot be inferred from the file names.
    if [ -f "${dir}/qmldir" ]; then
        ln -sf "${dir}/qmldir" "${target}/qmldir"
    else
        {
            printf 'module %s\n' "${module}"
            # Implicit form qmllint resolves: `Type 1.0 Type.qml`.
            find "${dir}" -maxdepth 1 -type f \( -name '*.qml' -o -name '*.js' \) -printf '%f\n' |
                sort |
                while IFS= read -r file; do
                    printf '%s 1.0 %s\n' "${file%.*}" "${file}"
                done
        } >"${target}/qmldir"
    fi

    find "${dir}" -maxdepth 1 -type f \( -name '*.qml' -o -name '*.js' \) -print0 |
        while IFS= read -r -d '' file; do
            ln -sf "${file}" "${target}/$(basename "${file}")"
        done
done < <(find "${QML_ROOT}" -type d -exec sh -c 'ls -1 "$1"/*.qml >/dev/null 2>&1' _ {} \; -print | sort)

printf '%s\n' "${OUT_DIR}"
