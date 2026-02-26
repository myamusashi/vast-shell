{
    lib,
    stdenv,
    cmake,
    ninja,
    fetchFromGitHub,
    qt6,
}:
stdenv.mkDerivation {
    pname = "AnotherRipple";
    version = "unstable-2026-02-26";

    src =
        fetchFromGitHub {
            owner = "myamusashi";
            repo = "Another-Ripple";
            rev = "917a89a4dde3f40d08945ae0e86b9a5128b96130";
            hash = "sha256-4xZ0nh9lRCLrn0T6DeRIFv9eMRAk/1UDTrZz/b6HT40=";
        }
        + "/AnotherRipple";

    nativeBuildInputs = [
        cmake
        ninja
        qt6.wrapQtAppsHook
    ];

    buildInputs = [
        qt6.qtbase
        qt6.qtdeclarative
    ];

    cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
        "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
        (lib.cmakeFeature "INSTALL_QMLDIR" "lib/qt-6/qml")
    ];

    dontWrapQtApps = true;

    postInstall = ''
        qmlDir="$out/lib/qt-6/qml/AnotherRipple"
        qtLibDir="${qt6.qtbase.outPath}/lib"

        for lib in "$qmlDir/libAnotherRipple.so" "$qmlDir/libAnotherRippleplugin.so"; do
          if [ -f "$lib" ]; then
            patchelf --set-rpath "$qmlDir:$qtLibDir" "$lib"
          fi
        done
    '';

    meta = with lib; {
        description = "A Ripple effect in QML, that can be used everywhere.";
        homepage = "https://github.com/mmjvox/Another-Ripple";
        platforms = platforms.linux;
        license = licenses.mit; # Adjust if license is different
    };
}
