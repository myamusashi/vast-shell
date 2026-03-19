<h1 align="center">vast-shell</h1>

<div align="center">

![Last Commit](https://img.shields.io/github/last-commit/myamusashi/vast-shell?label=last+commit&style=for-the-badge&color=cba6f7&labelColor=1e1e2e)
![Commits](https://img.shields.io/github/commit-activity/t/myamusashi/vast-shell?label=commits&style=for-the-badge&color=cba6f7&labelColor=1e1e2e)
![Stars](https://img.shields.io/github/stars/myamusashi/vast-shell?label=stars&style=for-the-badge&color=cba6f7&labelColor=1e1e2e)
![Repo Size](https://img.shields.io/github/repo-size/myamusashi/vast-shell?label=repo+size&style=for-the-badge&color=cba6f7&labelColor=1e1e2e)

![Nix](https://img.shields.io/badge/nix-flakes-89b4fa?style=for-the-badge&labelColor=1e1e2e&logo=nixos&logoColor=89b4fa)
![C++](https://img.shields.io/badge/c%2B%2B-23-89b4fa?style=for-the-badge&labelColor=1e1e2e&logo=cplusplus&logoColor=89b4fa)
![QML](https://img.shields.io/badge/qml-quickshell-89b4fa?style=for-the-badge&labelColor=1e1e2e&logo=qt&logoColor=89b4fa)

</div>

> [!WARNING]
> This project is still in **active development**. Some features may be incomplete or change without notice, but it is usable as a daily driver. Issues and feedback are welcome!

---

## Showcase

### Video

https://github.com/user-attachments/assets/11651d0e-6929-4404-a24f-7e3dabc95ad1

### Preview

<details>
  <summary>Image preview</summary>
  <table>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/447c0b4a-a5b4-41ec-8f4a-05b57f523edb" width="480"/><br/>Bar & Workspaces</td>
    <td align="center"><img src="https://github.com/user-attachments/assets/a34f1a9f-f9ed-4f82-991f-e68e79e54fec" width="480"/><br/>Quick Settings</td>
  </tr>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/6283c0b6-6055-4fd0-900a-0dabafac46a3" width="480"/><br/>Launcher</td>
    <td align="center"><img src="https://github.com/user-attachments/assets/8049ec79-ade0-47d5-b2d8-cb5c5a25e895" width="480"/><br/>Notifications</td>
  </tr>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/74ddfbbd-269a-48fb-8380-bd11b0bcc82f" width="480"/><br/>Weather</td>
    <td align="center"><img src="https://github.com/user-attachments/assets/01cd558e-9beb-48a2-930c-bb48cfa493d4" width="480"/><br/>Dashboard</td>
  </tr>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/9995e862-e6ff-45ee-88d8-68dbb98226e1" width="480"/><br/>Lockscreen</td>
    <td align="center"><img src="https://github.com/user-attachments/assets/7ba86a61-f957-440d-9aa8-0eb6c84c766c" width="480"/><br/>Settings</td>
  </tr>
</table>
</details>

---

## Features

### Shell Components
- **Bar** — top/bottom status bar with left, middle, and right sections
- **Overview** — workspace overview with window thumbnails
- **Launcher** — fuzzy search app launcher with highlighted matches and animated delegates
- **OSD** — on-screen display for volume, brightness, caps lock, and num lock
- **Session** — power menu (shutdown, reboot, logout, suspend)

### Quick Settings Panel
- **Network** — Wi-Fi toggle with full network list and hotspot control
- **Brightness** — display brightness slider
- **Volume** — per-app audio mixer and output selector
- **Audio Profiles** — PipeWire sink/source profile switching
- **Media Player** — MPRIS-based playback controls with lyrics view
- **Notifications** — notification center with border-progress animations
- **Performance** — live CPU, RAM, disk, battery, network, and display info popups
- **Power Profiles** — power/performance mode switching

### Dashboard
- **System Monitor** — detailed CPU, RAM, disk, and network usage
- **Screen Capture** — screenshot and screen recording with history

### Modules
- **Calendar** — month view with major event highlights
- **Weather** — detailed widget with hourly and daily forecast, AQI, UV index, moon phase, wind, humidity, pressure, precipitation, and visibility pages
- **Lockscreen** — PAM-authenticated lockscreen with clock and wallpaper
- **Polkit** — graphical polkit authentication agent
- **Wallpaper Selector** — wallpaper browser with live preview
- **Settings** — full settings UI with pages for appearance, bar, general, internet, language, media player, wallpaper, and weather

### Theming & Visuals
- **Material Design 3** — MD3-based component library
- **matugen integration** — dynamic color scheme generation from wallpaper
- **Wallpaper transitions** — GPU-accelerated GLSL transition effects (fade, dissolve, wipe, circle expand, pixelate, roll, and more)
- **Wavy / waveform shader** — animated waveform visual on the media player slider
- **Border progress shader** — GPU-rendered animated border for notifications

### Widgets
- **Clock** — time and date display
- **Workspaces** — Hyprland workspace indicators
- **Tray** — system tray with context menu
- **Battery** — battery status and percentage
- **Lyrics View** — synchronized lyrics display for the current track
- **Record Indicator** — live screen recording status indicator
- **Audio Profiles** — quick audio profile switcher
- **Notification Dots** — unread notification badge

### Plugins (C++23)
- **`SearchEngine`** — fuzzy file and app search with `FuzzyMatcher`
- **`AudioProfilesWatcher`** — PipeWire audio profile monitoring
- **`KeylockState`** — caps lock and num lock state via evdev
- **`LyricsProvider`** — lyrics fetching and sync from lrclib.net
- **`ScreenRecorder`** — screen recording control singleton
- **`TranslationManager`** — runtime locale switching without restart

### Localization
- Indonesian (`id_ID`) translation included
- Runtime language switching without restart

### Global shortcut (Hyprland only)

- quickshell:wallpaperSwitcher
- quickshell:layershell
- quickshell:appLauncher
- quickshell:screencaptureLauncher
- quickshell:overview
- quickshell:QuickSettings
- quickshell:session
- quickshell:weather
- quickshell:dashboard
- quickshell:settings

**How to use Hyprland global shortcuts**

```
hyprctl dispatch global quickshell:appLauncher
```

### Ipc call

```txt
target weather
  function toggle(): void
  function open(): void
  function close(): void
target screenCapture
  function toggle(): void
  function open(): void
  function close(): void
target bar
  function toggle(): void
  function open(): void
  function close(): void
target toast
  function open(header: string, description: string, icon: string, duration: int): void
target quickSettings
  function toggle(): void
  function open(): void
  function close(): void
target img
  function get(): string
  function set(path: string): void
target launcher
  function toggle(): void
  function open(): void
  function close(): void
target session
  function toggle(): void
  function open(): void
  function close(): void
target dashboard
  function toggle(): void
  function open(): void
  function close(): void
target settings
  function toggle(): void
  function open(): void
  function close(): void
target overview
  function toggle(): void
  function open(): void
  function close(): void
target wallpaperSwitcher
  function toggle(): void
  function open(): void
  function close(): void
target lock
  function unlock(): void
  function isLocked(): bool
  function lock(): void
```

**How to use ipc handler from quickshell**

```sh
quickshell -c <shell directory> ipc call wallpaperSwitcher toggle

or

qs -c <shell directory> ipc call wallpaperSwitcher toggle

or

shell ipc call wallpaperSwitcher toggle
```

---

## Installation

### NixOS (Flakes)

Add vast-shell to your flake inputs:
```nix
inputs.vast-shell.url = "github:myamusashi/vast-shell";
```

Then include the package in your system or home configuration:
```nix
environment.systemPackages = [
  inputs.vast-shell.packages.${system}.default
];
```

#### Home Manager

Import the module and enable it:
```nix
imports = [ inputs.vast-shell.homeManagerModules.default ];

programs.quickshell-shell = {
  enable = true;

  # Optional: install extra packages accessible to the shell
  extraPackages = with pkgs; [ spotify ];

  # Optional: disable font installation if you manage fonts separately
  installFonts = false;
};
```

The module registers a systemd user service (`quickshell-shell.service`) that auto-starts with your graphical session.

---

### Arch Linux

> [!IMPORTANT]
> Requires Arch Linux or an Arch-based distro. Run with `sudo`.
```bash
git clone https://github.com/myamusashi/vast-shell.git
cd vast-shell
sudo ./archInstall.sh
```

The script will install all dependencies, build the plugins, compile shaders, and set up the shell. Once complete, start it with:
```bash
shell
```

#### Runtime Dependencies

| Category | Packages |
|---|---|
| System | `hyprland`, `quickshell-git`, `foot`, `polkit`, `iw`, `libnotify` |
| Qt | `qt6-base`, `qt6-declarative`, `qt6-multimedia`, `qt6-shadertools` |
| Media | `ffmpeg`, `wireplumber`, `wl-clipboard`, `wl-screenrec` |
| Fonts | `ttf-material-symbols-variable-git`, `ttf-weather-icons` |
| Other | `matugen-bin`, `app2unit` |

---

### Other Distros

> [!WARNING]
> Package names, availability, and versions listed below were accurate at the time of writing but **may be outdated or unavailable** depending on your distro version and repo state. Always verify against your distro's official package index before installing. If a package is missing or renamed, check your distro's community wiki or forums. PRs to keep this list updated are welcome.
>
> - **Fedora** → https://packages.fedoraproject.org
> - **openSUSE** → https://software.opensuse.org
> - **Gentoo** → https://packages.gentoo.org
> - **Void** → https://voidlinux.org/packages

The following packages must be built from source regardless of distro:

| Package | Source |
|---|---|
| `quickshell` | https://github.com/quickshell/quickshell |
| `matugen` | https://github.com/InioX/matugen |
| `app2unit` | https://github.com/valpackett/app2unit |
| `wl-screenrec` | https://github.com/russelltg/wl-screenrec |
| Material Symbols font | https://github.com/google/material-design-icons |
| Weather Icons font | https://github.com/erikflowers/weather-icons |

#### Fedora
```bash
# System & build
sudo dnf install git cmake ninja-build extra-cmake-modules patchelf pkgconf \
                 gcc gcc-c++ make rust cargo

# Qt6
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtsvg-devel \
                 qt6-qtmultimedia-devel qt6-qt5compat-devel \
                 qt6-qtshadertools-devel qt6-qttools-devel

# Runtime
sudo dnf install pipewire wireplumber iw libnotify polkit \
                 wl-clipboard ffmpeg foot hyprland findutils grep sed gawk util-linux
```

> [!NOTE]
> `ffmpeg` requires [RPM Fusion](https://rpmfusion.org): `sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm`
> `qt6-qtgraphs` is not yet packaged in Fedora — build from source if required.

#### openSUSE Tumbleweed
```bash
# System & build
sudo zypper install git cmake ninja extra-cmake-modules patchelf pkgconf \
                    gcc gcc-c++ make rust cargo

# Qt6
sudo zypper install qt6-base-devel qt6-declarative-devel qt6-svg-devel \
                    qt6-multimedia-devel qt6-5compat-devel \
                    qt6-shadertools-devel qt6-tools-devel

# Runtime
sudo zypper install pipewire wireplumber iw libnotify-tools polkit \
                    wl-clipboard ffmpeg foot hyprland findutils grep sed gawk util-linux
```

#### Gentoo
```bash
# System & build
sudo emerge -av dev-vcs/git dev-build/cmake dev-build/ninja \
                kde-frameworks/extra-cmake-modules dev-util/patchelf \
                dev-util/pkgconf dev-lang/rust

# Qt6 (ensure USE="qt6" where applicable)
sudo emerge -av dev-qt/qtbase:6 dev-qt/qtdeclarative:6 dev-qt/qtsvg:6 \
                dev-qt/qtmultimedia:6 dev-qt/qt5compat:6 \
                dev-qt/qtshadertools:6 dev-qt/qttools:6

# Runtime
sudo emerge -av media-video/pipewire media-video/wireplumber net-wireless/iw \
                x11-libs/libnotify sys-auth/polkit \
                gui-apps/wl-clipboard media-video/ffmpeg gui-apps/foot \
                gui-wm/hyprland sys-apps/util-linux
```

#### Void Linux
```bash
# System & build
sudo xbps-install -S git cmake ninja extra-cmake-modules patchelf pkgconf \
                     base-devel rust cargo

# Qt6
sudo xbps-install -S qt6-base-devel qt6-declarative-devel qt6-svg-devel \
                     qt6-multimedia-devel qt6-5compat-devel \
                     qt6-shadertools-devel qt6-tools

# Runtime
sudo xbps-install -S pipewire wireplumber iw libnotify polkit \
                     wl-clipboard ffmpeg foot hyprland findutils grep sed gawk util-linux
```

---

## Configuration

Vast-shell can be customized by editing the JSON files in the `Data/` directory.

### Main Configuration ([configurations.json](file:///home/myamusashi/shell/Data/configurations.json))

This file contains the primary settings for the shell, organized into several categories:

| Category | Description |
|---|---|
| **Appearance** | Font families (Material, Mono, Sans) and animation scale. |
| **Bar** | Bar height, workspace visibility, and indicator style. |
| **Colors** | Toggle dark mode, enable Matugen dynamic colors or auto generate from quickshell. |
| **Generals** | Default applications, battery warning levels, transparency, and borders. |
| **Media Player** | Lyrics visibility, slider style (WaveForm/Wavy), and dynamic cover colors. |
| **Notifications** | Maximum notification count and age. |
| **Wallpaper** | Transition effects, duration, and wallpaper directory. |
| **Weather** | Location coordinates (lat/long) and refresh interval. |

<details>
<summary>View configurations.json</summary>

```json
{
	"appearance": {
		"animations": {
			"durations": {
				"scale": 1
			}
		},
		"fonts": {
			"family": {
				"material": "Material Symbols Rounded",
				"mono": "Hack",
				"sans": "Google Sans Flex"
			},
			"size": {
				"scale": 1
			}
		}
	},
	"bar": {
		"alwaysOpenBar": true,
		"barHeight": 35,
		"compact": false,
		"visibleWorkspace": 4,
		"workspacesIndicator": "dot"
	},
	"colors": {
		"isDarkMode": true,
		"matugenConfigPathForDarkColor": "/home/myamusashi/.config/shell/dark-colors.json",
		"matugenConfigPathForLightColor": "/home/myamusashi/.config/shell/light-colors.json",
		"useMatugenColor": true,
		"useStaticColors": false
	},
	"generals": {
		"alpha": 1,
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
				{
					"icon": "battery-020",
					"level": 20,
					"message": "Kamu mungkin mau colok chargernya",
					"title": "Baterai lemah"
				},
				{
					"icon": "battery-010",
					"level": 10,
					"message": "Kamu mungkin ingin colok charger kamu <b>sekarang</b>",
					"title": "Kamu bisa lihat pesan sebelumnya kan?"
				},
				{
					"icon": "battery-000",
					"level": 5,
					"message": "MASUKAN CHARGER NYA SEKARANG!!",
					"title": "Level baterai kritis"
				}
			]
		},
		"chargingGlowSpread": 20,
		"coverBlurRadius": 1,
		"enableOuterBorder": true,
		"followFocusMonitor": true,
		"outerBorderSize": 10,
		"transparent": true
	},
	"language": {
		"language": ""
	},
	"mediaPlayer": {
		"dynamicColorsCover": true,
		"showLyrics": false,
		"sliderType": "WaveForm"
	},
	"notification": {
		"maximumNotification": 100,
		"maximumNotificationAge": 604800000
	},
	"wallpaper": {
		"enabledWallpaper": true,
		"transition": "circle",
		"transitionDuration": 500,
		"transitionLowPerfMode": false,
		"visibleWallpaper": 3,
		"wallpaperDir": "/home/myamusashi/Pictures/wallpapers"
	},
	"weather": {
		"enableQuickSummary": false,
		"latitude": "",
		"longitude": "",
		"reloadTime": 1800000
	}
}
```

</details>

### Matugen ([matugen/](file:///home/myamusashi/shell/Data/matugen))

The `matugen` directory contains configuration and templates for dynamic color generation.
- `matugen.toml` — main configuration for the Matugen tool.
- `dark-colors.json` / `light-colors.json` — generated color schemes.

<details>
<summary>View dynamic colors example (dark)</summary>

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
		"tertiaryFixed": "#ffdad5",
		"tertiaryFixedDim": "#f5b8af",
		
		"end": "end"
	}
}
```

</details>

---

## Translations

Vast-shell uses Qt's built-in translation system. Translation files live in the `translations/` directory:

- `.ts` — source translation file (XML, human-editable)
- `.qm` — compiled binary used at runtime (generated, do not edit)

Currently included locales:

| Locale | Language |
|---|---|
| `id_ID` | Indonesian |

> [!NOTE]
> `lupdate` and `lrelease` are provided by `qt6-tools` (Arch) or `qt6-tools-dev-tools` (Debian/Ubuntu). On NixOS they are available via `qt6.qttools`.

### Qt Linguist

The recommended way to translate vast-shell is with **Qt Linguist** — a dedicated GUI translation editor that ships with `qt6-tools`. It shows every string in context, tracks translation progress, lets you mark strings as finished, and warns about missing or outdated entries.

<img src="https://github.com/user-attachments/assets/c5569311-99a3-4f99-9709-464ceda68495" width="720"/>

<table>
  <tr>
    <td>✅ Visual side-by-side source and translation editing</td>
    <td>✅ Translation progress tracker per file</td>
  </tr>
  <tr>
    <td>✅ Marks unfinished and obsolete strings</td>
    <td>✅ Built-in phrase book and search</td>
  </tr>
</table>
```bash
linguist translations/your_locale.ts
```

### Adding a New Language

**1. Generate a new `.ts` file from the source**
```bash
lupdate $(find . -name "*.qml" -not -path "./build/*") -ts translations/your_locale.ts
```

Replace `your_locale` with a standard locale code, e.g. `fr_FR`, `ja_JP`, `de_DE`.

**2. Open in Qt Linguist and translate**
```bash
linguist translations/your_locale.ts
```

Or edit by hand — fill in the `<translation>` tag for each entry:
```xml
<message>
    <source>Search applications</source>
    <translation>Rechercher des applications</translation>
</message>
```

**3. Compile to `.qm`**
```bash
lrelease translations/your_locale.ts
```

### Updating an Existing Translation

Sync new strings into an existing `.ts` file without overwriting existing translations:
```bash
lupdate $(find . -name "*.qml" -not -path "./build/*") -ts translations/your_locale.ts
```

Open in Linguist, fill in entries marked as **Unfinished**, then recompile:
```bash
lrelease translations/your_locale.ts
```

### NixOS

Translations are compiled automatically during the build phase — no manual steps needed.

### Arch Linux

The `archInstall.sh` script compiles translations automatically. To recompile manually:
```bash
/usr/lib/qt6/bin/lrelease translations/*.ts
```

---

## Project Structure
```
shell.qml
├── archInstall.sh
├── flake.nix
├── flake.lock
├── shell.nix
│
├── nix/
│   ├── default.nix
│   ├── hm-modules.nix
│   ├── packages/
│   │   ├── app2unit.nix
│   │   ├── material-symbols.nix
│   │   └── qmlfmt.nix
│   └── plugins/
│       ├── vastPlugin.nix
│       ├── AnotherRipple.nix
│       └── m3Shapes.nix
│
├── Core/
│   ├── Configs/
│   ├── States/
│   └── Utils/
│
├── Components/
│   ├── Base/
│   ├── Dialog/
│   │   └── FileDialog/
│   └── Feedback/
│
├── Services/
│   ├── Audio.qml
│   ├── Battery.qml
│   ├── Brightness.qml
│   ├── Colours.qml
│   ├── Hotspot.qml
│   ├── Hypr.qml
│   ├── Lyrics.qml
│   ├── Notifs.qml
│   ├── SystemUsage.qml
│   ├── Weather.qml
│   ├── http.js
│   └── ...
│
├── Modules/
│   ├── Drawers/
│   │   ├── Drawers.qml
│   │   ├── Bar/
│   │   ├── Calendar/
│   │   ├── Launcher/
│   │   ├── Notifications/
│   │   ├── OSD/
│   │   ├── Overview/
│   │   ├── QuickSettings/
│   │   ├── Session/
│   │   ├── Volume/
│   │   ├── WallpaperSelector/
│   │   └── Weather/
│   ├── Dashboard/
│   ├── Lock/
│   ├── Polkit/
│   ├── Settings/
│   └── Wallpaper/
│
├── Widgets/
│   ├── AudioProfiles.qml
│   ├── Battery.qml
│   ├── Clock.qml
│   ├── LyricsView.qml
│   ├── Mpris.qml
│   ├── RecordIndicator.qml
│   ├── Tray.qml
│   ├── Workspaces.qml
│   └── ...
│
├── Plugins/
│   └── Vast/
│       ├── CMakeLists.txt
│       ├── AudioProfilesModel.cpp/hpp
│       ├── AudioProfilesWatcher.cpp/hpp
│       ├── KeylockState.cpp/hpp
│       ├── LyricsProvider.cpp/hpp
│       ├── ScreenRecorder.cpp/hpp
│       ├── TranslationManager.cpp/hpp
│       └── Search/
│           ├── FileProvider.cpp/hpp
│           ├── FuzzyMatcher.cpp/hpp
│           ├── SearchEngine.cpp/hpp
│           └── SearchResult.cpp/hpp
│
├── Assets/
│   ├── go/
│   │   └── formatting.go
│   ├── images/
│   ├── pam.d/
│   ├── shaders/
│   │   ├── borderProgress.frag/vert
│   │   ├── ImageTransition.vert
│   │   ├── waveForm.frag/vert
│   │   ├── wavy.frag/vert
│   │   └── transitions/
│   │       ├── boxExpand.frag
│   │       ├── circleExpand.frag
│   │       ├── diagonalWipe.frag
│   │       ├── dissolve.frag
│   │       ├── fade.frag
│   │       ├── pixelate.frag
│   │       ├── roll.frag
│   │       ├── slideUp.frag
│   │       ├── splitHorizontal.frag
│   │       └── wipeDown.frag
│   └── weather_icon/
│
├── Data/
│   └── matugen/
├── patches/
└── translations/
```

---

## Upcoming Features

> [!NOTE]
> These features are planned and may change in scope or priority. Contributions are welcome!

### KDE Connect Integration
- [ ] Clipboard sync between devices
- [ ] File sharing between desktop and mobile
- [ ] Device presence detection and pairing UI

### Bluetooth
- [ ] Bluetooth device discovery and pairing
- [ ] Connection management and status indicator in the Quick Settings panel and settings window

### Screen Capture Rework
- [ ] Screen recording overlay inspired by OBS Studio
- [ ] Window selection mode for targeted recording
- [ ] Merged multi-monitor screenshot support
- [ ] Reduced external dependencies — less reliance on `slurp`, `hyprshot`, and `grim`

### VPN & Tunnel Detection
- [ ] Warp (Cloudflare) tunnel support
- [ ] WireGuard connection detection and status
- [ ] Generic VPN connection indicator in the settings network page

### Clipboard Manager
- [ ] Persistent clipboard history
- [ ] Image preview support
- [ ] Selected text snippets with source context
- [ ] Built-in, using `sqlite` or `cliphist` for clip monitoring

---

## Credits

Thanks to everyone in the Quickshell Discord server for helping me with my questions, especially **@m7moud_el_zayat** for the advice.

Thanks to **@outfoxxed** for [this beautiful project](https://github.com/quickshell-mirror/quickshell).

Thanks to **[@Soramane](https://github.com/caelestia-dots/shell)** for the inspiration, I took a lot of reference from your shell and thanks for the material shapes too (and yoink your code).

Thanks to **[@Rexcrazy804](https://github.com/Rexcrazy804/Zaphkiel)** for the kuru-kuru.

#### Honorable Mention

Check out [qtengine](https://github.com/kossLAN/qtengine) by **@koss** — a qt config that doesn't suck.
