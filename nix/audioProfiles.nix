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
    pname = "audio-profiles-plugin";
    version = "1.0";

    src = ../plugins/AudioProfiles;

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
        PLUGIN_DIR="$out/${qt6.qtbase.qtQmlPrefix}/AudioProfiles"

        # needs to find PipeWire + Qt at runtime
        if [ -f "$PLUGIN_DIR/libAudioProfilesPlugin.so" ]; then
          patchelf --set-rpath \
            "$PLUGIN_DIR:${lib.makeLibraryPath [qt6.qtbase qt6.qtdeclarative pipewire]}" \
            "$PLUGIN_DIR/libAudioProfilesPlugin.so"
        fi

        # only needs Qt (it dlopen-loads the backing lib from same dir)
        if [ -f "$PLUGIN_DIR/libAudioProfilesQmlPlugin.so" ]; then
          patchelf --set-rpath \
            "$PLUGIN_DIR:${lib.makeLibraryPath [qt6.qtbase qt6.qtdeclarative]}" \
            "$PLUGIN_DIR/libAudioProfilesQmlPlugin.so"
        fi
    '';

    meta = with lib; {
        description = "Expose audio profiles model";
        platforms = platforms.linux;
    };
}
