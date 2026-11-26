#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

QUICKSHELL_BIN="${VAST_QUICKSHELL_BIN:-quickshell}"
GREETER_QML="${VAST_GREETER_QML:-${ROOT}/Qml/greeter.qml}"

"${QUICKSHELL_BIN}" -p "${GREETER_QML}"
qs_status=$?

if [ -n "${VAST_GREETER_EXIT_CMD:-}" ]; then
    sh -c "${VAST_GREETER_EXIT_CMD}" || true
elif [ -n "${MANGO_INSTANCE_SIGNATURE:-}" ] && command -v mmsg >/dev/null 2>&1; then
    mmsg dispatch quit || true
elif [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
    hypr_out="$(hyprctl dispatch "hl.dsp.exit()" 2>&1)"
    hypr_rc=$?
    if [ "${hypr_rc}" -ne 0 ] || printf '%s' "${hypr_out}" | grep -qiE 'invalid|error|unknown'; then
        hyprctl dispatch exit || true
    fi
elif [ -n "${SWAYSOCK:-}" ] && command -v swaymsg >/dev/null 2>&1; then
    swaymsg exit || true
elif [ -n "${NIRI_SOCKET:-}" ] && command -v niri >/dev/null 2>&1; then
    niri msg action quit --skip-confirmation || true
elif [ -n "${LABWC_PID:-}" ]; then
    if command -v labwc >/dev/null 2>&1; then
        labwc --exit || kill -TERM "${LABWC_PID}" 2>/dev/null || true
    else
        kill -TERM "${LABWC_PID}" 2>/dev/null || true
    fi
else
    parent_comm=""
    if [ "${PPID:-1}" -gt 1 ] && command -v ps >/dev/null 2>&1; then
        parent_comm="$(ps -o comm= -p "${PPID}" 2>/dev/null | tr -d '[:space:]')"
    fi

    if [ "${parent_comm}" = "river" ] && command -v riverctl >/dev/null 2>&1; then
        riverctl exit || true
    elif [ "${PPID:-1}" -gt 1 ]; then
        case "${parent_comm}" in
            "" | sh | bash | dash | zsh | systemd | init) ;;
            *) kill -TERM "${PPID}" 2>/dev/null || true ;;
        esac
    fi
fi

exit "${qs_status}"
