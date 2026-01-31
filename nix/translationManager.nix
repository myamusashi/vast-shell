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

  src = ../plugins/TranslationManager;

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
    if [ -d "$out/TranslationManager" ]; then
      mkdir -p $out/${qt6.qtbase.qtQmlPrefix}/TranslationManager
      cp -r $out/TranslationManager/* $out/${qt6.qtbase.qtQmlPrefix}/TranslationManager/
      rm -rf $out/TranslationManager
    fi

    if [ ! -f "$out/${qt6.qtbase.qtQmlPrefix}/TranslationManager/qmldir" ]; then
      if [ -f "$NIX_BUILD_TOP/build/TranslationManager/qmldir" ]; then
        cp $NIX_BUILD_TOP/build/TranslationManager/qmldir \
          $out/${qt6.qtbase.qtQmlPrefix}/TranslationManager/
      fi
    fi

    PLUGIN_DIR="$out/${qt6.qtbase.qtQmlPrefix}/TranslationManager"

    # Set RPATH untuk libTranslationManagerplugin.so
    if [ -f "$PLUGIN_DIR/libTranslationManagerplugin.so" ]; then
      patchelf --set-rpath "$PLUGIN_DIR:${lib.makeLibraryPath [qt6.qtbase qt6.qtdeclarative]}" \
        "$PLUGIN_DIR/libTranslationManagerplugin.so"
    fi

    # Set RPATH untuk libTranslationManager.so jika ada
    if [ -f "$PLUGIN_DIR/libTranslationManager.so" ]; then
      patchelf --set-rpath "${lib.makeLibraryPath [qt6.qtbase qt6.qtdeclarative]}" \
        "$PLUGIN_DIR/libTranslationManager.so"
    fi
  '';

  meta = with lib; {
    description = "Translation Manager QML plugin";
    platforms = platforms.linux;
  };
}
