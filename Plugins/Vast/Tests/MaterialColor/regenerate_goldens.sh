#!/usr/bin/env bash
# Regenerate Plugins/Vast/Tests/data/golden/ from the reference implementation.
#
# The goldens are full 64-role palettes emitted by
# Assets/shell/generate_colors_material.py (the materialyoucolor port kept in
# repo as the migration reference). tst_spec_parity replays them through
# buildPaletteFromColor() to prove the C++ port still produces the same colors.
#
# Only re-run this when the reference implementation itself changes, and treat
# the resulting diff as the change to review -- never as a way to make a failing
# parity test pass.
#
# Requires materialyoucolor + pillow, e.g.
#   nix shell nixpkgs#python3Packages.materialyoucolor nixpkgs#python3Packages.pillow
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"

GOLDEN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/data/golden"
REFERENCE="$REPO/Assets/shell/generate_colors_material.py"

# Source colors and modes to capture. Each is a distinct hue family so the set
# exercises the neutral/secondary/tertiary derivation, not just one palette.
SOURCES=("#5E83AF" "#4285F4" "#FF1F10" "#944458")
MODES=(dark light)

command -v python3 >/dev/null || { echo "python3 not found" >&2; exit 1; }
python3 -c 'import materialyoucolor, PIL' 2>/dev/null || {
    echo "missing deps: run under 'nix shell nixpkgs#python3Packages.materialyoucolor nixpkgs#python3Packages.pillow'" >&2
    exit 1
}

mkdir -p "$GOLDEN_DIR"
for source in "${SOURCES[@]}"; do
    for mode in "${MODES[@]}"; do
        name="$(echo "$source" | tr -d '#' | tr 'A-Z' 'a-z')_${mode}.json"
        target="$GOLDEN_DIR/$name"
        # --json-out writes the post-fix_surface_extremes/validate_palette
        # palette, which is what the C++ PaletteBuilder returns. The --debug
        # print happens *before* those steps and must not be used here.
        python3 "$REFERENCE" --color "$source" --mode "$mode" \
            --scheme tonal-spot --json-out "$target" >/dev/null
        echo "wrote $(basename "$target")"
    done
done
