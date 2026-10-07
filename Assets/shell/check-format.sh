#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
IGNORE="${SCRIPT_DIR}/qmlformat-ignore.txt"

cd "${ROOT}" || exit 1

status=0

CLANG_FORMAT="${CLANG_FORMAT:-clang-format}"
if [ -z "${QMLFORMAT:-}" ]; then
    if command -v qmlformat-rs >/dev/null 2>&1; then
        QMLFORMAT=qmlformat-rs
    else
        QMLFORMAT=qmlformat
    fi
fi
echo "qmlformat command: ${QMLFORMAT}"


mapfile -t cpp_files < <(find Plugins/Vast -type f \( -name '*.cpp' -o -name '*.hpp' \) | sort)

echo "::group::clang-format (${#cpp_files[@]} files)"
if [ "${#cpp_files[@]}" -gt 0 ] && ! "${CLANG_FORMAT}" --dry-run --Werror "${cpp_files[@]}"; then
    echo "clang-format: the files above are not formatted. Run 'clang-format -i' on them."
    status=1
fi
echo "::endgroup::"

mapfile -t excluded < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' "${IGNORE}" | grep -v '^$')
mapfile -t qml_files < <(
    find Qml -name '*.qml' | sort |
        if [ "${#excluded[@]}" -gt 0 ]; then
            grep -vxF -f <(printf '%s\n' "${excluded[@]}")
        else
            cat
        fi
)

echo "::group::qmlformat (${#qml_files[@]} files, ${#excluded[@]} excluded)"

scratch=$(mktemp -d)
trap 'rm -rf "${scratch}"' EXIT

qml_status=0
for file in "${qml_files[@]}"; do
    if "${QMLFORMAT}" "${file}" 2>"${scratch}/err" | diff -q "${file}" - >/dev/null 2>&1; then
        continue
    fi
    if [ -s "${scratch}/err" ]; then
        echo "${file}: qmlformat failed"
        sed 's/^/    /' "${scratch}/err"
    else
        echo "${file}: not formatted"
    fi
    qml_status=1
done

if [ "${qml_status}" -ne 0 ]; then
    echo "qmlformat: the files above are not formatted. Run 'qmlformat -i' on them."
    echo "If qmlformat cannot parse a file at all, add it to Assets/shell/qmlformat-ignore.txt with a reason."
    status=1
fi
echo "::endgroup::"

exit "${status}"
