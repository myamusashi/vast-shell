{
    lib,
    stdenv,
    cmake,
    qt6,
    patchelf,
    pipewire,
    pkg-config,
}:
stdenv.mkDerivation {
    pname = "vast-plugin";
    version = "1.0";

    src = ../plugins/Vast;

    nativeBuildInputs = [
        cmake
        qt6.wrapQtAppsHook
        patchelf
        pkg-config
    ];

    buildInputs = [
        qt6.qtbase
        qt6.qtdeclarative
        pipewire
    ];

    cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    ];

    postInstall = ''
        PLUGIN_DIR="$out/${qt6.qtbase.qtQmlPrefix}/Vast"

        # needs to find PipeWire + Qt at runtime
        if [ -f "$PLUGIN_DIR/libVastPlugin.so" ]; then
          patchelf --set-rpath \
            "$PLUGIN_DIR:${lib.makeLibraryPath [qt6.qtbase qt6.qtdeclarative pipewire]}" \
            "$PLUGIN_DIR/libVastPlugin.so"
        fi

        # only needs Qt (it dlopen-loads the backing lib from same dir)
        if [ -f "$PLUGIN_DIR/libVastQmlPlugin.so" ]; then
          patchelf --set-rpath \
            "$PLUGIN_DIR:${lib.makeLibraryPath [qt6.qtbase qt6.qtdeclarative]}" \
            "$PLUGIN_DIR/libVastQmlPlugin.so"
        fi
    '';

    meta = with lib; {
        description = "Unified Vast Plugin for Quickshell";
        platforms = platforms.linux;
    };
}
