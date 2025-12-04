#!/usr/bin/env -S bash
set -euo pipefail

format_file() {
	qmlformat -w 4 -W 360 -i "$1" || {
		echo "Failed: $1" >&2
		return 1
	}
}

export -f format_file

mapfile -t all_files < <(find "${1:-.}" -name "*.qml" -type f)
[ ${#all_files[@]} -eq 0 ] && {
	echo "No QML files found"
	exit 0
}

echo "Formatting ${#all_files[@]} files..."
printf '%s\0' "${all_files[@]}" |
	xargs -0 -P "${QMLFMT_JOBS:-$(nproc)}" -I {} bash -c 'format_file "$@"' _ {} &&
	echo "Done" || {
	echo "Errors occurred" >&2
	exit 1
}
