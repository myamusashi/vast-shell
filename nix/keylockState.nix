{
    lib,
    stdenv,
    cmake,
    qt6,
    patchelf,
}:
stdenv.mkDerivation {
    pname = "translation-manager-plugin";
    version = "1.0";

    src = ../plugins/KeylockState;

    nativeBuildInputs = [
        cmake
        qt6.wrapQtAppsHook
        patchelf
    ];

    buildInputs = [
        qt6.qtbase
        qt6.qtdeclarative
    ];

    cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DQML_INSTALL_DIR=${placeholder "out"}/${qt6.qtbase.qtQmlPrefix}"
    ];

    postInstall = ''
        if [ -d "$out/KeylockState" ]; then
          mkdir -p $out/${qt6.qtbase.qtQmlPrefix}/KeylockState
          cp -r $out/KeylockState/* $out/${qt6.qtbase.qtQmlPrefix}/KeylockState/
          rm -rf $out/KeylockState
        fi

        if [ ! -f "$out/${qt6.qtbase.qtQmlPrefix}/KeylockState/qmldir" ]; then
          if [ -f "$NIX_BUILD_TOP/build/KeylockState/qmldir" ]; then
            cp $NIX_BUILD_TOP/build/KeylockState/qmldir \
              $out/${qt6.qtbase.qtQmlPrefix}/KeylockState/
          fi
        fi

        PLUGIN_DIR="$out/${qt6.qtbase.qtQmlPrefix}/KeylockState"

        if [ -f "$PLUGIN_DIR/libKeylockStateplugin.so" ]; then
          patchelf --set-rpath "$PLUGIN_DIR:${lib.makeLibraryPath [qt6.qtbase qt6.qtdeclarative]}" \
            "$PLUGIN_DIR/libKeylockStateplugin.so"
        fi

        if [ -f "$PLUGIN_DIR/libKeylockState.so" ]; then
          patchelf --set-rpath "${lib.makeLibraryPath [qt6.qtbase qt6.qtdeclarative]}" \
            "$PLUGIN_DIR/libKeylockState.so"
        fi
    '';

    meta = with lib; {
        description = "Keylock state QML plugin";
        platforms = platforms.linux;
    };
}
