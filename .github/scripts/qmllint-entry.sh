#!/usr/bin/env bash

# qmllint one entry point's closure. Used by the qmllint job in
# ci-lint.yml, once per entry point.
#
#   qmllint-entry.sh <entry-point.qml> <file-list>

set -euo pipefail

ENTRY="${1:?usage: qmllint-entry.sh <entry-point.qml> <file-list>}"
FILE_LIST="${2:?usage: qmllint-entry.sh <entry-point.qml> <file-list>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "${ROOT}"

count=$(wc -l <"${FILE_LIST}")
echo "::group::qmllint ${ENTRY} (${count} files)"

SYSTEM=$(nix eval --impure --raw --expr builtins.currentSystem)
QS_ROOT=$(Assets/shell/gen-qs-modules.sh Qml "${RUNNER_TEMP}/qs-modules")
IMPORTS=$(nix eval --raw ".#qmllintImportPaths.${SYSTEM}")
export QMLLINT_IMPORT_PATHS="${QS_ROOT}:${IMPORTS}"

nix build --no-link ".#qmllintModules.${SYSTEM}"

missing=0
while IFS= read -r path; do
    if [ ! -d "${path}" ]; then
        echo "::error::module root missing: ${path}"
        missing=1
    fi
done < <(tr ':' '\n' <<<"${QMLLINT_IMPORT_PATHS}")
[ "${missing}" -eq 0 ]

# qmllint comes from the devShell, so the import roots this script sets up are
# the only thing it has to supply.
status=0
# qml-entry-files.sh prints Qml/-relative paths; qmllint needs them relative to
# the repo root, because that is how it resolves a file's qs.* module against
# the import roots.
mapfile -t files < "${FILE_LIST}"
set -- "${files[@]/#/Qml/}"
Assets/shell/qmllint_qs.sh "$@" || status=$?

if [ "${status}" -ne 0 ]; then
    echo "::error::qmllint failed for ${ENTRY} (${count} files)"
fi
echo "::endgroup::"
exit "${status}"
