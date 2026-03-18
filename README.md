![Last Commit](https://img.shields.io/github/last-commit/myamusashi/vast-shell?label=last+commit&style=for-the-badge&color=cba6f7&labelColor=1e1e2e)
![Commits](https://img.shields.io/github/commit-activity/t/myamusashi/vast-shell?label=commits&style=for-the-badge&color=cba6f7&labelColor=1e1e2e)
![Stars](https://img.shields.io/github/stars/myamusashi/vast-shell?label=stars&style=for-the-badge&color=cba6f7&labelColor=1e1e2e)
![Repo Size](https://img.shields.io/github/repo-size/myamusashi/vast-shell?label=repo+size&style=for-the-badge&color=cba6f7&labelColor=1e1e2e)
![Nix](https://img.shields.io/badge/nix-flakes-89b4fa?style=for-the-badge&labelColor=1e1e2e&logo=nixos&logoColor=89b4fa)
![C++](https://img.shields.io/badge/c%2B%2B-23-89b4fa?style=for-the-badge&labelColor=1e1e2e&logo=cplusplus&logoColor=89b4fa)
![QML](https://img.shields.io/badge/qml-quickshell-89b4fa?style=for-the-badge&labelColor=1e1e2e&logo=qt&logoColor=89b4fa)

## Showcase

### Video

https://github.com/user-attachments/assets/11651d0e-6929-4404-a24f-7e3dabc95ad1

---

### Preview

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
- **Weather** — detailed weather widget with hourly and daily forecast, AQI, UV index, moon phase, wind, humidity, pressure, precipitation, and visibility pages
- **Lockscreen** — PAM-authenticated lockscreen with clock and wallpaper
- **Polkit** — graphical polkit authentication agent
- **Wallpaper Selector** — wallpaper browser with live preview
- **Settings** — full settings UI with pages for appearance, bar, general, internet, language, media player, wallpaper, and weather

### Theming & Visuals
- **Material Design 3** — MD3-based component library
- **matugen integration** — dynamic color scheme generation from wallpaper
- **Wallpaper transitions** — GPU-accelerated GLSL transition effects (fade, dissolve, wipe, circle expand, pixelate, roll, and more)
- **Wavy / waveform shader** — animated waveform visual component
- **Border progress shader** — GPU-rendered animated border for notifications

### Widgets
- **Clock** — time and date display
- **Workspaces** — Hyprland workspace indicators
- **Tray** — system tray with tray menu
- **Battery** — battery status and percentage
- **Lyrics View** — synchronized lyrics display for the current track
- **Record Indicator** — live screen recording status indicator
- **Audio Profiles** — quick audio profile switcher widget
- **Notification Dots** — unread notification badge

### Plugins (C++23)
- **`SearchEngine`** — fuzzy file and app search with `FuzzyMatcher`
- **`AudioProfilesWatcher`** — PipeWire audio profile monitoring
- **`KeylockState`** — caps lock and num lock state
- **`LyricsProvider`** — lyrics fetching and sync provider
- **`TranslationManager`** — runtime locale switching

### Localization
- Indonesian (`id_ID`) translation included
- Runtime language switching without restart

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
> Run with `sudo`.

Clone the repo and run the install script:
```bash
git clone https://github.com/myamusashi/vast-shell.git
cd vast-shell
sudo ./archInstall.sh
```
start the shell with:
```bash
shell
```

#### Runtime dependencies

| Category | Packages |
|---|---|
| System | `hyprland`, `quickshell-git`, `foot`, `polkit`, `iw`, `libnotify` |
| Qt | `qt6-base`, `qt6-declarative`, `qt6-multimedia`, `qt6-shadertools` |
| Media | `ffmpeg`, `wireplumber`, `wl-clipboard`, `wl-screenrec` |
| Fonts | `ttf-material-symbols-variable-git`, `ttf-weather-icons` |
| Other | `matugen-bin`, `app2unit`|

---

> [!WARNING]
> Package names, availability, and versions listed here were accurate at the time of writing but **may be outdated or unavailable** depending on your distro version and repo state. Always verify package names against your distro's official package index before installing:
>
> - **Fedora** → https://packages.fedoraproject.org
> - **openSUSE** → https://software.opensuse.org
> - **Gentoo** → https://packages.gentoo.org
> - **Void** → https://voidlinux.org/packages
>
> If a package is missing or renamed, check your distro's community wiki or forums. PRs to keep this list updated are welcome.

### Fedora
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
> `ffmpeg` requires [RPM Fusion](https://rpmfusion.org) — `sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm`
> `qt6-qtgraphs` is not yet packaged in Fedora repos — build from source if required.

---

### openSUSE Tumbleweed
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

---

### Gentoo
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

---

### Void Linux
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

# Translations
> [!NOTE]
> `lupdate` and `lrelease` are provided by `qt6-tools` (Arch).
> On NixOS they are available via `qt6.qttools`.

Vast-shell uses Qt's built-in translation system. Translation files live in the `translations/` directory:

- `.ts` — source translation file (XML, human-editable)
- `.qm` — compiled binary used at runtime (generated, do not edit)

Currently included locales:

| Locale | Language |
|---|---|
| `id_ID` | Indonesian |

---

### Adding a New Language

**1. Generate a new `.ts` file from the source**
```bash
lupdate $(find . -name "*.qml" -not -path "./build/*") -ts translations/your_locale.ts
```

Replace `your_locale` with a standard locale code, e.g. `fr_FR`, `ja_JP`, `de_DE`.

**2. Open and translate the file**

You can edit the `.ts` file directly in any text editor, or use Qt Linguist for a GUI:
```bash
linguist translations/your_locale.ts
```

Each string entry looks like this, fill in the `<translation>` tag:
```xml
<message>
    <source>Search applications</source>
    <translation>Rechercher des applications</translation>
</message>
```

**3. Compile the `.ts` to `.qm`**
```bash
lrelease translations/your_locale.ts
```

This generates `translations/your_locale.qm` which the shell loads at runtime.

---

### Updating an Existing Translation

When new strings are added to the shell, sync them into the existing `.ts` file first:
```bash
lupdate $(find . -name "*.qml" -not -path "./build/*") -ts translations/your_locale.ts
```

This adds new untranslated entries without overwriting your existing translations. Then open the file, fill in the new entries, and recompile:
```bash
lrelease translations/your_locale.ts
```

### Qt Linguist

The recommended way to translate vast-shell is with **Qt Linguist**, a dedicated GUI translation editor that ships with `qt6-tools`. It shows every string in context, tracks translation progress, lets you mark strings as finished, and warns you about missing or outdated translations.

<img width="720" height="720" alt="image" src="https://github.com/user-attachments/assets/c5569311-99a3-4f99-9709-464ceda68495" />

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

---

# Project tree
```md
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
- Clipboard sync between devices
- File sharing between desktop and mobile
- Device presence detection and pairing UI

### Bluetooth
- Bluetooth device discovery and pairing
- Connection management and status indicator in the Quick Settings panel and settings window

### Screen Capture Rework
- screen recording overlay inspired by OBS Studio
- Window selection mode for targeted recording
- Merged multi-monitor screenshot support
- Reduced external dependencies, less reliance on `slurp`, `hyprshot` and `grim`

### VPN & Tunnel Detection
- Warp (Cloudflare) tunnel support
- WireGuard connection detection and status
- Generic VPN connection indicator in the settigs network page 

### Clipboard Manager
- Persistent clipboard history
- Image preview support
- Selected text snippets with source context
- Built-in, using sqlite or cliphist for clip monitor

---

## Credits

Thanks to everyone in the Quickshell Discord server for helping me with my questions, especially **@m7moud_el_zayat** for the advice

Thanks to **@outfoxxed** for [this](https://github.com/quickshell-mirror/quickshell) beautiful project

Thanks to **[@Soramane](https://github.com/caelestia-dots/shell)** for the inspiration, I took a lot of reference from your shell and thanks for the material shapes too (yoink some of his code too)

Thanks to **[@Rexcrazy804](https://github.com/Rexcrazy804/Zaphkiel)** for the kuru-kuru

#### Honorable Mention

Check out [qtengine](https://github.com/kossLAN/qtengine) by **@koss** — a Qt config that doesn't suck
