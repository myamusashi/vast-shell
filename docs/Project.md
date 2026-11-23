# Project

[Back to README](../README.md)

## Project structure

```text
vast-shell/
├── Qml/                       # Shell UI
│   ├── shell.qml              # Main entry point
│   ├── greeter.qml            # greetd greeter entry point
│   ├── Components/            # Reusable Material 3 components
│   ├── Core/                  # Configs, global state, utilities
│   ├── Greeter/               # Greeter UI
│   ├── Modules/               # Bar, drawers, lock screen, polkit, settings, wallpaper
│   ├── Services/              # Audio, Bluetooth, brightness, capture, weather, and more (ain't write all that)
│   └── Widgets/               # Bar and drawer widgets
├── Plugins/                   # C++ QML modules (see below)
├── vastctl/                   # Go CLI
├── nix/                       # Nix package, plugin derivation and NixOS module
├── Assets/                    # Fonts, images, shaders, helper scripts
├── Data/                      # Default configurations.json and colors
├── packaging/arch/quickshell/ # PKGBUILD
├── translations/              # en_US, id_ID
├── CMakeLists.txt / CMakePresets.json
├── archInstall.sh
└── flake.nix / flake.lock / shell.nix
```

### C++ plugins

Each directory under `Plugins/Vast/` is a QML module with the URI `Vast.<Name>`:

| Module | Provides |
|---|---|
| `Audio` | PipeWire devices, profiles and cards |
| `Brightness` | `BrightnessManager` (ddcutil and sysfs) |
| `Clipboard` | SQLite-backed history, Wayland `ext_data_control_v1` backend |
| `ImageCache` | Persistent image cache |
| `Jobs` | `JobExecutor` thread pool |
| `Keylock` | Caps Lock and Num Lock state (evdev) |
| `Lyrics` | Provider, cache, LRC parser, scheduler |
| `Search` | Fuzzy search, file search, launch history |
| `Translation` | `TranslationManager` |
| `Utils` | `ColorMaterial`, `ColorUtils`, `PaletteAnimator`, Bluetooth pairing agent |
| `MaterialColor` | Static library for color generation (no QML types) |
| `Tests` | Qt Test suites, see [Testing](Testing.md) |

### Vendored dependencies

`Plugins/third_party/` contains three git submodules, each built through a local CMake wrapper:

| Directory | Upstream |
|---|---|
| `material-color-utilities/` | [material-foundation/material-color-utilities](https://github.com/material-foundation/material-color-utilities) |
| `fzy/` | [jhawthorn/fzy](https://github.com/jhawthorn/fzy) |
| `yaml-cpp/` | [jbeder/yaml-cpp](https://github.com/jbeder/yaml-cpp) |

### Material color generation

```text
wallpaper path
  → ColorMaterial       (debounced, off-thread via Vast.Jobs)
  → ImageQuantizer      (Celebi/Score quantizer)
  → MaterialRoles       (about 60 roles, 2021 and 2025 specs)
  → PaletteBuilder / PaletteValidation
  → PaletteAnimator     (OKLab blend, no flicker)
  → M3TemplateColors    → Colours.m3Colors
```

## CI

| Workflow | Runs |
|---|---|
| `ci-test.yml` | C++ tests (`ctest`) and Go tests for `vastctl`. See [Testing](Testing.md). |
| `ci-lint.yml` | clazy and clang-tidy over `Plugins/Vast`, and `qmllint` over `Qml/`. |
| `ci-format.yml` | `clang-format` over `Plugins/Vast` and `qmlformat` over `Qml/`. |
| `ci-archinstall.yml` | `archInstall.sh` end to end. |
| `ci-nix-build.yml` | `nix build .` |
| `ci-cachix.yml` | Builds and pushes the binary cache. |
| `ci-flake-update.yml` | Weekly `nix flake update`. |

### Run the checks locally

```sh
# Format
nix develop -c Assets/shell/check-format.sh

# Lint
cmake --preset clazy && cmake --build --preset clazy
Assets/shell/qmllint_qs.sh

# Tests
cmake --preset test && cmake --build --preset test
ctest --test-dir build/test --output-on-failure
```

`qmllint_qs.sh` needs a module tree to resolve `qs.*` imports. With a shell running, it uses the `Qml/.qmlls.ini` that quickshell writes at startup. Without one, generate the tree first:

```sh
SYSTEM=$(nix eval --impure --raw --expr builtins.currentSystem)
QS_ROOT=$(Assets/shell/gen-qs-modules.sh Qml "$(mktemp -d)")
export QMLLINT_IMPORT_PATHS="${QS_ROOT}:$(nix eval --raw ".#qmllintImportPaths.${SYSTEM}")"
nix build --no-link ".#qmllintModules.${SYSTEM}"
Assets/shell/qmllint_qs.sh
```

Use `nix build` to fetch the modules. `nix-store --realise` does not work here.

## Roadmap

Planned and open to contributions:

- [ ] Warp (Cloudflare) and WireGuard detection
- [ ] Generic VPN status indicator on the network settings page

## Credits

Thanks to everyone in the Quickshell Discord server, especially **@m7moud_el_zayat** for the advice.

Thanks to **@outfoxxed** for [quickshell](https://github.com/quickshell-mirror/quickshell).

Thanks to **[@Soramane](https://github.com/caelestia-dots/shell)** for the inspiration. Many references were taken from your shell, and thanks for the material shapes too.

Also check out [qtengine](https://github.com/kossLAN/qtengine) by **@koss**, a Qt config that doesn't suck.
