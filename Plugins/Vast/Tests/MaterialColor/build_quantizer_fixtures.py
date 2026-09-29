#!/usr/bin/env python3
"""Build the quantizer-parity fixtures and their goldens.

Why the fixtures are downscaled
-------------------------------
The quantizer is not scale-invariant: reducing an image before it reaches
Celebi changes which color wins. Measured on the originals, a 512px downscale
moves nord's accent from #5E83AF to #6083AD and redsamurai's from #FF1F10 to
#FF1F0F. The C++ port reproduces Python exactly at *any* scale, but the golden
source colors are only valid for the exact bytes they were produced from.

So the images are downscaled once here, and the goldens are generated from
those downscaled files. Everything downstream -- fixture, golden, and test --
refers to the same bytes.

512px is still comfortably above the 128px quantize bitmap, so the Pillow /
QImage bicubic downscale path stays under test.

Usage:
    ./build_quantizer_fixtures.py [SOURCE_DIR]

Needs materialyoucolor + pillow for the golden step; without them the images
are still written and the script reports what it skipped.
"""
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
OUT_DIR = os.path.join(HERE, "data", "quantizer")
GOLDEN_DIR = os.path.join(HERE, "data", "quantizer-golden")
REFERENCE = os.path.join(REPO, "Assets", "shell", "generate_colors_material.py")

WIDTH = 512
JPEG_QUALITY = 92

# The five images the reference palettes in data/golden/ were generated from.
SOURCES = ["nord", "pulp-fiction", "redsamurai", "sunset-cat",
           "wallhaven-p966oj_2560x1440"]


def deps_available():
    try:
        import materialyoucolor  # noqa: F401
        import PIL  # noqa: F401
    except ImportError:
        return False
    return True


def main():
    source_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Pictures/wallpapers")
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(GOLDEN_DIR, exist_ok=True)

    have_deps = deps_available()
    if not have_deps:
        print("materialyoucolor/pillow unavailable: writing images only, skipping goldens",
              file=sys.stderr)

    manifest = {}
    for name in SOURCES:
        src = os.path.join(source_dir, f"{name}.png")
        if not os.path.exists(src):
            print(f"missing source: {src}", file=sys.stderr)
            return 1

        from PIL import Image
        image = Image.open(src).convert("RGB")
        width, height = image.size
        resized = image.resize((WIDTH, max(1, round(height * WIDTH / width))), Image.LANCZOS)
        dest = os.path.join(OUT_DIR, f"{name}.jpg")
        resized.save(dest, "JPEG", quality=JPEG_QUALITY, optimize=True)

        entry = {"file": os.path.basename(dest), "source": name,
                 "originalSize": [width, height], "width": WIDTH,
                 "sourceColor": None}

        if have_deps:
            out = os.path.join(GOLDEN_DIR, f"{name}.json")
            subprocess.run([sys.executable, REFERENCE, "--path", dest, "--mode", "dark",
                            "--scheme", "tonal-spot", "--json-out", out],
                           check=True, capture_output=True)
            colors = json.load(open(out))["colors"]
            entry["sourceColor"] = colors["sourceColor"]
            os.remove(out)

        manifest[name] = entry
        print(f"{name:<38} {os.path.getsize(dest) // 1024:>4}KB  "
              f"accent={entry['sourceColor']}")

    with open(os.path.join(GOLDEN_DIR, "manifest.json"), "w") as handle:
        json.dump(manifest, handle, indent=2)
        handle.write("\n")
    return 0


sys.exit(main())
