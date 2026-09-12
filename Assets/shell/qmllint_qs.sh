#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
INI="${QMLLS_INI:-${ROOT}/Qml/.qmlls.ini}"

if [ ! -f "$INI" ]; then
  echo "ERROR: .qmlls.ini not found at $INI. Is quickshell running with this checkout?" >&2
  exit 1
fi
BUILDDIR=$(grep buildDir "$INI" | cut -d'"' -f2)

if [ ! -d "$BUILDDIR/qs" ]; then
  echo "ERROR: Quickshell buildDir not available. Is qs running?" >&2
  exit 1
fi

IMPORTS=$(grep importPaths "$INI" | cut -d'"' -f2 | tr ':' '\n')

ARGS=("-I" "${ROOT}/Qml" "-I" "$BUILDDIR")
for p in $IMPORTS; do
  ARGS+=("-I" "$p")
done

exec qmllint "${ARGS[@]}" "$@" 2> >(grep -v 'Two plugins named' >&2)
