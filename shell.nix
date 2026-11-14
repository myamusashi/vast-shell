{
    pkgs,
    qmlformat-rs,
}:
(pkgs.mkShell.override {stdenv = pkgs.clangStdenv;}) {
    nativeBuildInputs = with pkgs; [
        qt6.wrapQtAppsHook
        cmake
        ninja
    ];

    buildInputs = with pkgs; [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtmultimedia
        qt6.qtgraphs
        qt6.qt5compat
        qt6.qttranslations
        ddcutil
        pipewire.dev
        wayland
        wayland-protocols
        mold
    ];

    packages = with pkgs; [
        go
        gopls
        golangci-lint
        nil
        pkg-config
        wayland-scanner
        qt6.qttools
        qt6.qtshadertools
        python314Packages.pillow
        python314Packages.materialyoucolor
        dbus
        clang
        clazy
        clang-tools
        gdb
        qmlformat-rs
    ];

    shellHook = ''
        FLAGS='--glsl "450,330,300 es" --hlsl 50 --msl 12'
        FRAG_ONLY_FLAGS='--glsl "150,330,300 es" --hlsl 50 --msl 12'

        compile_if_missing() {
            local output="$1"
            local input="$2"
            local flags="''${3:-$FLAGS}"

            if [ ! -f "$output" ]; then
                echo "Compiling: $output"
                eval qsb $flags -o "$output" "$input"
            fi
        }
        TRANSITIONS=(
            fade wipeDown circleExpand dissolve splitHorizontal
            hexTile slideUp pixelate diagonalWipe boxExpand roll
        )
        for name in "''${TRANSITIONS[@]}"; do
            compile_if_missing "Assets/shaders/transitions/$name.frag.qsb" "Assets/shaders/transitions/$name.frag" "$FRAG_ONLY_FLAGS"
        done

        SHADERS=(borderProgress wavy waveForm circleWave cornerFillet drawerShape arcGauge linearProgress triangleCaret waveFill celestialArc)
        for shader in "''${SHADERS[@]}"; do
            compile_if_missing "Assets/shaders/$shader.frag.qsb" "Assets/shaders/$shader.frag" "$FRAG_ONLY_FLAGS"
        done
        echo "vast-shell environment (clang toolchain)"
    '';
}
