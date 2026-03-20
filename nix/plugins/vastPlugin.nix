{
    lib,
    stdenv,
    cmake,
    qt6,
    patchelf,
    pipewire,
    ddcutil,
    pkg-config,
}:
stdenv.mkDerivation {
    pname = "vast-plugin";
    version = "1.0";
    src = ../../Plugins/Vast;

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
        ddcutil
    ];

    cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    ];

    postInstall = ''
        PLUGIN_DIR="$out/${qt6.qtbase.qtQmlPrefix}/Vast"

        if [ -f "$PLUGIN_DIR/libVastPlugin.so" ]; then
          patchelf --set-rpath \
            "$PLUGIN_DIR:${lib.makeLibraryPath [
            qt6.qtbase
            qt6.qtdeclarative
            pipewire
            ddcutil
        ]}" \
            "$PLUGIN_DIR/libVastPlugin.so"
        fi

        if [ -f "$PLUGIN_DIR/libVastQmlPlugin.so" ]; then
          patchelf --set-rpath \
            "$PLUGIN_DIR:${lib.makeLibraryPath [
            qt6.qtbase
            qt6.qtdeclarative
        ]}" \
            "$PLUGIN_DIR/libVastQmlPlugin.so"
        fi
    '';

    meta = with lib; {
        description = "Unified Vast Plugin for Quickshell";
        license = licenses.gpl3Plus;
        platforms = platforms.linux;
    };
}
