# Testing

[Back to README](../README.md)

## C++ unit tests

```sh
cmake --preset test
cmake --build --preset test
ctest --test-dir build/test --output-on-failure
```

`enable_testing()` is called at the top level only when `VAST_BUILD_TESTS=ON`, since
`add_test()` outside a testing-enabled top level is an error. 28 binaries.

### Verbose output

`VAST_TEST_VERBOSE=ON` (default `OFF`) passes Qt Test's `-v2`, which prints every test
function plus the actual/expected value of each comparison. ctest only displays that
captured output with `-V` or `--output-on-failure`, so a green run stays quiet either way.

```sh
cmake --preset test -DVAST_TEST_VERBOSE=ON
cmake --build --preset test
ctest --test-dir build/test -V
ctest --test-dir build/test -R clipboardmodel -V      # scope to one binary
```

### Suites

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
| `tst_clipboarddatabase` | schema, CRUD, hash dedup, pinned-aware pruning, signals |
| `tst_clipboardmodel` | role names, ordering, fuzzy filter, pin re-sort |
| `tst_clipboardhelpers` | `ClipboardEntry`, classifier, `LoopbackGuard`, preview cache, `htmlToPlainText` |
| `tst_clipboardmanager` | end to end over a seeded database file |
| `tst_imagecacheindex` | `ImageCacheIndex`: file-URL helpers, persistence, load filters |
| `tst_imagecache` | `ImageCache`: `copyAndPreload`, provider cache, `evictKey`, async hop |
| `tst_jobexecutor` | `JobExecutor`: off-thread execution, one worker, ordering, affinity |
| `tst_keylock` | `KeyEventDecoder`'s two evdev modes, QML property contract |
| `tst_lrcparser` | `LrcParser`: LRC and plain-text parsing |
| `tst_lyricscache` | `LyricsCache`: key derivation, envelope, miss conditions |
| `tst_lyricsscheduler` | `LyricsScheduler`: position selection, boundaries, signals |
| `tst_translation` | `TranslationManager`: catalogue load, language switching, failures |
| `tst_colorutils` | `ColorUtils`: OKLab blending, `fromString`, HCT, palette blending |
| `tst_utilsfile` | `Read` / `Write`: round trips and failure paths |
| `tst_paletteanimator` | `PaletteAnimator`: duration, deterministic interpolation |
| `tst_bluetoothagent` | `BluetoothAgentManager` over a private bus: handshake, prompt round trips, re-registration |

### Parity fixtures

`Plugins/Vast/Tests/MaterialColor/data/golden/` holds ten complete 64-role palettes
emitted by the reference Python implementation (`Assets/shell/generate_colors_material.py`):
five source colors × both modes. Each records the `sourceColor` it came from, so a palette
re-derives through `buildPaletteFromColor()` without the source images. The test matches
all 640 role values. `referencePalettesAreThemselvesValid` guards the oracle against goldens
regenerated from a broken build.

`data/quantizer/` holds the five source wallpapers, 512px JPEG, plus
`data/quantizer-golden/manifest.json` with the reference accent for each. The quantizer is
not scale-invariant, so a golden is only valid for the exact bytes it was produced from:
`build_quantizer_fixtures.py` downscales once and derives the goldens from those files.

```sh
nix shell nixpkgs#python3Packages.materialyoucolor nixpkgs#python3Packages.pillow
./Plugins/Vast/Tests/MaterialColor/build_quantizer_fixtures.py [SOURCE_DIR]
```

`data/wallpapers/` holds 20 JPEGs from [wallhaven](https://wallhaven.cc) (SFW, general),
512px wide, about 480 KB. Candidates are selected by a chroma-weighted median-cut hue over
a 6-colour cut, weighted by `population × saturation`; a candidate is rejected when its hue
lands within 11° of an accepted one. The set spans 348.5°, recorded per image in
`manifest.json`. `everyFixtureHasDistinctSourceColor` fails if the quantizer collapses onto
one colour. 512px is above the 128px quantize bitmap, so the Pillow-parity bicubic
downscale stays exercised.

```sh
Plugins/Vast/Tests/MaterialColor/fetch_wallpapers.py   # resumes, adds only what is missing
```

### What the tests assert

`tst_palette` states M3 invariants rather than golden hex values:

- every role in `requiredRoles()` is present, plus the `success*` roles and the
  `*PaletteKeyColor` entries the QML side reads
- every emitted value is a 7-character `#RRGGBB` string
- no surface role is pure `#000000` or `#FFFFFF`
- the five fg/bg pairs the shell paints keep a ≥40 tone gap
- the container ramp is monotonic — ascending in dark, descending in light
- all 9 schemes × both modes × all 20 fixtures validate
- `smart` forces the neutral variant below chroma 20
- `buildPaletteFromColor` and `buildPalette` agree for the same source colour
- the quantizer never falls back to black across `rescaleSize` 32/64/128/256

`tst_colormaterial` covers the wrapper contract: default property values and the idle
state; empty and non-local sources clearing the palette with no error; a missing file
setting `error` exactly once; `sourceColor` staying consistent with `colors()`; a burst of
20 changes coalescing into one `colorsChanged`; an unchanged assignment notifying nothing;
and a result queued before a clear not resurrecting the palette.

Async assertions watch `colorsChanged` rather than polling `ready`, which still holds the
previous result while a rebuild is in flight. The one negative case
(`inFlightResultCannotResurrectClearedState`) uses a fixed drain budget instead, because
it asserts a late result does not arrive.

### Contracts the suites pin

These are behaviours a reader could otherwise get wrong, not bugs:

- **`AudioDevicesModel::setDevices` always resets**; `setProfiles` early-returns on
  `std::ranges::equal`. The devices watcher guards the call with `if (changed)`.
- **`id` is not a key in `AudioDevicesModel`.** The watcher synthesises a
  `<name>.monitor` row per sink carrying the same id, so duplicates stay separate rows.
- **`formatProfileName` output is user-visible text**, rendered through
  `textRole: "readable"` in `Qml/Widgets/AudioProfiles.qml`.
  `"output:stereo+output:surround-51+input:stereo+input:mono"` displays as
  `Stereo + Surround 51 + Stereo + Mono`.
  `"output:stereo++input:mono"` displays as `Stereo +  + Mono` — an empty segment between
  separators survives the join.
- **`formatProfileName` is in `Plugins/Vast/Audio/AudioProfileFormat.hpp`**, not an
  anonymous namespace, so tests can link it.
- **`LyricsScheduler` applies `offsetMs` whether or not playback is running**, so both
  paths resolve the same line at the same position.
- **Unsynced lyrics never highlight**: `rebuildBoundaries` skips words with `time < 0`,
  which is what `parsePlain` emits.
- **The watchers' `connected()` is not asserted.** Both constructors open a real PipeWire
  connection, so a daemon and no daemon are both valid. The tests only pin that the
  QML-facing models exist and start empty, and never call the `create()` singletons, which
  would hold a thread loop open until process exit.
- **`JobExecutor` drops a job still queued at exit** and terminates on a throwing job.
  Both are recorded in its header.
- **`BluetoothAgentManager::active` means registered *and* default.** A registered but
  non-default agent is never asked to handle a pairing, so `RequestDefaultAgent` failure
  leaves `active` false. Nothing reads `active` or `activeChanged` — the only QML surface is
  `busy` and the four completion methods.
- **`mPending` is keyed by device path.** One in-flight prompt per device; a second
  request for the same device gets `org.bluez.Error.Rejected` / "Superseded by a newer
  request" rather than orphaning the first caller.
- **Only a message delivered over a bus can be replied to.** `createReply()` on a
  hand-built `QDBusMessage` aborts libdbus, which is why the agent tests drive the real
  adaptor on a private `dbus-daemon` instead of calling the handlers directly.

### Test seams

Three production accessors exist only so behaviour is testable, and each says so in place:

- `ColorUtils::blendColors` returns its endpoints verbatim below `t=0` and above `t=1`.
- `ImageCacheIndex` takes an optional directory, defaulting to the production one.
  `ImageCache` is default-constructed, so behaviour is unchanged.
- `PaletteAnimator::animation()` exposes the `QVariantAnimation` so the blend is driven
  with `setCurrentTime()` instead of a wall clock.
- `KeyEventDecoder` was extracted from `Keylock::onReadReady`, which otherwise needs a live
  evdev descriptor and notifier. Nothing in `tst_keylock` constructs a `Keylock`.
- `BluetoothAgentManager` takes the bus as a defaulted second constructor argument, so
  `tst_bluetoothagent` can put the agent on its own `dbus-daemon` instead of the system
  bus. The QML singleton takes the default.

`QDBusInterface` was removed from `BluetoothAgentManager` rather than left as a seam: it
blocks in its constructor with a synchronous introspection, and `isValid()` reads stale
when called from inside the owner-changed handler, which is exactly where re-registration
has to work. The three `AgentManager1` calls go out as plain `QDBusMessage`s instead.

`ClipboardPreviewCache` has no injection point and writes to a hardcoded
`/tmp/vast-shell/clipboard-preview`; its tests derive a unique id per test and remove the
file afterwards. Each clipboard test gets its own SQLite file, because
`ClipboardDatabase::close()` leaves the file on disk.

### Layout

Suites are grouped by the module under test. `Plugins/Vast/Tests/CMakeLists.txt` only
dispatches; each subdirectory owns its targets.

```
Plugins/Vast/Tests/
├── CMakeLists.txt                    # find_package(Qt6 Test) + add_subdirectory
├── Audio/                            # Vast.Audio
│   └── tst_audioprofiles.cpp tst_audiocards.cpp tst_audiodevices.cpp
├── Brightness/                       # Vast.Brightness
│   └── tst_brightnessstore.cpp tst_brightnessdisplay.cpp tst_brightnessmanager.cpp
├── Clipboard/                        # Vast.Clipboard
│   └── tst_clipboarddatabase.cpp tst_clipboardmodel.cpp tst_clipboardhelpers.cpp tst_clipboardmanager.cpp
├── ImageCache/                       # Vast.ImageCache
│   └── tst_imagecacheindex.cpp tst_imagecache.cpp
├── Jobs/                             # vast-jobs (static, not a Qml module)
│   └── tst_jobexecutor.cpp
├── Keylock/                          # Vast.Keylock
│   └── tst_keylock.cpp
├── Lyrics/                           # Vast.Lyrics
│   └── tst_lrcparser.cpp tst_lyricscache.cpp tst_lyricsscheduler.cpp
├── MaterialColor/                    # ColorMaterial + vast-materialcolor
│   ├── CMakeLists.txt
│   ├── WallpaperFixtures.{hpp,cpp}   # shared by the two wallpaper suites
│   ├── tst_palette.cpp               # M3 invariants over the wallpapers
│   ├── tst_colormaterial.cpp         # async wrapper
│   ├── tst_spec_parity.cpp           # sourceColor -> 64 roles vs reference
│   ├── tst_quantizer_parity.cpp      # image bytes -> sourceColor vs reference
│   ├── fetch_wallpapers.py           # regenerates data/wallpapers/
│   ├── regenerate_goldens.sh         # regenerates data/golden/
│   ├── build_quantizer_fixtures.py   # regenerates data/quantizer{,-golden}/
│   └── data/
│       ├── wallpapers/               # 20 wallhaven JPEGs + manifest.json
│       ├── golden/                   # reference 64-role palettes
│       ├── quantizer/                # 5 source wallpapers, 512px
│       └── quantizer-golden/         # their reference accent colors
├── Search/                           # vast-core Fuzzy + Vast.Search
│   └── tst_fuzzy.cpp tst_search.cpp
├── Translation/                      # Vast.Translation
│   └── tst_translation.cpp
└── Utils/                            # Vast.Utils
    └── tst_colorutils.cpp tst_utilsfile.cpp tst_paletteanimator.cpp
```

`tst_colormaterial` links the `vast-utils` QML module rather than recompiling
`ColorMaterial.cpp`, so it exercises the shipped class including its `QML_ELEMENT`
registration. `tst_search` links `vast-core` as well as `vast-search`.

## CI

`ci-cpp-test.yml` is the only workflow that compiles the plugin C++ and runs ctest. The
`material-color-utilities` and `fzy` submodules are checked out with `--recursive`; the
plugin does not configure without them.

The job installs Nix with `DeterminateSystems/nix-installer-action` and caches the store
with `magic-nix-cache-action`, matching `ci-flake-update.yml`. It then enters the flake
devShell via `nicknovitski/nix-develop`, so CI builds with the same clang, Qt, pipewire,
ddcutil and mold as a local build — there is no second package list to maintain.

```sh
cmake --preset test -DVAST_TEST_VERBOSE=ON
cmake --build --preset test
QT_QPA_PLATFORM=offscreen ctest --test-dir build/test --output-on-failure --no-tests=error
```

The suites are headless. Eleven binaries link `Qt6::Gui` and use `QTEST_MAIN`, so they
construct a `QGuiApplication` and abort without a platform plugin. The `Clipboard` suite
and `tst_translation` set `QT_QPA_PLATFORM=offscreen` on their own ctest targets;
`ci-cpp-test.yml` exports it for the whole run to cover `MaterialColor` and
`tst_search`, which do not set it. `tst_fuzzy` uses `QTEST_MAIN` but links `Qt6::Core`
alone, so it gets a `QCoreApplication` and needs no display. The remaining 17 binaries
are `QTEST_GUILESS_MAIN`.

`--no-tests=error` matters: ctest exits 0 when it finds no tests, which is the failure mode
where every suite silently stops being built.

`tst_translation` uses `QTEST_MAIN` because `loadTranslation` calls
`QGuiApplication::installTranslator`; its CMake target sets the offscreen platform
itself. Nothing in CI opens a display or reads `/dev/input`: `tst_keylock` does not
construct a `Keylock`, and `tst_brightnessmanager` asserts only the invariant that holds
with or without a backlight device.

`dbus-daemon` must be on `PATH`: `tst_bluetoothagent` spawns its own private bus rather
than touching the system bus, which is what keeps it from registering an agent on a
developer's real bluetoothd. It is a `shell.nix` input, so the devShell CI enters already
has it. If the daemon is missing the suite **fails** under `CI` and skips locally, so a
broken nix input cannot read as a green run with no coverage.

The CI job checks `command -v dbus-daemon` in its own step, before the build, and dumps
`PATH` on failure. `initTestCase` reports which step of the bus setup went wrong --
spawn failure, an unread address, or a refused service registration -- because a bare
"dbus-daemon unavailable" cannot tell those apart.

The daemon is started with a **self-written** `session.conf` and an explicit socket,
not `--session`. `--session` reads whichever `session.conf` the distribution installed,
and in a bare Nix environment there may be none, in which case `dbus-daemon` exits
immediately and silently. Writing the config into a `QTemporaryDir` makes the bus
depend on nothing but the binary.

## Linters

`ci-lint.yml` runs two jobs:

- **clazy + clang-tidy** over the plugins, via the `clazy` CMake preset
  (`VAST_NO_PCH=ON`).
- **qmllint** over `shell.qml` and `greeter.qml` and their import closure, with a coverage
  check that every file under `Qml/` is reachable from one of the two entry points.

`Plugins/Vast/Tests/` is excluded from both the clazy and the clang-tidy target by an
explicit `list(FILTER ... EXCLUDE REGEX "/Plugins/Vast/Tests/")` in
`Plugins/cmake/clazy-lint.cmake` and `Plugins/cmake/tidy-lint.cmake`. The bulk of what
clazy reports on that tree is framework noise — 30 × `ctor-missing-parent-argument`, because
Qt Test instantiates the test class with no parent, and 15 × `detaching-member` — but the
exclusion is not free. Running the project's own check list over the tree also surfaced
compiler warnings the build does not show, including `-Wshorten-64-to-32`
(`tst_imagecache.cpp`) and `-Wimplicit-int-conversion` (`tst_clipboarddatabase.cpp`).
Those are real and currently unchecked.

The test sources are still held to `clang-format`, which `ci-format.yml` enforces via
`Assets/shell/check-format.sh` over all of `Plugins/Vast`.
