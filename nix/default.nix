{
  lib,
  makeWrapper,
  stdenv,
  gnugrep,
  findutils,
  gnused,
  gawk,
  lucide,
  weather-icons,
  libnotify,
  quickshell,
  util-linux,
  networkmanager,
  m3Shapes,
  matugen,
  playerctl,
  wl-clipboard,
  wl-screenrec,
  ffmpeg,
  foot,
  kdePackages,
  polkit,
  patchelf,
  hyprland,
  qt6,
  callPackage,
  cmake,
}: let
  app2unit = callPackage ./app2unit.nix {};
  keystate-bin = callPackage ./keystate.nix {};
  material-symbols = callPackage ./material-symbols.nix {};
  runtimeDeps = [
    findutils
    gnugrep
    gawk
    gnused
    util-linux
    networkmanager
    matugen
    playerctl
    wl-clipboard
    libnotify
    weather-icons
    wl-screenrec
    ffmpeg
    foot
    polkit
    m3Shapes
    hyprland
    kdePackages.qtmultimedia
    qt6.qtbase
    qt6.qtgraphs
    material-symbols
    (lucide.overrideAttrs rec {
      version = "0.544.0";
      url = "https://unpkg.com/lucide-static@${version}/font/Lucide.ttf";
      hash = "sha256-Cf4vv+f3ZUtXPED+PCHxvZZDMF5nWYa4iGFSDQtkquQ=";
    })
  ];
  shell = stdenv.mkDerivation {
    pname = "shell";
    version = "0.1.0";
    src = ../.;

    nativeBuildInputs = [
      makeWrapper
      patchelf
      cmake
      qt6.qttools # untuk lrelease
      qt6.wrapQtAppsHook # untuk Qt dependencies
    ];

    buildInputs = [
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qtmultimedia
      kdePackages.qtmultimedia
    ];

    postPatch = ''
      substituteInPlace shell.qml \
        --replace-fail 'ShellRoot {' 'ShellRoot { settings.watchFiles: false'
    '';

    dontUseCmakeConfigure = true;

    buildPhase = ''
      runHook preBuild

      echo "Building Translations..."
      # Pastikan folder translations ada
      if [ -d "translations" ]; then
        ${qt6.qttools}/bin/lrelease translations/*.ts
      fi

      echo "Building TranslationManager Plugin..."
      mkdir -p build
      cd build

      cmake ../plugins/TranslationManager \
        -DCMAKE_INSTALL_PREFIX=$out \
        -DCMAKE_BUILD_TYPE=Release \
        -DQT_QMAKE_EXECUTABLE=${qt6.qtbase}/bin/qmake \
        -DCMAKE_PREFIX_PATH=${qt6.qtbase}

      cmake --build .
      cd ..

      runHook postBuild
    '';

    dontWrapQtApps = true;

    installPhase = ''
      runHook preInstall

      # Install quickshell files (exclude build folder!)
      mkdir -p $out/share/quickshell
      shopt -s extglob
      cp -r !(build) $out/share/quickshell/ 2>/dev/null || true

      # Copy specific files to avoid build artifacts
      for dir in Assets Components Widgets; do
        if [ -d "$dir" ]; then
          mkdir -p "$out/share/quickshell/$dir"
          cp -r "$dir"/* "$out/share/quickshell/$dir/" 2>/dev/null || true
        fi
      done

      # Copy QML and config files
      for file in *.qml *.js; do
        [ -f "$file" ] && cp "$file" "$out/share/quickshell/" || true
      done

      # Copy translations
      if [ -d "translations" ]; then
        mkdir -p "$out/share/quickshell/translations"
        cp -r translations/*.qm "$out/share/quickshell/translations/" 2>/dev/null || true
      fi

      # Install binaries
      install -Dm755 ${keystate-bin}/bin/keystate-bin \
        $out/share/quickshell/Assets/keystate-bin
      install -Dm755 ${app2unit}/bin/app2unit $out/bin/app2unit
      install -Dm755 ${keystate-bin}/bin/keystate-bin $out/bin/keystate-bin

      # Install fonts
      mkdir -p $out/share/fonts/truetype
      cp -r ${material-symbols}/share/fonts/truetype/* \
        $out/share/fonts/truetype/

      # Install TranslationManager plugin
      mkdir -p $out/lib/qt-6/qml/TranslationManager

      # Debug: cek file yang ada di build
      echo "=== Checking build directory ==="
      ls -la build/
      echo "=== Looking for .so files ==="
      find build/ -name "*.so" -type f
      echo "=== Looking for qmldir ==="
      find build/ -name "qmldir" -type f
      echo "================================"

      # Copy plugin library - coba berbagai kemungkinan nama
      PLUGIN_COPIED=false
      for so_file in build/*.so build/**/*.so; do
        if [ -f "$so_file" ]; then
          echo "Found library: $so_file"
          cp "$so_file" $out/lib/qt-6/qml/TranslationManager/
          PLUGIN_COPIED=true
        fi
      done

      if [ "$PLUGIN_COPIED" = false ]; then
        echo "ERROR: No .so file found in build directory!"
        exit 1
      fi

      # Copy qmldir (CMake auto-generated)
      if [ -f build/qmldir ]; then
        echo "Using CMake-generated qmldir"
        cp build/qmldir $out/lib/qt-6/qml/TranslationManager/
      elif [ -f plugins/TranslationManager/qmldir ]; then
        echo "Using manual qmldir"
        cp plugins/TranslationManager/qmldir $out/lib/qt-6/qml/TranslationManager/
      else
        echo "ERROR: qmldir not found!"
        exit 1
      fi

      # Copy additional QML files if exist
      for qml_file in build/*.qml; do
        if [ -f "$qml_file" ]; then
          cp "$qml_file" $out/lib/qt-6/qml/TranslationManager/
        fi
      done

      # Create wrapper
      makeWrapper ${quickshell.packages.${stdenv.hostPlatform.system}.default}/bin/quickshell \
        $out/bin/shell \
        --add-flags "-p $out/share/quickshell" \
        --set QUICKSHELL_CONFIG_DIR "$out/share/quickshell" \
        --set QT_QPA_FONTDIR "${material-symbols}/share/fonts" \
        --prefix PATH : ${lib.makeBinPath (runtimeDeps ++ [app2unit])} \
        --suffix PATH : /run/current-system/sw/bin \
        --suffix PATH : /etc/profiles/per-user/$USER/bin \
        --suffix PATH : $HOME/.nix-profile/bin

      runHook postInstall
    '';

    postInstall = ''
      # Patch RPATH untuk semua .so files di plugin directory
      echo "=== Patching RPATH for plugin libraries ==="

      # Set RPATH untuk plugin agar bisa menemukan backing library
      for so_file in $out/lib/qt-6/qml/TranslationManager/*.so; do
        if [ -f "$so_file" ]; then
          echo "Patching RPATH for: $so_file"

          # Set RPATH to include:
          # 1. $ORIGIN (current directory - untuk libTranslationManager.so)
          # 2. Qt libraries
          patchelf \
            --set-rpath "\$ORIGIN:${lib.makeLibraryPath [qt6.qtbase qt6.qtdeclarative]}" \
            "$so_file"

          # Verify
          echo "RPATH for $so_file:"
          patchelf --print-rpath "$so_file"
        fi
      done

      echo "=== RPATH patching complete ==="
    '';

    meta = {
      description = "Custom Quickshell configuration";
      mainProgram = "shell";
    };
  };
in {
  inherit
    shell
    keystate-bin
    material-symbols
    app2unit
    runtimeDeps
    ;
  default = shell;
}
