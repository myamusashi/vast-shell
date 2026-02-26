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
            rev = "0eb6610b1270383fab0a4a2af5ffc40dbcf4df54";
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
        pluginPath="$out/lib/qt-6/qml/AnotherRipple/libAnotherRipple.so"
        if [ -f "$pluginPath" ]; then
            patchelf --set-rpath "$out/lib/qt-6/qml/AnotherRipple:${qt6.qtbase.outPath}/lib" "$pluginPath"
        fi
    '';

    meta = with lib; {
        description = "A Ripple effect in QML, that can be used everywhere.";
        homepage = "https://github.com/mmjvox/Another-Ripple";
        platforms = platforms.linux;
        license = licenses.mit; # Adjust if license is different
    };
}
