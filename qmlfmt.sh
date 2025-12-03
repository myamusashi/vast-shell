#!/usr/bin/env bash

# Fungsi untuk backup koma di posisi tertentu
backup_commas() {
    local file="$1"
    # Replace koma dengan placeholder unik yang tidak akan di-format
    sed -i.bak-comma \
        -e 's/,\([[:space:]]*\)$/___COMMA___\1/g' \
        "$file"
}

# Fungsi untuk restore koma
restore_commas() {
    local file="$1"
    sed -i 's/___COMMA___/,/g' "$file"
    rm -f "${file}.bak-comma"
}

find . -name "*.qml" -type f | while read -r file; do
    echo "Formatting: $file"
    
    # Backup koma yang mungkin hilang
    # backup_commas "$file"
    
    # Format dengan qmlfmt
    qmlfmt -t 4 -i 4 -w -b 250 "$file"
    
    # Restore koma
    # restore_commas "$file"
    
    # Fix indentasi if tanpa bracket
    awk '
    /^[[:space:]]*if \(.*\)$/ {
        print
        getline
        if ($0 ~ /^    / || $0 ~ /^\t/) {
            print
        } else if ($0 ~ /^[[:space:]]*$/) {
            print
        } else {
            print "    " $0
        }
        next
    }
    { print }
    ' "$file" > "$file.tmp"
    
    mv "$file.tmp" "$file"
    sed -i "s/pragma ComponentBehavior$/pragma ComponentBehavior: Bound/g" "$file"
done

