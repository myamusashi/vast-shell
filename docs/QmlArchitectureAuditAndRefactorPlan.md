# QML Architecture Audit and Refactor Plan

## Purpose

Before creating unit tests, scan every QML file for duplicated functionality, Single-Responsibility Principle violations, business logic embedded in UI components, and non-UI state that should live in a `Singleton`, `Scope`, `QML_ELEMENT`, or C++ service.

The goal is to extract pure logic and state machines into testable owners first. Unit tests should then target those owners instead of testing duplicated UI implementations.

## Audit Scope

The audit covers approximately 200 files under `Qml/**/*.qml`.

There are currently no QML unit tests. Existing tests are limited to:

- `Plugins/third_party/*_test.*`
- `vastctl/internal/pretty/tree_test.go`

The main issue blocking useful unit tests is that pure logic currently lives inside UI components.

---

# 4. Business Logic Currently Inside UI Components

Per the project rules, non-trivial business logic should move out of QML UI files.

## 4.1 System usage logic

Move out:

```text
parseNetworkData()
calculateNetworkStats()
parsePerCoreCpu()
formatSpeed()
formatUsage()
formatKB()
```

Also move shell parsing for:

```text
df
lscpu
lspci
awk
hwmon
```

Recommended owner:

```text
SystemInfo
```

Prefer C++ for process parsing and system queries.

## 4.2 Weather logic

Move out:

- XHR requests
- Request abort and timeout
- `updateWeather()`
- `updateAqi()`
- `updateAstronomy()`
- Quick-summary generation
- Health recommendations
- Dominant-pollutant detection
- Day-length calculation
- Astronomy parsing
- Schema reflection
- Cache handling
- Refresh scheduling

Recommended owners:

```text
WeatherService
AqiService
AstronomyService
```

C++ is preferred for network and parsing-heavy logic.

## 4.3 KDEConnect parsing

Move out:

```text
parseDeviceList()
parseFullDeviceList()
```

The current regex and command-output parsing belong in a service or C++ type.

## 4.4 Hotspot logic

Move out:

- `nmcli` command construction
- Status parsing
- Connection parsing

This also deserves security review because shell-string interpolation can become injection-prone.

## 4.5 Screenshot history

Move out:

```text
parseFileList()
newestFiles()
```

Avoid repeated shell `find` calls and repeated filename parsing in UI components.

## 4.6 Holiday model

Move out:

```text
ensureYear()
applyData()
isoDate()
```

The XHR and cache logic belongs in a service.

## 4.7 Battery service

Move out:

- `/sys` BAT* scanning
- Health calculations
- Battery capacity calculations
- Battery-time calculations

## 4.8 Color conversion

Move out:

```text
schemeEnum()
clamp01()
overlayColor()
rgbToHct()
hctToRgb()
```

Recommended owner:

```text
ColorUtils
```

or C++ if the conversion path is performance-sensitive.

## 4.9 Dynamic-island service

Move out:

```text
show()
dismiss()
promoteOrClose()
_expire()
```

The service currently owns several timers and state transitions.

Recommended owner:

```text
DynamicIslandController
```

or a C++/Scope-backed state machine.

## 4.10 Privacy service

Move out:

```text
fingerprint()
nodesFor()
schedule()
flush()
sync()
```

Avoid dynamic property access such as:

```qml
root[kind]
```

Prefer a typed map or explicit controller methods.

## 4.11 Drawer logic

Move out or centralize:

- Wi-Fi network sorting
- Wi-Fi connection handling
- PipeWire stream filtering
- PipeWire sorting
- Brightness target selection
- Filesystem model synchronization
- Hyprland monitor iteration
- Battery row mapping
- Track-art downloading
- Shell command construction
- Clipboard preview retry logic
- Notification inline-reply handling
- Audio label derivation
- OSD height calculation

## 4.12 Settings logic

Move out:

- Settings search scoring
- Fuzzy-search thresholds
- Top-eight result selection
- Idle configuration persistence
- Command sanitization
- Desktop-entry deduplication
- dB conversion
- Peak calculation
- Wallpaper command execution
- File URL normalization
- KDEConnect interval guards

## 4.13 Widget and utility logic

Move out:

- Workspace occupancy map
- Workspace geometry
- Audio profile persistence
- Calendar decade paging
- Month-name mapping
- Lyrics state and blend machines
- Tray menu placement
- Tray icon URI parsing
- KDEConnect file URL handling
- Authentication command parsing
- Dropdown placement calculations
- Wallpaper key-editing branches
- Greeter random mask generation

---

# 5. Non-UI State Suitable for Singleton or Scope

The following should become reusable non-visual owners.

## Recommended Singleton or Scope candidates

```text
TimeFormat
DurationFormatter
IconUtils
WifiIcons
WifiUtils
NetworkState
AqiScale
CelestialProgress
HourlyForecastUtils
TrackArtService
VolumeUtils
VolumeController
ThresholdIcon
BrightnessTargets
MediaKind
ThumbnailQueue
TrayMenuController
PopupPlacement
ModelAdapter
FileListMetrics
AuthFlow
IslandHost
GreeterWallpaper
WorkspaceGeometry
WorkspaceTarget
CalendarScope
ClockFormat
SinkProfileController
NotificationStore
AudioRestore
AppStats
WifiSorter
FilesystemsModel
MonitorsModel
BatteryRowsModel
ClipboardKeyController
SessionService
SettingsSearchService
UrlUtils
```

## State that should remain view-local

Small pixel/layout calculations can stay in a local `QtObject`, for example:

```text
Volume.sliderHeight
Volume.itemSize
ClipboardServices.uiState.listWidth
ClipboardServices.uiState.previewWidth
ClipboardServices.uiState.visualAnchor
VolumeContent.perAppWidth
```

The distinction is:

- Domain state and reusable logic → Singleton, Scope, service, or C++.
- One-view layout math → local `QtObject`.
- Visual layout and bindings → QML UI component.

---

# 6. Dead Code and Forwarders to Remove

Potential 1:1 forwarders:

```text
PolAgent
KeylockState
Players
Hyprsunset
Fontlist
```

Expose the underlying C++ or service object directly where safe.

Keep `Brightness` only if it owns IPC behavior.

Other dead or redundant state:

- `KDEConnect.pollInterval`
- `KDEConnect.polling`
- `Lyrics.offsets`
- `Lyrics.trackJustChanged`
- `CaptureScreenVideo` configuration mirrors
- `CaptureScreenVideo.loadingFromConfig`
- Redundant configuration properties that only mirror `Configs`

Bind directly to configuration values instead of maintaining duplicate mirrors.

Potential type issue:

```text
Hotspot.upstreamInterface: string = SystemUsage.allEthernetDevices
```

The declared type does not match the assigned list.

Potential ownership issue:

```text
Wallpaper.colorSourceImage: Item
```

A visual `Item` handle should not be stored in a long-lived Singleton. Keep it in the view or use an explicit ownership contract.

---

# 7. Recommended Refactor Order

## Phase 1 — Pure utilities

1. Time and formatting
2. Wi-Fi utilities
3. AQI scale
4. Celestial progress
5. Media-kind detection
6. Search debounce
7. Volume formatting

These are low-risk and produce the best unit-test targets.

## Phase 2 — Shared visual shells

1. `ZoomPopup`
2. `BlendColor` / `BlendRect`
3. `DebouncedSearchField`
4. `VerticalVolumeControl`
5. `ConfirmDialog`
6. `LockIndicator`
7. `ForecastStrip`
8. `BluetoothDeviceDelegate`

## Phase 3 — Service extraction

1. Weather service split
2. System usage split
3. Screenshot and thumbnail services
4. Notification store
5. Audio restore
6. Media-kind service
7. KDEConnect process factory
8. Greeter wallpaper service
9. Authentication flow

## Phase 4 — Rebind callers (evaluated 2026-09-26, executed same day)

Owner renames vs original audit: `TimeAgo.qml` does not exist — owner is `Qml/Core/Utils/FormatTimeUtils.qml`. `DebouncedSearchField.qml` does not exist — owner is `Qml/Core/Utils/DebouncedValue.qml` plus central `WallpaperFileModels.searchQuery` wiring. `BlendRect.qml` does not exist — owner is `Qml/Components/Effects/BlendColor.qml`. `weatherCodes.mjs` is already deleted; single source is `Qml/Services/Weather/weatherData.js`.

1. Formatter callers — DONE, no edit. Owner `FormatTimeUtils.qml` exists. `RecordIndicator`, `ContentMediaPlayer` (x2), `Preview` (clipboard/size), `LauncherRow`, `Performances` battery, `Notifs` `timeStr` all bound; `Mpris`, QS `MediaPlayer` shell, `LauncherServices` correctly no-op; `Weather.qml` keeps one-line delegating shims to `WeatherFormatter`.

2. Wi-Fi callers — DONE, no edit. Owner `Qml/Core/Utils/WifiUtils.qml` (`iconFor/sorted/tryConnect/handleConnectionFailed`) exists. `NetworkInfoColumn`, `NetworkDelegate`, `NetworkList`, `InternetPage` all bound (9 sites); zero icon/sort/connect copies remain. Optional nit: `WifiToggle.qml` vs `InternetPage.qml:195-199` share an identical `StyledSwitch` toggle with no shared owner — out of `WifiUtils` scope.

3. Popup callers — DONE. Blend callers — DONE except generic control machines. `ZoomPopup.qml` bound in `PopupWidget`, `WifiList`, `BluetoothList`, `EthernetList`, `StatusCard` (`openFrom`), `Performances` host; zero local zoom shells in scope. `BlendColor.qml` bound in all 10 in-scope sites after adding it to `Components/Base/BluetoothDeviceDelegate.qml:34-37` (connected-container blend now flows through `target` + `BlendColor`, matching `NetworkDelegate`). Remaining generic machines (`StyledSlide`, `PasswordInput`, `ExtendedFloatingButton`, `ContentMediaPlayer` progress) are purpose-built control animations, recorded as out of scope.

4. Weather callers — DONE. Fixed live hourly-UV bug (`Weather.qml:668` now maps `hourly.uv_index`); deleted `Headers.qml` ~50-case `getWeatherCondition` passthrough (now `condition || ""`); linked `Pages/AQI.qml:36/43` bounds to `AqiScale.usaBounds/europeBounds`; extracted shared UV helpers (`WeatherFormatter.uvCategoryInfo/uvCategoryLabel/uvCategoryIndex`, `Weather.pressureTrendIcon`) and rebound `WeatherItem/UVIndex.qml` + `Pages/UVIndex.qml:67`; created shared `Pages/HourlyValueSlider.qml` (`handleText/handleIcon/handleRotation`) and rebound Humidity/Precipitation/Pressure/UVIndex/Wind pages, deleting 5 local `*Slider` copies (wind triangle decoration retired with its local slider).

5. Volume/media callers — DONE. Created `Qml/Components/Volume/VerticalVolumeControl.qml` (`audioNode/sliderHeight/itemSize/showAppIcon/enableMuteToggle`, shared showVolume timer/slider/OSD) and rebound `Drawers/Volume/Content.qml` master + per-app delegates to it; `MasterControl.qml`/`Mixer.qml` kept as thin compatibility shims. Rebound `AudioLevelRow.qml:110/126` percent math to `VolumeUtils.toPercent` (`dbText` stays as peak-meter-specific logic). Rebound all media `Image`s to `TrackArt.cachedPath` (`Lock/MediaPlayer`, QS `MediaPlayer`, `ContentMediaPlayer:24` now defaults `trackArtColors: TrackArt.colors`).

6. Search callers — DONE. Rebound `Clipboard/SearchBar.qml:66` (150 ms `setFilter`) and `Dialog/FileDialog.qml:171` (200 ms `runFileSearch`, removed manual `restart()`) to `DebouncedValue`; renamed Launcher's selection-only 80 ms `Timer` to `selectionReset` (query stays immediate by design, timer id no longer masquerades as a search debounce). `SettingsSearchField` (200 ms) + wallpaper central `WallpaperFileModels` (300 ms) + 2 thin writers unchanged.

7. Service callers — DONE except documented splits. Rebound `WallpaperPage.qml:102` to `MediaKind.isVideo`; removed `PageHistory.qml:88` unused `fileExt` helper; routed `ElevatedCharging.qml:201` battery warnings via `CaptureNotify.sendNotification`; routed `Greeter/Surface.qml` wallpaper construction via `GreeterWallpaper.effectiveWallpaper`. Left intentionally local: `LauncherServices.captureFileKind` (screenshot-domain mp3→video split vs `MediaKind.kindOf`) and `FileListItem.getFileExtension` (folder/file display label).

After each group:

```text
Assets/shell/qmllint_qs.sh <changed-files>
qmlformat --dry-run <changed-files>
runtime smoke test
```

## Phase 5 — Unit tests

Only after extraction, write tests for pure logic and state transitions:

- Duration formatting
- Battery formatting
- Clipboard timestamp formatting
- Wi-Fi icon thresholds
- Wi-Fi network ordering
- AQI categories
- AQI marker fractions
- Celestial progress clamping
- Weather forecast filtering
- Media-kind detection
- Thumbnail path generation
- Search scoring thresholds
- Volume clamping
- Volume percentage formatting
- Popup state transitions
- Authentication state transitions
- Notification queue behavior
- Workspace geometry and occupancy
- File-list width calculations

Tests should assert behavior and invariants, not implementation details.

---

# 8. Highest-ROI Refactors Before Testing

## 1. Shared formatting singleton

Removes approximately seven formatter copies and enables straightforward timestamp and duration tests.

## 2. Wi-Fi utility and network state

Removes signal-threshold, sorting, and connection duplication across Quick Settings and Settings.

## 3. Shared popup and blend components

Removes four popup shells and seven or more color-blend state machines.

## 4. Weather utilities

Unifies weather card/page behavior, AQI marker calculations, celestial progress, hourly filtering, and slider implementations.

Also fixes the UV-index copy-paste bug.

## 5. Service extraction

Split:

```text
Weather
SystemUsage
CaptureScreen
Notifications
Audio
GlobalStates
```

Then extract:

```text
ThumbnailQueue
MediaKind
notifySend
AudioRestore
```

This is the highest-value step for making the code genuinely unit-testable.

---

# 9. Verification Requirements

After each refactor group:

```text
Assets/shell/qmllint_qs.sh <changed-files>
qmlformat --dry-run <changed-files>
```

When new QML files are created:

1. Run:

```text
quickshell -p Qml/
```

2. Wait for:

```text
INFO: QML tooling support enabled
```

3. Regenerate `.qmlls.ini`.
4. Run `qmllint` again.

Searches that should eventually return no stale implementations:

```text
calculateSunProgress
calculateMoonProgress
weatherCodes.mjs
debouncedSearchQuery
local formatTime implementations
duplicate zoomOrigin state
duplicate track-art downloaders
duplicate media-kind regexes
duplicate notification senders
```

Runtime smoke coverage should include:

- Launcher search and navigation
- Clipboard search
- Wallpaper search
- Settings search
- File-dialog search
- Wi-Fi popup
- Bluetooth popup
- Ethernet popup
- Performance popups
- Weather cards and detail pages
- AQI marker positioning
- UV index hourly values
- Volume drawer
- Per-application volume
- Lock-screen artwork
- Notifications
- Screenshot history
- Dynamic-island notifications
- Greeter wallpaper handling

The target architecture is:

```text
QML UI = layout, bindings, and user interaction
Singleton/Scope = reusable state and domain coordination
QML_ELEMENT/C++ = parsing, networking, process control, and heavy business logic
Unit tests = pure utilities and state transitions
```
