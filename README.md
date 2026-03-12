<!-- Last Commit -->
![Last Commit](https://img.shields.io/github/last-commit/myamusashi/vast-shell?label=LAST+COMMIT&style=flat-square)

<!-- Stars -->
![Stars](https://img.shields.io/github/stars/myamusashi/vast-shell?label=STARS&style=flat-square)

<!-- Repo Size -->
![Repo Size](https://img.shields.io/github/repo-size/myamusashi/vast-shell?label=REPO+SIZE&style=flat-square)

# Project structure
```md
shell.qml
│
├── flake.nix
├── flake.lock
├── shell.nix
│
├── nix/
│   ├── default.nix
│   ├── hm-modules.nix
│   ├── packages/
│   │   ├── AnotherRipple.nix
│   │   ├── app2unit.nix
│   │   ├── m3Shapes.nix
│   │   ├── material-symbols.nix
│   │   └── qmlfmt.nix
│   └── plugins/
│       ├── vastPlugin.nix
│       ├── audioProfiles.nix
│       ├── keylockState.nix
│       ├── keystate.nix
│       ├── translationManager.nix
│       └── go-scripts.nix
│
├── Core/
│   ├── Configs/
│   ├── States/
│   └── Utils/
│
│
├── Components/
│   ├── Base/
│   │
│   │
│   ├── Dialog/
│   └── Feedback/
│
├── Services/
│   └── http.js
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
│   │
│   ├── Dashboard/
│   ├── Lock/
│   ├── Polkit/
│   ├── Settings/
│   └── Wallpaper/
│
├── Widgets/
│
├── Plugins/
│   └── Vast/
│       ├── CMakeLists.txt
│       ├── AudioProfilesModel.cpp/hpp
│       ├── AudioProfilesWatcher.cpp/hpp
│       ├── KeylockState.cpp/hpp
│       ├── ScreenRecorder.cpp/hpp
│       ├── TranslationManager.cpp/hpp
│       └── Search/
│
├── Assets/
├── Data/
└── translations/
```
