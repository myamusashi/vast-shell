# Testing

[Back to README](../README.md)

## Run the tests

```sh
cmake --preset test
cmake --build --preset test
ctest --test-dir build/test --output-on-failure
```

Tests live in `Plugins/Vast/Tests/`, grouped by the module they cover. Each subdirectory owns its own targets.

For per-test output, enable verbose mode and run a single suite with `-R`:

```sh
cmake --preset test -DVAST_TEST_VERBOSE=ON
cmake --build --preset test
ctest --test-dir build/test -R clipboardmodel -V
```

`tst_bluetoothagent` starts its own private D-Bus and needs `dbus-daemon` on `PATH`. If it is missing, the suite is skipped locally and fails in CI.

## Suites

| Target | Covers |
|---|---|
| `tst_palette` | M3 invariants over 20 wallpaper fixtures |
| `tst_colormaterial` | `ColorMaterial` wrapper: debounce, errors, generation guard |
| `tst_spec_parity` | `sourceColor` → 64 roles against the reference palettes |
| `tst_quantizer_parity` | image bytes → `sourceColor` against the reference accents |
| `tst_fuzzy` | `FuzzyCore`, `FuzzyMatcher` |
| `tst_search` | `SearchEngine`, `LaunchHistoryStore`, `FileSearchModel`, `DirectoryWalker` |
| `tst_audioprofiles` | `AudioProfilesModel`, `formatProfileName` |
| `tst_audiocards` | `AudioCard`, `AudioCardsModel`, watcher construct/destroy |
| `tst_audiodevices` | `AudioDevicesModel`, monitor linkage |
| `tst_brightnessstore` | `BrightnessProfileStore` |
| `tst_brightnessdisplay` | `DisplayWorker` coalescing, `clampPercent`, backlight I/O |
| `tst_brightnessmanager` | `BrightnessManager` without hardware |
| `tst_clipboarddatabase` | Schema, CRUD, hash dedup, pinned-aware pruning, signals |
| `tst_clipboardmodel` | Role names, ordering, fuzzy filter, pin re-sort |
| `tst_clipboardhelpers` | `ClipboardEntry`, classifier, `LoopbackGuard`, preview cache, `htmlToPlainText` |
| `tst_clipboardmanager` | End to end over a seeded database file |
| `tst_imagecacheindex` | `ImageCacheIndex`: file-URL helpers, persistence, load filters |
| `tst_imagecache` | `ImageCache`: `copyAndPreload`, provider cache, `evictKey`, async hop |
| `tst_jobexecutor` | `JobExecutor`: off-thread execution, ordering, affinity |
| `tst_keylock` | `KeyEventDecoder` evdev modes, QML property contract |
| `tst_lrcparser` | `LrcParser`: LRC and plain-text parsing |
| `tst_lyricscache` | `LyricsCache`: key derivation, envelope, miss conditions |
| `tst_lyricsscheduler` | `LyricsScheduler`: position selection, boundaries, signals |
| `tst_translation` | `TranslationManager`: catalogue load, language switching, failures |
| `tst_colorutils` | `ColorUtils`: OKLab blending, `fromString`, HCT, palette blending |
| `tst_utilsfile` | `Read` / `Write`: round trips and failure paths |
| `tst_paletteanimator` | `PaletteAnimator`: duration, deterministic interpolation |
| `tst_bluetoothagent` | `BluetoothAgentManager` over a private bus: handshake, prompts, re-registration |

## Color fixtures

The color suites use fixtures under `Plugins/Vast/Tests/MaterialColor/data/`:

| Directory | Contents |
|---|---|
| `wallpapers/` | 20 wallhaven JPEGs (512px) with a `manifest.json` |
| `golden/` | Reference 64-role palettes from `Assets/shell/generate_colors_material.py` |
| `quantizer/` | 5 source wallpapers (512px) |
| `quantizer-golden/` | Reference accent color for each quantizer wallpaper |

Regenerate them with:

```sh
# Wallpapers (resumes, only adds what is missing)
Plugins/Vast/Tests/MaterialColor/fetch_wallpapers.py

# Quantizer wallpapers and goldens
nix shell nixpkgs#python3Packages.materialyoucolor nixpkgs#python3Packages.pillow
./Plugins/Vast/Tests/MaterialColor/build_quantizer_fixtures.py [SOURCE_DIR]

# Palette goldens
Plugins/Vast/Tests/MaterialColor/regenerate_goldens.sh
```

A quantizer golden is only valid for the exact image bytes it was made from, so always regenerate the images and goldens together.

## CI

`ci-test.yml` runs two parallel jobs:

- `cpp-test` builds the plugins and runs `ctest`.
- `go-test` runs `gofmt`, `go vet`, build and tests for `vastctl`.

Submodules must be checked out with `--recursive`. To reproduce the C++ job locally:

```sh
cmake --preset test -DVAST_TEST_VERBOSE=ON
cmake --build --preset test
QT_QPA_PLATFORM=offscreen ctest --test-dir build/test --output-on-failure --no-tests=error
```

## Linters

`ci-lint.yml` runs two jobs:

- **clazy + clang-tidy** over the plugins, via the `clazy` preset.
- **qmllint** over `shell.qml`, `greeter.qml` and everything they import.

`Plugins/Vast/Tests/` is excluded from clazy and clang-tidy but is still checked by `clang-format` (`ci-format.yml`).
