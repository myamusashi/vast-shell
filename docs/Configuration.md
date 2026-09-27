# Configuration

[Back to README](../README.md)

Vast-shell keeps all of its settings in a single JSON file: `configurations.json`.

## Where the file lives

The path is resolved once at startup by `Qml/Core/Utils/Paths.qml`:

| Path | Value |
|---|---|
| `HOME` | `$HOME` |
| `configDir` | `$XDG_CONFIG_DIR` if set, otherwise `$HOME/.config` |
| `shellDir` | `<configDir>/vast-shell` |
| **config file** | **`<shellDir>/configurations.json`** |

Normally that resolves to `~/.config/vast-shell/configurations.json`.

> [!WARNING]
> `Paths.qml` reads **`XDG_CONFIG_DIR`**, not the XDG-standard `XDG_CONFIG_HOME`. If you set `XDG_CONFIG_HOME` and not `XDG_CONFIG_DIR`, the shell still uses `~/.config`.

If the file does not exist, the shell does not error — every key falls back to the default declared in its `*Config.qml`. So a fresh install needs no config file at all.

The file is watched: edits made from the Settings UI are written back, and edits made on disk are picked up live.

## Setup

To start from the shipped defaults instead:

```bash
mkdir -p ~/.config/vast-shell
cp /path/to/vast-shell/Data/configurations.json ~/.config/vast-shell/
```

You generally do **not** need to copy the color files — the Material palette is generated at runtime in C++ (see [Material Colors](#material-colors)). Copy `Data/colors.json` only if you want to pin a static palette.

> [!NOTE]
> `Data/configurations.json` is a *convenience snapshot*, not the source of truth. It is missing several sections (`clipboard`, `audio`, `idle`, `search`, `privacy`, `kdeConnect`, `captureScreenVideo`) and it contains two dead keys (`colors.toDarkColor`, `colors.toWhiteColor`) that nothing reads. The tables below document the **code defaults**, which are what actually apply for any key you leave out.

---

## Structure

<details>
<summary>Full structure (code defaults)</summary>

```json
{
  "appearance": {
    "animations": {
      "curves": {},
      "durations": { "scale": 1 }
    },
    "fonts": {
      "family": {
        "material": "Material Symbols Rounded",
        "mono": "monospace",
        "nerd": "",
        "sans": "sans-serif"
      },
      "size": { "scale": 1.0 }
    },
    "margin":  { "small": 5, "smaller": 7, "normal": 10, "larger": 12, "large": 15 },
    "padding": { "small": 5, "smaller": 7, "normal": 10, "larger": 12, "large": 15 },
    "rounding": { "small": 12, "normal": 17, "large": 25, "full": 1000 },
    "spacing":  { "small": 7, "smaller": 10, "normal": 12, "larger": 15, "large": 20 }
  },
  "audio": {
    "defaultSinkName": "",
    "sinkProfiles": {},
    "showPeakLevels": true
  },
  "bar": {
    "alwaysOpenBar": true,
    "barHeight": 40,
    "compact": false,
    "visibleWorkspace": 5,
    "workspacesIndicator": "dot"
  },
  "captureScreenVideo": {
    "maxFps": 60,
    "bitrate": "5 MB",
    "videoCodec": "",
    "audioCodec": "",
    "lowPower": "auto",
    "showCursor": true,
    "historyMode": false
  },
  "clipboard": {
    "enabled": false,
    "enablePreview": false,
    "enableVimKeybinds": false,
    "keepOpenAfterCopy": false,
    "listEntries": 15,
    "maxEntries": 300,
    "width": 300,
    "height": 400,
    "preview": { "sourceWidth": 300, "sourceHeight": 300 }
  },
  "colors": {
    "isDarkMode": true,
    "useStaticColors": false,
    "staticColorsPath": "~/.config/vast-shell/colors.json",
    "scheme": "tonal-spot"
  },
  "generals": {
    "alpha": 1.0,
    "transparent": false,
    "enableOuterBorder": false,
    "outerBorderSize": 10,
    "coverBlurRadius": 16,
    "chargingGlowSpread": 10,
    "followFocusMonitor": true,
    "showHolidays": true,
    "apps": {
      "audio": "pavucontrol-qt",
      "fileExplorer": "pcmanfm-qt",
      "imageViewer": "lximage-qt",
      "playback": "mpv",
      "terminal": "foot",
      "videoViewer": "mpv"
    },
    "battery": {
      "criticalLevel": 3,
      "warnLevels": [
        { "level": 20, "title": "Low battery",         "message": "You might want to plug in a charger",            "icon": "battery-020" },
        { "level": 10, "title": "Did you see the previous message?", "message": "You should probably plug in a charger <b>now</b>", "icon": "battery-010" },
        { "level": 5,  "title": "Critical battery level", "message": "PLUG THE CHARGER RIGHT NOW!!",                  "icon": "battery-000" }
      ]
    }
  },
  "idle": {
    "enabled": true,
    "timeouts": [
      { "timeoutMonitor": 60, "on-timeout": "", "on-resume": "" }
    ]
  },
  "kdeConnect": {
    "pollingEnabled": true,
    "pollInterval": 15000
  },
  "language": { "language": "id_ID" },
  "mediaPlayer": {
    "dynamicColorsCover": true,
    "showLyrics": false,
    "sliderType": "Wavy"
  },
  "notification": {
    "maximumNotification": 100,
    "maximumNotificationAge": 604800000
  },
  "privacy": {
    "enablePrivacyIndicator": false,
    "enablePrivacyIcon": true,
    "enablePrivacyIndicatorOnDynamicIsland": true,
    "blockPrivacyListNodesName": {}
  },
  "search": {
    "maxDepth": 3,
    "fileDirs": []
  },
  "wallpaper": {
    "enabledWallpaper": true,
    "wallpaperDir": "~/Pictures/wallpapers",
    "transition": "random",
    "transitionDuration": 300,
    "transitionLowPerfMode": false,
    "visibleWallpaper": 3,
    "depthWallpaperEnabled": true,
    "livePreview": true,
    "autoProcessedDepthWallpaper": false,
    "depthWallpaperSource": "",
    "depthFgPath": ""
  },
  "weather": {
    "enableQuickSummary": false,
    "latitude": "-6.4028",
    "longitude": "106.7744",
    "astronomyApiKey": "",
    "reloadTime": 180
  }
}
```

`appearance.animations.curves`, `appearance.animations.durations.*` (except `scale`), `appearance.fonts.size.*` (except `scale`), `clipboard.preview.sourceSize*` are **derived** `readonly` properties — set them through the other keys, not directly.

</details>

---

## Reference

### Appearance

| Key | Default | Description |
|---|---|---|
| `animations.durations.scale` | `1` | Global multiplier for all derived animation durations (200–1000 ms). |
| `animations.durations.*` | derived | `small` 200, `normal` 300, `expressiveFastSpatial` 350, `emphasizedDecel` 400, `emphasized` 500, `expressiveDefaultSpatial` 500, `large` 600, `expressiveEffects` 200, `emphasizedAccel` 200, `extraLarge` 1000 — each × `scale`. |
| `animations.curves.*` | derived | Material 3 easing curves: `standard`, `standardAccel`, `standardDecel`, `emphasized`, `emphasizedAccel`, `emphasizedDecel`, `expressiveDefaultSpatial`, `expressiveFastSpatial`, `expressiveEffects`. |
| `fonts.family.material` | `"Material Symbols Rounded"` | Icon font. |
| `fonts.family.mono` | `"monospace"` | Monospace face. |
| `fonts.family.nerd` | `""` | Nerd Font face; empty falls back to the system sans. |
| `fonts.family.sans` | `"sans-serif"` | UI face. |
| `fonts.size.scale` | `1.0` | Global font size multiplier (derived sizes 12/13/14/16/18/30 × `scale`). |
| `margin` | 5/7/10/12/15 | `small`…`large` outer spacing in px. |
| `padding` | 5/7/10/12/15 | `small`…`large` inner spacing in px. |
| `rounding` | 12/17/25/1000 | `small`/`normal`/`large`/`full` corner radius in px. |
| `spacing` | 7/10/12/15/20 | `small`…`large` gaps in px. |

### Bar

| Key | Default | Description |
|---|---|---|
| `alwaysOpenBar` | `true` | Keep the bar always visible. |
| `barHeight` | `40` | Bar height in pixels. |
| `compact` | `false` | Enable compact bar mode. |
| `visibleWorkspace` | `5` | Number of workspaces shown. |
| `workspacesIndicator` | `"dot"` | `dot` (flat indicator) or `interactive` (pill shape with toplevel icon and hover preview). |

### Colors

| Key | Default | Description |
|---|---|---|
| `isDarkMode` | `true` | Generate the dark palette instead of the light one. |
| `scheme` | `"tonal-spot"` | Material scheme: `vibrant`, `tonal-spot`, `expressive`, `monochrome`, `rainbow`, `fruit-salad`, `neutral`, `fidelity`, `content`. |
| `useStaticColors` | `false` | Use a fixed palette instead of the generated one. |
| `staticColorsPath` | `<shellDir>/colors.json` | Path to the static palette file. |

> [!NOTE]
> `colors.toDarkColor` and `colors.toWhiteColor` still appear in `Data/configurations.json` but are **dead keys** — no code reads them. Generated palettes are never written to disk. Safe to delete.

### Generals

| Key | Default | Description |
|---|---|---|
| `alpha` | `1.0` | Global transparency level for shell surfaces. |
| `transparent` | `false` | Enable transparency. |
| `enableOuterBorder` | `false` | Draw a border around the shell layout. |
| `outerBorderSize` | `10` | Outer border thickness in pixels. |
| `coverBlurRadius` | `16` | Blur radius applied to media cover art. |
| `chargingGlowSpread` | `10` | Glow spread radius when the device is charging. |
| `followFocusMonitor` | `true` | Track the focused monitor for the bar and drawers. |
| `showHolidays` | `true` | Show public holidays in the calendar drawer. |
| `apps.terminal` | `"foot"` | Default terminal. |
| `apps.fileExplorer` | `"pcmanfm-qt"` | Default file manager. |
| `apps.imageViewer` | `"lximage-qt"` | Default image viewer. |
| `apps.videoViewer` | `"mpv"` | Default video player. |
| `apps.playback` | `"mpv"` | Default media player. |
| `apps.audio` | `"pavucontrol-qt"` | Default mixer. |
| `battery.criticalLevel` | `3` | Battery percentage that triggers the critical notification. |
| `battery.warnLevels` | see above | Threshold list; each entry has `level`, `title`, `message` (rich text) and `icon`. |

### Audio

| Key | Default | Description |
|---|---|---|
| `defaultSinkName` | `""` | Sink restored as default on startup. |
| `sinkProfiles` | `{}` | Per-sink volume/mute profiles. |
| `showPeakLevels` | `true` | Live input and output level meters in the volume page. |

> [!NOTE]
> Quickshell has this error: 
>```txt
>ERROR quickshell.service.pipewire.peak: PwNode(0x73f807e5a400, id=46/bound) is missing channels present in capture stream. Node channels: QList(qs::service::pipewire::PwAudioChannel::Mono) Stream channels: QList(qs::service::pipewire::PwAudioChannel::FrontLeft, qs::service::pipewire::PwAudioChannel::FrontRight)
>```
> We can just wait until the issue is fixes

### Media Player

| Key | Default | Description |
|---|---|---|
| `showLyrics` | `false` | Auto-fetch and display synced lyrics. |
| `dynamicColorsCover` | `true` | Adapt UI colors from the current track's cover art. |
| `sliderType` | `"Wavy"` | Progress bar style (`Wavy` or `WaveForm`). |

### Notification

| Key | Default | Description |
|---|---|---|
| `maximumNotification` | `100` | Maximum number of retained notifications. |
| `maximumNotificationAge` | `604800000` | Maximum notification age in milliseconds (7 days). |

### Clipboard

| Key | Default | Description |
|---|---|---|
| `enabled` | `false` | Enable the clipboard manager daemon. |
| `enablePreview` | `false` | Show an image/text preview pane. |
| `enableVimKeybinds` | `false` | Enable Vim-style navigation and visual-mode selection. |
| `keepOpenAfterCopy` | `false` | Keep the drawer open after copying an entry. |
| `listEntries` | `15` | Entries rendered per page. |
| `maxEntries` | `300` | Maximum retained entries. |
| `width` / `height` | `300` / `400` | Drawer size in pixels. |
| `preview.sourceWidth` / `sourceHeight` | `300` / `300` | Source resolution used for the cached preview thumbnail. |

### Capture Screen Video

| Key | Default | Description |
|---|---|---|
| `maxFps` | `60` | Target frame rate (UI offers 30/60/120). |
| `bitrate` | `"5 MB"` | Output bitrate (UI offers 1/5/10/20 MB). |
| `videoCodec` | `""` | `""` (encoder default), `avc`, `hevc`, `vp8`, `vp9`, `av1`. |
| `audioCodec` | `""` | `""` (encoder default), `aac`, `mp3`, `flac`, `opus`. |
| `lowPower` | `"auto"` | `auto`, `on`, `off` — trades quality for battery. |
| `showCursor` | `true` | Draw the pointer into the recording. |
| `historyMode` | `false` | Write captures straight to the history buffer. |

### Wallpaper

| Key | Default | Description |
|---|---|---|
| `enabledWallpaper` | `true` | Draw the wallpaper. |
| `wallpaperDir` | `~/Pictures/wallpapers` | Directory to source wallpapers from. |
| `transition` | `"random"` | `none`, `random`, `fade`, `wipedown`, `circle`, `dissolve`, `splitH`, `slideup`, `pixelate`, `diagonal`, `box`, `roll`, `hexTile`. `random` picks a fresh one per change. |
| `transitionDuration` | `300` | Transition duration in ms (slider 100–2000). |
| `transitionLowPerfMode` | `false` | Swap transitions for instant cuts. |
| `visibleWallpaper` | `3` | Wallpapers shown in the picker. |
| `depthWallpaperEnabled` | `true` | Enable the depth/parallax lock-screen effect (see below). |
| `livePreview` | `true` | Generate a palette from the wallpaper as soon as it loads. |
| `autoProcessedDepthWallpaper` | `false` | Process depth wallpapers without asking. |
| `depthWallpaperSource` | `""` | Wallpaper path the depth effect was built from. |
| `depthFgPath` | `""` | Cached extracted foreground for that wallpaper. |

> [!WARNING]
> `WallpaperConfig.qml` currently hardcodes `wallpaperDir` to the maintainer's home directory (`/home/myamusashi/Pictures/wallpapers`). Set it explicitly if you use a config file of your own.

### Weather

| Key | Default | Description |
|---|---|---|
| `latitude` / `longitude` | `"-6.4028"` / `"106.7744"` | Your location. |
| `reloadTime` | `180` | Refresh interval, in **seconds** (`Weather.qml` multiplies by 1000). |
| `enableQuickSummary` | `false` | Show a compact weather summary in the bar. |
| `astronomyApiKey` | `""` | Key for the sunrise/sunset and moon-phase provider. |

> [!WARNING]
> `reloadTime` has a units bug: `Weather.qml` reads it as **seconds**, while `WeatherPage.qml` writes it as **milliseconds**. Setting it from the Settings page therefore inflates the interval by 1000×. Prefer editing the JSON directly with a value in seconds.

### KDE Connect

| Key | Default | Description |
|---|---|---|
| `pollingEnabled` | `true` | Enable periodic device discovery. |
| `pollInterval` | `15000` | Poll interval in milliseconds. |

### Idle

| Key | Default | Description |
|---|---|---|
| `enabled` | `true` | Run the idle monitors. |
| `timeouts[].timeoutMonitor` | `60` | Idle seconds before the action fires. |
| `timeouts[]."on-timeout"` | `""` | Shell command run on timeout. |
| `timeouts[]."on-resume"` | `""` | Shell command run when activity resumes. |

```json
"timeouts": [
  { "timeoutMonitor": 900, "on-timeout": "hyprctl dispatch dpms off", "on-resume": "hyprctl dispatch dpms on" }
]
```

### Search

| Key | Default | Description |
|---|---|---|
| `maxDepth` | `3` | How deep to walk directory trees in the file dialog. |
| `fileDirs` | `[]` | Pinned search roots; empty falls back to the dialog's current directory. |

### Privacy

| Key | Default | Description |
|---|---|---|
| `enablePrivacyIndicator` | `false` | Show the privacy indicator at all. |
| `enablePrivacyIcon` | `true` | Show the privacy icon in the bar. |
| `enablePrivacyIndicatorOnDynamicIsland` | `true` | Also surface privacy state on the dynamic island. |
| `blockPrivacyListNodesName` | `{}` | Per-app blocked node names. |

### Language

| Key | Default | Description |
|---|---|---|
| `language` | `"id_ID"` | Locale for the Qt translation catalogue. See [Translations](Translations.md). |

---

## Material Colors

> [!IMPORTANT]
> Material You colors are generated **in C++**, not by a Python script. There is nothing to install and nothing to invoke.

The palette is derived from the current wallpaper in-process:

```
wallpaper image
  → Vast.Utils ColorMaterial      debounced, off-thread via Vast.Jobs
  → ImageQuantizer                Celebi/Score quantizer at 128px
  → MaterialRoles                 ~60 roles, M3 2021 + 2025 spec delegates
  → PaletteBuilder                role → #RRGGBB, plus PaletteValidation
  → PaletteAnimator               OKLab blend over 300 ms (no flicker)
  → M3TemplateColors              → Colours.m3Colors
```

- `Colors.staticColorsPath` is the **only** file the theme reads, and only when `useStaticColors` is `true`.
- `Assets/shell/generate_colors_material.py` is a **legacy** Python implementation kept as the reference for the C++ port. It is not invoked by the shell, and nothing writes `dark-colors.json` / `light-colors.json` at runtime.

Generate a palette for any image without touching the running theme:

```sh
vastctl color generate ~/Pictures/wallpapers/foo.png --mode dark --scheme tonal-spot
vastctl color from "#ce8fd6" --mode light --scheme vibrant
```

<details>
<summary>Example generated color scheme (dark)</summary>

```json
{
  "colors": {
    "background": "#171217",
    "error": "#ffb4ab",
    "errorContainer": "#93000a",
    "inverseOnSurface": "#342f34",
    "inversePrimary": "#7a4f80",
    "inverseSurface": "#eadfe6",
    "onBackground": "#eadfe6",
    "onError": "#690005",
    "onErrorContainer": "#ffdad6",
    "onPrimary": "#48204f",
    "onPrimaryContainer": "#fed6ff",
    "onPrimaryFixed": "#300939",
    "onPrimaryFixedVariant": "#603767",
    "onSecondary": "#3b2b3c",
    "onSecondaryContainer": "#f4dbf2",
    "onSecondaryFixed": "#251726",
    "onSecondaryFixedVariant": "#524153",
    "onSurface": "#eadfe6",
    "onSurfaceVariant": "#cfc3cd",
    "onTertiary": "#4c2520",
    "onTertiaryContainer": "#ffdad5",
    "onTertiaryFixed": "#33110d",
    "onTertiaryFixedVariant": "#673b35",
    "outline": "#988d97",
    "outlineVariant": "#4d444c",
    "primary": "#eab5ee",
    "primaryContainer": "#603767",
    "primaryFixed": "#fed6ff",
    "primaryFixedDim": "#eab5ee",
    "scrim": "#000000",
    "secondary": "#d7bfd5",
    "secondaryContainer": "#524153",
    "secondaryFixed": "#f4dbf2",
    "secondaryFixedDim": "#d7bfd5",
    "shadow": "#000000",
    "sourceColor": "#ce8fd6",
    "surface": "#171217",
    "surfaceBright": "#3d373d",
    "surfaceContainer": "#231e23",
    "surfaceContainerHigh": "#2e282d",
    "surfaceContainerHighest": "#393338",
    "surfaceContainerLow": "#1f1a1f",
    "surfaceContainerLowest": "#110d11",
    "surfaceDim": "#171217",
    "surfaceTint": "#eab5ee",
    "surfaceVariant": "#4d444c",
    "tertiary": "#f5b8af",
    "tertiaryContainer": "#673b35",
    "onTertiary": "#4c2520",
    "onTertiaryContainer": "#ffdad5",
    "onTertiaryFixed": "#33110d",
    "onTertiaryFixedVariant": "#673b35",
    "success": "#7ddb8f",
    "onSuccess": "#00391a",
    "successContainer": "#005227",
    "onSuccessContainer": "#99f8b2"
  }
}
```

</details>

---

## Depth Wallpaper

> [!NOTE]
> Depth wallpaper extracts the foreground subject from your wallpaper and layers it separately over a blurred background, creating a **parallax depth effect** on the lock screen.

**How it works:**

1. When `depthWallpaperEnabled` is on, the first wallpaper change triggers foreground extraction
2. `Assets/shell/extract-fg.sh` runs `remove-bg.py` with the **BiRefNet-portrait** model to separate the foreground subject from the background
3. The extracted foreground is cached by content hash (`depthFgPath`) so subsequent uses of the same wallpaper are instant
4. On the lock screen, the wallpaper blurs and the foreground layer sits on top with independent scaling

**Model details:**

| Property | Value |
|---|---|
| Model | `birefnet-portrait` (BiRefNet for portraits/foregrounds) |
| Download size | ~176 MB (downloaded once on first use) |
| RAM usage during inference | ~800 MB – 1.5 GB |
| Processing time (GPU) | ~2 – 8 seconds |
| Processing time (CPU) | ~10 – 40 seconds |

> [!TIP]
> - Processing runs **asynchronously** in the background — you can continue using the shell normally
> - The extracted foreground is cached in `~/.cache/vast-shell/depthwp/foregrounds/`
> - To reprocess a wallpaper, delete its cached foreground from that directory and trigger a wallpaper change
> - Depth wallpaper needs a **static** image; it does not apply to video wallpapers
> - GPU acceleration requires `onnxruntime` with CUDA support — `pip install onnxruntime-gpu`
