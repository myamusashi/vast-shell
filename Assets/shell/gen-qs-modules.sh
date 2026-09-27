#!/usr/bin/env bash

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
    elif [ -z "${rel}" ]; then
        printf 'module qs\n' >"${target}/qmldir"
    else
        {
            printf 'module %s\n' "${module}"
            # `pragma Singleton` has to surface in the qmldir, otherwise qmllint
            # resolves the type but loses every member declared on it.
            find "${dir}" -maxdepth 1 -type f \( -name '*.qml' -o -name '*.js' \) -printf '%f\n' |
                sort |
                while IFS= read -r file; do
                    if ! grep -qE '^[[:space:]]*pragma[[:space:]]+Singleton[[:space:]]*$' "${dir}/${file}"; then
                        # Plain .js helpers are imported by path, not as types.
                        case "${file}" in
                            *.js) continue ;;
                        esac
                        printf '%s 1.0 %s\n' "${file%.*}" "${file}"
                        continue
                    fi
                    printf 'singleton %s 1.0 %s\n' "${file%.*}" "${file}"
                done
        } >"${target}/qmldir"
    fi

    find "${dir}" -maxdepth 1 -type f \( -name '*.qml' -o -name '*.js' \) -print0 |
        while IFS= read -r -d '' file; do
            ln -sf "${file}" "${target}/$(basename "${file}")"
        done
done < <(find "${QML_ROOT}" -type d -exec sh -c 'ls -1 "$1"/*.qml >/dev/null 2>&1' _ {} \; -print | sort)

printf '%s\n' "${OUT_DIR}"
