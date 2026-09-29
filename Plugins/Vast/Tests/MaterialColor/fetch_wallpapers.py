#!/usr/bin/env python3
"""Fetch ColorMaterial test wallpapers and pick well-separated dominant hues.

Selection matters: the palette tests assert that 20 different wallpapers yield
20 visibly different palettes, so a fixture set clustered in one hue corner
would let a regression in hue/chroma handling pass unnoticed.

Pipeline per candidate: download the `large` thumb, compute a
chroma-weighted median-cut hue, reject it when it sits closer than
MIN_HUE_GAP to an already-accepted hue, then downscale to 512px wide JPEG.
The 512px width is deliberate: it is still larger than the 128px quantize
bitmap, so the bicubic downscale path in ImageQuantizer is exercised, while
the whole set stays small enough to commit.

Resumable and idempotent: already-downloaded JPEGs are re-hued from disk and
kept, and the final step renumbers every file into manifest order so the
on-disk names always match manifest.json.

Usage:
    ./fetch_wallpapers.py [OUT_DIR] [COUNT]

Requires network access on first run; later runs are offline.
"""
import colorsys
import io
import json
import os
import sys
import urllib.request
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "data", "wallpapers")
WANT = int(sys.argv[2]) if len(sys.argv) > 2 else 20

MIN_HUE_GAP = 11.0      # degrees, minimum pairwise separation
MIN_HUE_SPREAD = 300.0  # degrees, largest gap-free arc covering all hues
MAX_WIDTH = 512         # committed JPEG width
JPEG_QUALITY = 85

API = ("https://wallhaven.cc/api/v1/search?categories=111&purity=100"
       "&sorting=random&atleast=1600x900&page={}")
UA = {"User-Agent": "vast-shell-test-fixtures/1.0"}


def fetch(url, timeout=60):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return response.read()


def dominant_hue(image):
    """Chroma-weighted hue centroid over a 6-colour median cut.

    Weighting each cluster by (population * saturation) keeps a large
    desaturated background from outvoting a small saturated accent, which a
    plain most-common-pixel pick would do on most wallpapers.
    """
    small = image.convert("RGB").resize((64, 64), Image.BICUBIC)
    cut = small.quantize(colors=6, method=Image.MEDIANCUT)
    clusters = sorted(cut.getcolors(), reverse=True)
    palette = cut.getpalette()
    total = sum(count for count, _ in clusters)

    hue_sum = weight_sum = 0.0
    for count, index in clusters:
        red, green, blue = palette[index * 3:index * 3 + 3]
        hue, sat, _ = colorsys.rgb_to_hsv(red / 255, green / 255, blue / 255)
        weight = (count / total) * sat
        hue_sum += hue * weight
        weight_sum += weight
    if weight_sum <= 1e-6:
        return None
    return (hue_sum / weight_sum) % 1.0 * 360.0


def hue_gap(a, b):
    delta = abs(a - b) % 360.0
    return min(delta, 360.0 - delta)


def hue_spread(hues):
    """Widest gap-free arc containing every hue, found per anchor hue."""
    best = 0.0
    for anchor in hues:
        offsets = [(hue - anchor) % 360.0 for hue in hues]
        best = max(best, max(offsets) - min(offsets))
    return best


def is_separated(hue, hues):
    return all(hue_gap(hue, other) >= MIN_HUE_GAP for other in hues)


def wallhaven_id(filename):
    return filename.split("-", 1)[1].rsplit(".", 1)[0]


def collect_existing():
    """Re-hue whatever is already downloaded, dropping any now too close."""
    kept = []
    for name in sorted(os.listdir(OUT)):
        if not name.lower().endswith(".jpg"):
            continue
        path = os.path.join(OUT, name)
        hue = dominant_hue(Image.open(path))
        if hue is None or not is_separated(hue, [k["hue"] for k in kept]):
            os.remove(path)
            continue
        kept.append({"id": wallhaven_id(name), "file": name, "hue": hue,
                     "source": f"https://wallhaven.cc/w/{wallhaven_id(name)}"})
    return kept


def download_more(kept):
    hues = [k["hue"] for k in kept]
    seen = {k["id"] for k in kept}
    page = 1
    while len(kept) < WANT and page <= 25:
        try:
            data = json.loads(fetch(API.format(page)))
        except Exception as error:  # noqa: BLE001 - transient network, keep going
            print(f"api fail page={page}: {error}", file=sys.stderr)
            page += 1
            continue
        for entry in data.get("data", []):
            if len(kept) >= WANT:
                break
            wid = entry["id"]
            if wid in seen:
                continue
            seen.add(wid)
            try:
                image = Image.open(io.BytesIO(fetch(entry["thumbs"]["large"])))
                image = image.convert("RGB")
            except Exception as error:  # noqa: BLE001 - skip bad candidate
                print(f"dl fail {wid}: {error}", file=sys.stderr)
                continue
            hue = dominant_hue(image)
            if hue is None or not is_separated(hue, hues):
                continue
            width, height = image.size
            if width > MAX_WIDTH:
                image = image.resize(
                    (MAX_WIDTH, max(1, round(height * MAX_WIDTH / width))),
                    Image.LANCZOS)
            name = f"{len(kept):02d}-{wid}.jpg"
            image.save(os.path.join(OUT, name), "JPEG", quality=JPEG_QUALITY,
                       optimize=True)
            hues.append(hue)
            kept.append({"id": wid, "file": name, "hue": hue,
                         "source": entry["short_url"]})
            print(f"[{len(kept):2d}/{WANT}] {wid} hue={hue:6.1f} "
                  f"spread={hue_spread(hues):5.1f} "
                  f"{os.path.getsize(os.path.join(OUT, name)) // 1024}KB",
                  flush=True)
        page += 1
    return kept


def renumber(kept):
    """Rename into manifest order so on-disk names match manifest.json.

    A resumed run appends past whatever index it happens to reach, which can
    collide with an existing prefix or leave holes; the index is derived data
    and carries no meaning beyond ordering.
    """
    for old, image in zip(sorted(os.listdir(OUT)), kept):
        if not old.lower().endswith(".jpg"):
            continue
        new = f"{kept.index(image):02d}-{image['id']}.jpg"
        if old != new:
            os.rename(os.path.join(OUT, old), os.path.join(OUT, new))
            image["file"] = new


def main():
    os.makedirs(OUT, exist_ok=True)
    kept = collect_existing()
    if len(kept) < WANT:
        kept = download_more(kept)

    renumber(kept)
    spread = hue_spread([k["hue"] for k in kept])
    if len(kept) < WANT or spread < MIN_HUE_SPREAD:
        print(f"INSUFFICIENT: {len(kept)} images, spread={spread:.1f}",
              file=sys.stderr)
        return 1

    for image in kept:
        image["hue"] = round(image["hue"], 2)
    with open(os.path.join(OUT, "manifest.json"), "w") as handle:
        json.dump({"count": len(kept), "hueSpreadDegrees": round(spread, 1),
                   "minPairwiseHueGap": MIN_HUE_GAP, "maxWidth": MAX_WIDTH,
                   "images": kept}, handle, indent=2)
        handle.write("\n")
    print(f"OK {len(kept)} images, hue spread {spread:.1f} deg")
    return 0


sys.exit(main())
