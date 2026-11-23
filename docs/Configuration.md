# Configuration

[Back to README](../README.md)

vast-shell reads `~/.config/vast-shell/configurations.json`.

Every key has a built-in default, so the file is optional. To start from the shipped defaults:

```sh
mkdir -p ~/.config/vast-shell
cp /path/to/vast-shell/Data/configurations.json ~/.config/vast-shell/
```

## Reference

### Appearance

| Key | Default | Description |
|---|---|---|
| `animations.durations.scale` | `1` | Multiplier for all animation durations. |
| `fonts.family.material` | `"Material Symbols Rounded"` | Fallback family while the bundled Material Symbols font loads. Not in the Settings UI. |
| `fonts.family.mono` | `"monospace"` | Monospace face. |
| `fonts.family.nerd` | `""` | Nerd Font face. Empty falls back to the system sans. |
| `fonts.family.sans` | `"sans-serif"` | UI face. |
| `fonts.size.scale` | `1.0` | Multiplier for all font sizes. |
| `icons.type` | `"material"` | `material` or `phosphor`. |
| `icons.materialFontPath` | `""` | Custom Material Symbols TTF. Empty uses the bundled font. |
| `icons.phosphorFontPath` | `""` | Custom Phosphor TTF. Empty uses the bundled font. |
| `margin` | `5` / `7` / `10` / `12` / `15` | Outer spacing in px (`small` to `large`). |
| `padding` | `5` / `7` / `10` / `12` / `15` | Inner spacing in px (`small` to `large`). |
| `rounding` | `12` / `17` / `25` / `1000` | Corner radius in px (`small`, `normal`, `large`, `full`). |
| `spacing` | `7` / `10` / `12` / `15` / `20` | Gaps in px (`small` to `large`). |

Animation durations, easing curves and font sizes are derived from their `scale` keys and are read-only.

Switching `icons.type` applies without a restart. **Settings → Appearance → Icons → Reload** re-reads the active font from disk.

### Audio

| Key | Default | Description |
|---|---|---|
| `defaultSinkName` | `""` | Sink restored as default on startup. |
| `sinkProfiles` | `{}` | Per-sink volume and mute profiles. |
| `showPeakLevels` | `true` | Show live level meters on the volume page. |

### Bar

| Key | Default | Description |
|---|---|---|
| `alwaysOpenBar` | `true` | Keep the bar always visible. |
| `barHeight` | `40` | Bar height in px. |
| `compact` | `false` | Use the compact bar. |
| `visibleWorkspace` | `5` | Number of workspaces shown. |
| `workspacesIndicator` | `"dot"` | `dot` (flat) or `interactive` (pill with window icon and hover preview). |

### Capture Screen Video

| Key | Default | Description |
|---|---|---|
| `maxFps` | `60` | Target frame rate. The UI offers 30, 60 and 120. |
| `bitrate` | `"5 MB"` | Output bitrate. The UI offers 1, 5, 10 and 20 MB. |
| `videoCodec` | `""` | Empty (encoder default), `avc`, `hevc`, `vp8`, `vp9` or `av1`. |
| `audioCodec` | `""` | Empty (encoder default), `aac`, `mp3`, `flac` or `opus`. |
| `lowPower` | `"auto"` | `auto`, `on` or `off`. Trades quality for battery. |
| `showCursor` | `true` | Draw the pointer into the recording. |
| `historyMode` | `false` | Write captures straight to the history buffer. |

### Clipboard

| Key | Default | Description |
|---|---|---|
| `enabled` | `false` | Enable the clipboard manager. |
| `enablePreview` | `false` | Show a preview pane for images and text. |
| `enableVimKeybinds` | `false` | Vim-style navigation and visual-mode selection. |
| `keepOpenAfterCopy` | `false` | Keep the drawer open after copying. |
| `listEntries` | `15` | Entries shown per page. |
| `maxEntries` | `300` | Maximum entries kept. |
| `showTruncatedText` | `true` | Show a notice when previewed text is truncated. |
| `width` / `height` | `300` / `400` | Drawer size in px. |
| `preview.sourceWidth` / `sourceHeight` | `300` / `300` | Resolution of the cached preview thumbnail. |

### Colors

| Key | Default | Description |
|---|---|---|
| `isDarkMode` | `true` | Use the dark palette instead of the light one. |
| `scheme` | `"tonal-spot"` | `vibrant`, `tonal-spot`, `expressive`, `monochrome`, `rainbow`, `fruit-salad`, `neutral`, `fidelity` or `content`. |
| `useStaticColors` | `false` | Use a fixed palette instead of generating one. |
| `staticColorsPath` | `~/.config/vast-shell/colors.json` | Static palette file. |

Preview a palette without changing the running theme:

```sh
vastctl color generate ~/Pictures/wallpapers/foo.png --mode dark --scheme tonal-spot
```

#### Color templates

Templates are listed in `~/.config/vast-shell/templates.json`. Each entry has these keys:

| Key | Default | Description |
|---|---|---|
| `name` | `""` | Name selected by `vastctl color render --template`. |
| `input` | `""` | Template file. `~` and environment variables are expanded. |
| `output_path` | `""` | Rendered file. Empty means next to the template. |
| `post_hook` | `""` | Command run after the file is written. |
| `enabled` | `true` | A disabled template is skipped when rendering all templates. |

Placeholder syntax is described in [Usage](Usage.md#color-templates).

### Generals

| Key | Default | Description |
|---|---|---|
| `alpha` | `1.0` | Global transparency of shell surfaces. |
| `transparent` | `false` | Enable transparency. |
| `enableOuterBorder` | `false` | Draw a border around the shell layout. |
| `outerBorderSize` | `10` | Border thickness in px. |
| `coverBlurRadius` | `16` | Blur radius for media cover art. |
| `chargingGlowSpread` | `10` | Glow spread while charging. |
| `followFocusMonitor` | `true` | Show the bar and drawers on the focused monitor. |
| `showHolidays` | `true` | Show public holidays in the calendar. |
| `apps.terminal` | `"foot"` | Terminal. |
| `apps.fileExplorer` | `"pcmanfm-qt"` | File manager. |
| `apps.imageViewer` | `"lximage-qt"` | Image viewer. |
| `apps.videoViewer` | `"mpv"` | Video player. |
| `apps.playback` | `"mpv"` | Media player. |
| `apps.audio` | `"pavucontrol-qt"` | Audio mixer. |
| `battery.criticalLevel` | `3` | Battery percentage that triggers the critical notification. |
| `battery.warnLevels` | | List of thresholds. Each has `level`, `title`, `message` (rich text) and `icon`. |

### Idle

| Key | Default | Description |
|---|---|---|
| `enabled` | `true` | Run the idle monitors. |
| `timeouts[].timeoutMonitor` | `60` | Idle seconds before the action fires. |
| `timeouts[]."on-timeout"` | `""` | Command run on timeout. |
| `timeouts[]."on-resume"` | `""` | Command run when activity resumes. |

```json
"timeouts": [
  { "timeoutMonitor": 900, "on-timeout": "hyprctl dispatch dpms off", "on-resume": "hyprctl dispatch dpms on" }
]
```

### KDE Connect

| Key | Default | Description |
|---|---|---|
| `pollingEnabled` | `true` | Discover devices periodically. |
| `pollInterval` | `15000` | Poll interval in ms. |

### Language

| Key | Default | Description |
|---|---|---|
| `language` | `"id_ID"` | Locale of the translation catalogue. See [Translations](Translations.md). |

### Lockscreen

| Key | Default | Description |
|---|---|---|
| `blurWindowsEnabled` | `false` | Show blurred windows of the active workspace behind the lock screen. |
| `blurRadius` | `48` | Blur radius for those windows. |

### Media Player

| Key | Default | Description |
|---|---|---|
| `showLyrics` | `false` | Fetch and show synced lyrics. |
| `dynamicColorsCover` | `true` | Take UI colors from the current cover art. |
| `sliderType` | `"Wavy"` | Progress bar style: `Wavy` or `WaveForm`. |

### Notification

| Key | Default | Description |
|---|---|---|
| `maximumNotification` | `100` | Maximum notifications kept. |
| `maximumNotificationAge` | `604800000` | Maximum age in ms (7 days). |

### Privacy

| Key | Default | Description |
|---|---|---|
| `enablePrivacyIndicator` | `false` | Enable the privacy indicator. |
| `enablePrivacyIcon` | `true` | Show the privacy icon in the bar. |
| `enablePrivacyIndicatorOnDynamicIsland` | `true` | Also show privacy state on the dynamic island. |
| `blockPrivacyListNodesName` | `{}` | Per-app node names to hide. |

### Search

| Key | Default | Description |
|---|---|---|
| `maxDepth` | `3` | Directory depth searched in the file dialog. |
| `fileDirs` | `[]` | Pinned search roots. Empty uses the dialog's current directory. |

### Wallpaper

| Key | Default | Description |
|---|---|---|
| `enabledWallpaper` | `true` | Draw the wallpaper. |
| `wallpaperDir` | `~/Pictures/wallpapers` | Wallpaper directory. |
| `transition` | `"random"` | `none`, `random`, `fade`, `wipedown`, `circle`, `dissolve`, `splitH`, `slideup`, `pixelate`, `diagonal`, `box`, `roll` or `hexTile`. `random` picks a new one per change. |
| `transitionDuration` | `300` | Transition length in ms. |
| `transitionLowPerfMode` | `false` | Use instant cuts instead of transitions. |
| `visibleWallpaper` | `3` | Wallpapers shown in the picker. |
| `livePreview` | `true` | Generate a palette as soon as a wallpaper loads. |

### Weather

| Key | Default | Description |
|---|---|---|
| `latitude` / `longitude` | | Your location in decimal degrees, as strings. |
| `reloadTime` | `180` | Refresh interval in **seconds**. |
| `enableQuickSummary` | `false` | Show a compact summary in the bar. |
| `astronomyApiKey` | `""` | API key for the sunrise, sunset and moon-phase provider. |
