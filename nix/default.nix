{
  lib,
  makeWrapper,
  stdenv,
  gnugrep,
  findutils,
  gnused,
  gawk,
  weather-icons,
  libnotify,
  iw,
  quickshell,
  util-linux,
  networkmanager,
  matugen,
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
  qml-material = callPackage ./qmlMaterial.nix {};
  m3shapes = callPackage ./m3Shapes.nix {};
  translationManager = callPackage ./translationManager.nix {};

  runtimeDeps = [
    findutils
    gnugrep
    gawk
    gnused
    util-linux

    iw
    networkmanager
    libnotify
    polkit

    matugen
    wl-clipboard
    wl-screenrec
    ffmpeg
    weather-icons

    foot
    hyprland

    qml-material
    m3shapes
    translationManager
    material-symbols

    kdePackages.qtmultimedia
    qt6.qt5compat
    qt6.qtbase
    qt6.qtgraphs
  ];

  shell = stdenv.mkDerivation {
    pname = "shell";
    version = "0.1.0";
    src = ../.;

    nativeBuildInputs = [
      makeWrapper
      patchelf
      cmake
      qt6.qttools
      qt6.wrapQtAppsHook
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
    dontWrapQtApps = true;

    buildPhase = ''
      runHook preBuild

      echo "Building Translations..."
      if [ -d "translations" ]; then
        ${qt6.qttools}/bin/lrelease translations/*.ts
      fi

      runHook postBuild
    '';

    installPhase = ''
         runHook preInstall

         mkdir -p $out/share/quickshell
         shopt -s extglob
         cp -r !(build) $out/share/quickshell/ 2>/dev/null || true

         for dir in Assets Components Widgets; do
           if [ -d "$dir" ]; then
             mkdir -p "$out/share/quickshell/$dir"
             cp -r "$dir"/* "$out/share/quickshell/$dir/" 2>/dev/null || true
           fi
         done

         for file in *.qml; do
           [ -f "$file" ] && cp "$file" "$out/share/quickshell/" || true
         done

         install -Dm755 ${keystate-bin}/bin/keystate-bin \
           $out/share/quickshell/Assets/keystate-bin
         install -Dm755 ${app2unit}/bin/app2unit \
           $out/bin/app2unit
         install -Dm755 ${keystate-bin}/bin/keystate-bin \
           $out/bin/keystate-bin

         mkdir -p $out/share/fonts/truetype
         cp -r ${material-symbols}/share/fonts/truetype/* \
           $out/share/fonts/truetype/

      echo "${translationManager}"
         # Copy QML plugins to lib directory
         mkdir -p $out/${qt6.qtbase.qtQmlPrefix}

         # Copy m3shapes
         if [ -d "${m3shapes}/${qt6.qtbase.qtQmlPrefix}" ]; then
           cp -r ${m3shapes}/${qt6.qtbase.qtQmlPrefix}/* \
             $out/${qt6.qtbase.qtQmlPrefix}
         fi

         # Copy qml-material
         if [ -d "${qml-material}/${qt6.qtbase.qtQmlPrefix}" ]; then
           cp -r ${qml-material}/${qt6.qtbase.qtQmlPrefix}/* \
             $out/${qt6.qtbase.qtQmlPrefix}
         fi

         # Copy translationManager
         if [ -d "${translationManager}/${qt6.qtbase.qtQmlPrefix}" ]; then
           cp -r ${translationManager}/${qt6.qtbase.qtQmlPrefix}/* \
             $out/${qt6.qtbase.qtQmlPrefix}
         fi

         makeWrapper ${quickshell.packages.${stdenv.hostPlatform.system}.default}/bin/quickshell \
           $out/bin/shell \
           --add-flags "-p $out/share/quickshell" \
           --set QUICKSHELL_CONFIG_DIR "$out/share/quickshell" \
           --set QT_QPA_FONTDIR "${material-symbols}/share/fonts" \
           --prefix QML2_IMPORT_PATH : "$out/lib/qt-${qt6.qtbase.version}/qml" \
           --prefix QML2_IMPORT_PATH : "${translationManager}/${qt6.qtbase.qtQmlPrefix}" \
           --prefix PATH : ${lib.makeBinPath (runtimeDeps ++ [app2unit])} \
           --suffix PATH : /run/current-system/sw/bin \
           --suffix PATH : /etc/profiles/per-user/$USER/bin \
           --suffix PATH : $HOME/.nix-profile/bin

         runHook postInstall
    '';
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
