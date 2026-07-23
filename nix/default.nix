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
    wl-screenrec-fork,
    util-linux,
    matugen,
    wl-clipboard,
    ffmpeg,
    wireplumber,
    foot,
    rembg,
    kdePackages,
    polkit,
    patchelf,
    hyprland,
    qt6,
    python3Packages,
    callPackage,
    cmake,
}: let
    app2unit = callPackage ./packages/app2unit.nix {};
    material-symbols = callPackage ./packages/material-symbols.nix {};
    m3shapes = callPackage ./plugins/m3Shapes.nix {};
    another-ripple = callPackage ./plugins/AnotherRipple.nix {};
    vastPlugin = callPackage ./plugins/vastPlugin.nix {};
    vastctl = callPackage ./packages/vastctl.nix {};

    runtimeDeps = [
        ## utils
        findutils
        gnugrep
        gawk
        gnused
        util-linux

        ## For created a depth wallpaper
        rembg

        ## pipewire for changing sinks
        wireplumber

        ## network, polkit, notify
        iw
        libnotify
        polkit

        ## Icons & symbols and weather icons
        weather-icons
        material-symbols

        ## generated colors, copy-paste, screenrecord, thumbnails
        matugen
        wl-clipboard
        wl-screenrec-fork
        ffmpeg

        ## terminal for running apps with app2unit and a compositor
        foot
        hyprland

        ## Qt packages
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
            qt6.qtgraphs
            qt6.qt5compat
            kdePackages.qtmultimedia
        ];

        postPatch = ''
            substituteInPlace Qml/shell.qml \
              --replace-fail 'ShellRoot {' 'ShellRoot { settings.watchFiles: false'
        '';

        dontUseCmakeConfigure = true;
        dontWrapQtApps = true;

        buildPhase = ''
            runHook preBuild

            echo "Compile Translations..."
            if [ -d "translations" ]; then
                ${qt6.qttools}/bin/lrelease translations/*.ts
            fi

            echo "Cleaning old shaders..."
            find Assets/shaders -name "*.qsb" -delete

            echo "Compile shaders..."
            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/ImageTransition.vert.qsb \
                   Assets/shaders/ImageTransition.vert

            for name in fade wipeDown circleExpand dissolve splitHorizontal slideUp pixelate diagonalWipe boxExpand roll; do
                echo "Compiling ''${name}.frag..."
                ${qt6.qtshadertools}/bin/qsb \
                    --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                    -o Assets/shaders/transitions/''${name}.frag.qsb \
                       Assets/shaders/transitions/''${name}.frag
            done

            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/borderProgress.vert.qsb \
                   Assets/shaders/borderProgress.vert
            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/borderProgress.frag.qsb \
                   Assets/shaders/borderProgress.frag
            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/wavy.vert.qsb \
                   Assets/shaders/wavy.vert
            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/wavy.frag.qsb \
                   Assets/shaders/wavy.frag
            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/waveForm.vert.qsb \
                   Assets/shaders/waveForm.vert
            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/waveForm.frag.qsb \
                   Assets/shaders/waveForm.frag

            runHook postBuild
        '';

        installPhase = ''
            runHook preInstall

            mkdir -p $out/share/quickshell
            shopt -s extglob
            cp -r !(build) $out/share/quickshell/ 2>/dev/null || true

            install -Dm755 ${app2unit}/bin/app2unit \
              $out/bin/app2unit

            install -Dm755 ${vastctl}/bin/vastctl \
              $out/bin/vastctl

            mkdir -p $out/share
            cp -r ${vastctl}/share/bash-completion $out/share/ 2>/dev/null || true
            cp -r ${vastctl}/share/fish $out/share/ 2>/dev/null || true
            cp -r ${vastctl}/share/zsh $out/share/ 2>/dev/null || true
            cp -r ${vastctl}/share/nushell $out/share/ 2>/dev/null || true

            mkdir -p $out/share/fonts/truetype
            cp -r ${material-symbols}/share/fonts/truetype/* \
              $out/share/fonts/truetype/

            mkdir -p $out/${qt6.qtbase.qtQmlPrefix}

            if [ -d "${m3shapes}/${qt6.qtbase.qtQmlPrefix}" ]; then
              cp -r ${m3shapes}/${qt6.qtbase.qtQmlPrefix}/* \
                $out/${qt6.qtbase.qtQmlPrefix}
            fi

            if [ -d "${another-ripple}/${qt6.qtbase.qtQmlPrefix}" ]; then
              cp -r ${another-ripple}/${qt6.qtbase.qtQmlPrefix}/* \
                $out/${qt6.qtbase.qtQmlPrefix}
            fi

            if [ -d "${vastPlugin}/${qt6.qtbase.qtQmlPrefix}" ]; then
              cp -r ${vastPlugin}/${qt6.qtbase.qtQmlPrefix}/* \
                $out/${qt6.qtbase.qtQmlPrefix}
            fi

            makeWrapper ${quickshell.packages.${stdenv.hostPlatform.system}.default}/bin/quickshell \
              $out/bin/shell \
                --add-flags "-p $out/share/quickshell/Qml" \
                --set QUICKSHELL_CONFIG_DIR "$out/share/quickshell" \
                --set QT_QPA_FONTDIR "${material-symbols}/share/fonts/truetype" \
                --prefix QML2_IMPORT_PATH : "$out/lib/qt-${qt6.qtbase.version}/qml" \
                --prefix QML2_IMPORT_PATH : "${qt6.qt5compat}/${qt6.qtbase.qtQmlPrefix}" \
                --prefix QML2_IMPORT_PATH : "${qt6.qtgraphs}/${qt6.qtbase.qtQmlPrefix}" \
                --prefix QML2_IMPORT_PATH : "${another-ripple}/${qt6.qtbase.qtQmlPrefix}" \
                --prefix QML2_IMPORT_PATH : "${vastPlugin}/${qt6.qtbase.qtQmlPrefix}" \
                --prefix PATH : ${lib.makeBinPath (runtimeDeps ++ [app2unit])} \
                --suffix PATH : /run/current-system/sw/bin \

            runHook postInstall
        '';
    };
in {
    inherit
        shell
        vastctl
        material-symbols
        app2unit
        runtimeDeps
        ;
    default = shell;
}
