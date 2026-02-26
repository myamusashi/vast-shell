{
    lib,
    stdenv,
    cmake,
    ninja,
    fetchFromGitHub,
    qt5,
    qt6,
}:
stdenv.mkDerivation {
    pname = "AnotherRipple";
    version = "unstable-2022-11-20";

    src =
        fetchFromGitHub {
            owner = "mmjvox";
            repo = "Another-Ripple";
            rev = "919d73f45240fd2aad6b871023664c31d6111e21";
            hash = "sha256-NmmFhkQDEA5n5vm+TUq48ilsnfit5C/4cvrLv46bb6E=";
        }
        + "/AnotherRipple";

    nativeBuildInputs = [
        cmake
        ninja
        qt5.wrapQtAppsHook
    ];

    buildInputs = [
        qt5.qtbase
        qt5.qtdeclarative
    ];

    cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    ];

    dontWrapQtApps = true;

    postPatch = ''
        substituteInPlace CMakeLists.txt \
            --replace-fail "add_library(AnotherRipple STATIC" "add_library(AnotherRipple SHARED"
    '';

    # CMakeLists.txt has no install() rules so we do everything manually
    installPhase = ''
        runHook preInstall

        install -Dm644 $src/include/AnotherRipple.h \
            $out/include/AnotherRipple.h
        for header in $src/include/AnotherRipple/*.h; do
            install -Dm644 "$header" \
                "$out/include/AnotherRipple/$(basename $header)"
        done

        install -Dm755 libAnotherRipple.so \
        $out/${qt6.qtbase.qtQmlPrefix}/AnotherRipple/libAnotherRipple.so

        mkdir -p $out/${qt6.qtbase.qtQmlPrefix}/AnotherRipple
        cat > $out/${qt6.qtbase.qtQmlPrefix}/AnotherRipple/qmldir <<EOF
          module AnotherRipple
          plugin AnotherRipple
        EOF

        runHook postInstall
    '';

    postFixup = ''
        patchelf --set-rpath "${qt6.qtbase.outPath}/lib" \
            $out/${qt6.qtbase.qtQmlPrefix}/AnotherRipple/libAnotherRipple.so
    '';

    meta = with lib; {
        description = " This is a Ripple effect in QML, that can be used everywhere. ";
        homepage = "https://github.com/mmjvox/Another-Ripple";
        platforms = platforms.linux;
    };
}
