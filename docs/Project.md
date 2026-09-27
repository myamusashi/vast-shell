# Project

[Back to README](../README.md)

## Project Structure

```
vast-shell/
├── CMakeLists.txt / CMakePresets.json   # C++ plugin build (Ninja + clang + mold)
├── archInstall.sh                       # Arch installer
├── flake.nix / flake.lock / shell.nix
│
├── vastctl/                             # Go CLI companion
│   ├── main.go
│   ├── go.mod / go.sum
│   ├── cmd/                    # audio, brightness, capture, carapace, clipboard,
│   │                           # color, completion, daemon, dragAndDrop, helpers,
│   │                           # hypr, idle, keylock, lock, log, mpris, record,
│   │                           # root, toast, volume, wallpaper
│   └── internal/
│       ├── hypr/dispatch.go    # hyprctl wrapper (global shortcuts)
│       ├── ipc/client.go       # shell ipc call client + daemon launcher
│       └── pretty/tree.go      # JSON -> tree renderer
│
├── nix/
│   ├── default.nix
│   ├── nixos-modules.nix
│   ├── packages/               # app2unit, material-symbols, remove-bg, vastctl
│   └── plugins/
│       └── vastPlugin.nix      # C++ plugin derivation
│
│
├── Qml/
│   ├── shell.qml              # main entry point
│   ├── greeter.qml            # greetd greeter entry point
│   ├── Components/
│   │   ├── Base/              # CAnim, Circular, Corner, CornerPair, Cornery,
│   │   │                      # ElevatedCharging, Elevation, FocusCage, M3TemplateColors,
│   │   │                      # NAnim, StateLayer, StyledRect, StyledSlide, StyledSwitch,
│   │   │                      # StyledText, StyledTextInput, TabNavigator, Wallpaper, Wavy,
│   │   │                      # BluetoothDeviceDelegate, KdeDeviceRow
│   │   │   ├── NavigationRail/   # NavigationRail, NavigationRailItem, RailBadge
│   │   │   └── TextInputComponents/ # PasswordInput, VisibleInput
│   │   ├── Button/            # ConnectedButtonGroup, ExtendedFloatingButton,
│   │   │                      # FloatingButton, SplitButton
│   │   ├── Menu/              # ContextMenu, DropdownField, DropdownMenu, MenuDivider,
│   │   │                      # MenuItem, MenuSurface, MenuTransitions, PopupPlacement,
│   │   │                      # TrayMenu, TrayMenuItem
│   │   ├── Dialog/            # ConfirmDialog, DialogBox, WifiPskDialog
│   │   │   └── FileDialog/    # FileDialog + components/{BottomActionBar, FileListView,
│   │   │                      # PlacesSidebar, TopAppBar} + delegate/{FileListItem, PlaceItem}
│   │   ├── Effects/           # BlendColor
│   │   ├── Feedback/          # BorderProgress, DynamicIsland, IslandHost,
│   │   │                      # LoadingIndicator, Progress, Toast
│   │   ├── Popup/             # Header, ZoomPopup
│   │   └── Volume/            # Pulse, VerticalVolumeControl
│   │
│   ├── Core/
│   │   ├── Configs/           # Configs (loader) + one *Config per JSON section:
│   │   │                      # Appearance, Audio, Bar, CaptureScreenVideo, Clipboard,
│   │   │                      # ColorSystem, General, Idle, KDEConnect, Localization,
│   │   │                      # MediaPlayer, Notification, PrivacyIndicator, Search,
│   │   │                      # Wallpaper, Weather
│   │   ├── States/            # GlobalStates (IPC handlers, OSD, panels),
│   │   │                      # OSDManager, PanelManager, Workspaces
│   │   └── Utils/             # AqiScale, CelestialProgress, DebouncedValue, Distro,
│   │                          # Dots, FileListMetrics, Fonts, FormatTimeUtils,
│   │                          # HighlightText, Icon, IconUtils, MArea, MediaKind,
│   │                          # ModelAdapter, Paths, ScreenSelection, Time, VolumeUtils,
│   │                          # WeatherIcon, WifiUtils
│   │
│   ├── Greeter/               # Auth, GreetConfigs, Surface, UserCard
│   │
│   ├── Modules/
│   │   ├── BluetoothAgent/    # PairingDialog (in-shell BlueZ agent UI)
│   │   ├── DragAndDrop/       # DragAndDrop, ConfirmDeviceContent, DeviceListContent,
│   │   │                      # DoneContent, DragAndDropIslandContent, DraggingContent,
│   │   │                      # FilesDroppedContent, ProgressContent
│   │   ├── Privacy/           # Privacy, PrivacyIslandContent
│   │   ├── Drawers/           # Drawers (root)
│   │   │   ├── Bar/           # Bar, Left, Middle, Right
│   │   │   ├── Brightness/    # BrightnessOsd, SegmentBar
│   │   │   ├── Calendar/
│   │   │   ├── CaptureScreenVideo/ # AudioDeviceItem, PageAudio, PageHistory, PageMain,
│   │   │   │                      # PageSettings, CaptureScreenVideo (drawer)
│   │   │   ├── Clipboard/     # Clipboard, Content, Delegate, EntryGrid, Preview, SearchBar
│   │   │   ├── Launcher/      # Launcher, LauncherRow
│   │   │   ├── Notifications/ # Notifications, Components/{Content, NotifIcon, Wrapper}
│   │   │   ├── OSD/           # OSD, LockIndicator
│   │   │   ├── QuickSettings/ # QuickSettings, BluetoothList, Performances,
│   │   │   │                  # StatusCard, VolumeSettings, PerformancePages/Popup/*,
│   │   │   │                  # Settings/{Bluetooth, Wifi, *}
│   │   │   ├── Session/
│   │   │   ├── Volume/
│   │   │   ├── WallpaperSelector/
│   │   │   └── Weather/       # Weathers, Headers, WeatherItem/*
│   │   ├── Lock/              # Bar, BottomItem, CapsLockPopup, Clock, Lockscreen,
│   │   │                      # MediaPlayer, Pam, Surface
│   │   ├── Polkit/            # Polkit, Body, Header
│   │   ├── Settings/
│   │   │   ├── Components/    # CardRevealer, SettingRow, SettingsCard,
│   │   │   │                  # SettingsPageBase, SettingsSearchField
│   │   │   └── Pages/         # Appearance, Bar, Bluetooth, CaptureScreenVideo, Clipboard,
│   │   │                      # General, Greeter, Idle, Internet, KDEConnect, Language,
│   │   │                      # Lockscreen (+ Lockscreen/DepthWallpaperSection),
│   │   │                      # MediaPlayer, Notification, PrivacyNodes, Volume (+ tabs),
│   │   │                      # Wallpaper, Weather
│   │   └── Wallpaper/         # Wall
│   │
│   ├── Services/              # Audio, AudioRestore, AuthFlow, Battery,
│   │                          # BluetoothDeviceFormatter, BluetoothDeviceIndex,
│   │                          # BluetoothServices, Brightness, CaptureNotify,
│   │                          # CaptureSaver, ClipboardServices, Colours,
│   │                          # DepthWallpaperController, DragAndDropServices,
│   │                          # DynamicIslandService, Fontlist, GreeterWallpaper,
│   │                          # HolidayModel, Hotspot, Hypr, Hyprsunset, KDEConnect,
│   │                          # KeylockState, LauncherServices, Lyrics, Notifs,
│   │                          # Players, PolAgent, PrivacyServices, ScreenCapture,
│   │                          # ScreenCaptureHistory, SystemInfoFormatter, SystemUsage,
│   │                          # ThumbnailQueue, ToastService, TrackArt, TransferController,
│   │                          # Volume, Wallpaper, WallpaperFileModels, Weather,
│   │                          # WeatherFormatter, captureUtils.js
│   │   ├── CaptureScreenImage/ # CaptureScreenImage, PanelScreenshot
│   │   ├── CaptureScreenVideo/ # CaptureScreenVideo
│   │   └── Weather/           # weatherData.js
│   │
│   └── Widgets/               # AudioProfiles, Battery, Clock, KdeConnect, LyricsView,
│                              # MixerEntry, Mpris, NotificationDots, OsText, Privacy,
│                              # RecordIndicator, Sound, Tray, WorkspaceName,
│                              # WorkspacePreview, Workspaces, YearMonthPicker
│
├── Plugins/                   # C++ QML modules, URI per directory under the Vast namespace
│   ├── cmake/                 # qml-module.cmake (vast_module() helper), pch.cmake,
│   │                          # clazy-lint.cmake, tidy-lint.cmake
│   ├── third_party/           # vendored dependencies (see below)
│   └── Vast/
│       ├── CMakeLists.txt     # core module (URI Vast), shared FuzzyCore/FuzzyMatcher
│       ├── Audio/             # Vast.Audio       — AudioCard(sModel), AudioDevicesModel/Watcher,
│       │                      #                   AudioProfilesModel/Watcher
│       ├── Brightness/        # Vast.Brightness  — BrightnessManager, BrightnessProfileStore
│       ├── Clipboard/         # Vast.Clipboard   — ClipboardContentClassifier, ClipboardDatabase,
│       │   │                  #                   ClipboardManager, ClipboardModel,
│       │   │                  #                   ClipboardPreviewCache, LoopbackGuard,
│       │   │                  #                   WaylandDataControl
│       │   └── protocols/     # ext-data-control-v1.xml
│       ├── ImageCache/        # Vast.ImageCache  — ImageCache, ImageCacheIndex
│       ├── Jobs/              # Vast.Jobs        — JobExecutor (thread pool)
│       ├── Keylock/           # Vast.Keylock     — KeylockState, KeyboardDeviceScanner
│       ├── Lyrics/            # Vast.Lyrics      — LyricsProvider, LyricsCache,
│       │                      #                   LrcParser, LyricsScheduler
│       ├── MaterialColor/     # static lib vast-materialcolor — ImageQuantizer, MaterialRoles,
│       │                      #                   MaterialTemperatureCache, PaletteBuilder,
│       │                      #                   PaletteValidation (no QML types)
│       ├── Search/            # Vast.Search      — SearchEngine, FileSearchModel,
│       │                      #                   DirectoryWalker, LaunchHistoryStore
│       ├── Translation/       # Vast.Translation — TranslationManager
│       └── Utils/             # Vast.Utils       — ColorMaterial, ColorPreview, ColorUtils,
│                              #                   PaletteAnimator, BluetoothAgentManager,
│                              #                   BluetoothAgentAdaptor
│
├── Assets/
│   ├── images/                # image_not_found.svg, kuru.gif, wallpaper.png,
│   │                          # notif-icon-image-fallback.jpg
│   ├── pam.d/                 # password.conf (lock-screen PAM stack)
│   ├── shaders/               # borderProgress, waveForm, wavy, ImageTransition
│   │   └── transitions/       # boxExpand, circleExpand, diagonalWipe, dissolve, fade,
│   │                          # hexTile, pixelate, roll, slideUp, splitHorizontal, wipeDown
│   ├── shell/                 # desktop-session.sh, extract-fg.sh, last-session.sh,
│   │                          # pkexec.sh, qmllint_qs.sh, remove-bg.py,
│   │                          # generate_colors_material.py (legacy, unused — see below)
│   └── weather_icon/          # Moon phase SVGs
│
├── packaging/arch/quickshell/ # PKGBUILD (quickshell 0.3.1 built from source)
├── patches/                   # upstream qmlfmt/qt-creator build fixes
├── Data/                      # configurations.json (defaults), colors.json,
│                              # dark-colors.json, light-colors.json
└── translations/              # en_US.{ts,qm}, id_ID.{ts,qm}
```

### Vendored dependencies

`Plugins/third_party/` holds the non-system C++ dependencies:

| Directory | Kind | Upstream |
|---|---|---|
| `material-color-utilities/` | git submodule | [material-foundation/material-color-utilities](https://github.com/material-foundation/material-color-utilities) |
| `fzy/` | git submodule | [jhawthorn/fzy](https://github.com/jhawthorn/fzy) |
| `mcu/` | local CMake wrapper + `absl_shim` | builds the `material-color-utilities` submodule (upstream is Bazel-only) |
| `fzy-wrapper/` | local CMake wrapper | builds the `fzy` submodule |

### Material color generation

Color generation is **C++**. The pipeline is:

```
wallpaper path
  → Vast.Utils ColorMaterial      (debounced, off-thread via Vast.Jobs)
  → ImageQuantizer                (Celebi/Score quantizer, Pillow-parity resize)
  → MaterialRoles                 (~60 roles, 2021 + 2025 spec delegates)
  → PaletteBuilder / PaletteValidation
  → PaletteAnimator               (OKLab blend, no flicker)
  → M3TemplateColors              →  Colours.m3Colors
```

`Assets/shell/generate_colors_material.py` is a **legacy** Python implementation kept as the reference for the C++ port. It is not invoked by the shell; the only remaining reference is `archInstall.sh`, which copies it to `/usr/local/bin/generate-colors-material`.

> [!NOTE]
> `Data/dark-colors.json` and `Data/light-colors.json` are legacy outputs of that script. Nothing reads them at runtime — see [Configuration → Colors](Configuration.md#colors).

---

## Upcoming Features

> [!NOTE]
> These features are planned and may change in scope or priority. Contributions are welcome!

**KDE Connect**
- [x] Device discovery, pairing, and transfer UI
- [x] Drag-and-drop file sharing via Drag and Drop
- [x] Settings page with polling controls and device management

**Bluetooth**
- [x] Device discovery and pairing
- [x] Connection management and status in Quick Settings
- [x] In-shell BlueZ pairing agent

**Screen Capture Rework**
- [x] Redesign the screen recorder
- [x] Window selection mode for targeted recording
- [x] Merged multi-monitor screenshot support
- [x] Reduced external dependencies (less reliance on `slurp`, `hyprshot`, `grim`)

**VPN & Tunnel Detection**
- [ ] Warp (Cloudflare) and WireGuard connection detection
- [ ] Generic VPN status indicator in the network settings page

**Clipboard Manager**
- [x] Persistent clipboard history with image preview
- [x] Selected text snippets with source context
- [x] Vim keybindings for navigation, visual mode for selection, copy, delete and search
- [x] Built-in storage via `sqlite`
- [x] Native `ext_data_control_v1` Wayland backend
- [x] Fuzzy search over history

**Greeter**
- [x] greetd greeter entry point
- [x] Per-user session selection and last-session memory
- [x] Settings page

---

## Credits

Thanks to everyone in the Quickshell Discord server, especially **@m7moud_el_zayat** for the advice.

Thanks to **@outfoxxed** for [quickshell](https://github.com/quickshell-mirror/quickshell).

Thanks to **[@Soramane](https://github.com/caelestia-dots/shell)** for the inspiration — lots of references taken from your shell, and thanks for the material shapes too.

Also check out [qtengine](https://github.com/kossLAN/qtengine) by **@koss** — a Qt config that doesn't suck.
