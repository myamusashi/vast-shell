#!/usr/bin/env bash

set -u

search_dirs="${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:/run/current-system/sw/share:/nix/var/nix/profiles/default/share"

declare -A seen_sessions=()

IFS=':' read -ra dirs <<< "${search_dirs}"
for base_dir in "${dirs[@]}"; do
    [ -z "${base_dir}" ] && continue
    for subdir in wayland-sessions xsessions; do
        session_dir="${base_dir}/${subdir}"
        [ -d "${session_dir}" ] || continue

        session_type="wayland"
        if [ "${subdir}" = "xsessions" ]; then
            session_type="x11"
        fi

        while IFS= read -r file; do
            [ -f "${file}" ] || continue

            session_id="$(basename "${file}" .desktop)"
            dedupe_key="${session_type}:${session_id}"
            if [ -n "${seen_sessions[${dedupe_key}]+x}" ]; then
                continue
            fi

            hidden="$(grep -m1 '^Hidden=' "${file}" | cut -d= -f2- | tr '[:upper:]' '[:lower:]')"
            no_display="$(grep -m1 '^NoDisplay=' "${file}" | cut -d= -f2- | tr '[:upper:]' '[:lower:]')"
            if [ "${hidden}" = "true" ] || [ "${no_display}" = "true" ]; then
                continue
            fi

            try_exec="$(grep -m1 '^TryExec=' "${file}" | cut -d= -f2-)"
            if [ -n "${try_exec}" ]; then
                if ! [ -x "${try_exec}" ] && ! command -v "${try_exec}" >/dev/null 2>&1; then
                    continue
                fi
            fi

            name="$(grep -m1 '^Name=' "${file}" | cut -d= -f2-)"
            raw_exec="$(grep -m1 '^Exec=' "${file}" | cut -d= -f2-)"
            exec_cmd="$(printf '%s' "${raw_exec}" | sed -E 's/(^|[[:space:]])%[fFuUdDnNickvm]($|[[:space:]])/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//')"
            desktop_names="$(grep -m1 '^DesktopNames=' "${file}" | cut -d= -f2- | tr ';' ':' | sed -E 's/:+/:/g; s/^://; s/:$//')"

            if [ -n "${name}" ] && [ -n "${exec_cmd}" ]; then
                seen_sessions["${dedupe_key}"]=1
                printf '%s|||%s|||%s|||%s|||%s\n' "${name}" "${exec_cmd}" "${session_type}" "${desktop_names}" "${session_id}"
            fi
        done < <(find "${session_dir}" -maxdepth 1 -name '*.desktop' 2>/dev/null | sort)
    done
done
