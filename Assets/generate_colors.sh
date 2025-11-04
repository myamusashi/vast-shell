#!/usr/bin/env bash

usage() {
    echo "Usage: $0 <qml-file>"
    exit 1
}

if [ $# -eq 0 ]; then
    usage
fi

QML_FILE="$1"

if [ ! -f "$QML_FILE" ]; then
    echo "Error: File '$QML_FILE' not found"
    exit 1
fi

NEW_COLORS=$(matugen image "$(shell ipc call img get)" -t scheme-tonal-spot -j hex | jq '.colors.dark')

if [ -z "$NEW_COLORS" ] || [ "$NEW_COLORS" = "null" ]; then
    echo "Error: generate colors from matugen"
    exit 1
fi

BACKUP_FILE="${QML_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$QML_FILE" "$BACKUP_FILE"

TEMP_SED_SCRIPT=$(mktemp)

echo "$NEW_COLORS" | jq -r '
to_entries[] | 
"s/\\(component ColorsComponent:.*\\n\\([[:space:]]*readonly property color " + .key + ":[[:space:]]*\\)\\)\"[^\"]*\"/\\1\"" + .value + "\"/g"
' > "$TEMP_SED_SCRIPT"

echo "$NEW_COLORS" | jq -r '
to_entries[] | 
"/component ColorsComponent:/,/^[[:space:]]*}[[:space:]]*$/ s/\\(readonly property color " + .key + ":[[:space:]]*\\)\"[^\"]*\"/\\1\"" + .value + "\"/g"
' > "$TEMP_SED_SCRIPT"

if sed -f "$TEMP_SED_SCRIPT" -i "$QML_FILE"; then
    echo "0"
    
    
    if grep -A 100 "component ColorsComponent:" "$QML_FILE" | grep -B 100 "^[[:space:]]*}[[:space:]]*$" | head -n -1 | grep "readonly property color" | head -5; then
        echo "✓"
    else
        echo "⚠ Warning: Could not verify color updates"
    fi
    
else
    echo "Error: Failed to update colors, backup"
    # Restore backup on failure
    mv "$BACKUP_FILE" "$QML_FILE"
    exit 1
fi

rm -f "$TEMP_SED_SCRIPT"
rm -f "$BACKUP_FILE"
echo -e "\n0"
