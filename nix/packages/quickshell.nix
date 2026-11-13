{
    lib,
    stdenv,
    fetchFromGitHub,
    pkg-config,
    cmake,
    ninja,
    spirv-tools,
    vulkan-headers,
    qt6,
    cpptrace,
    jemalloc,
    cli11,
    wayland,
    wayland-protocols,
    wayland-scanner,
    libxcb,
    libdrm,
    libgbm,
    pipewire,
    pam,
    glib,
    polkit,
}:
stdenv.mkDerivation (finalAttrs: {
    pname = "quickshell";
    version = "unstable-13-11-2026-53c28300";

    src = fetchFromGitHub {
        owner = "duxlabs-dev";
        repo = "dux-qt-base";
        rev = "53c28300add0c28df0d4c765a6c70263d8c02b63";
        hash = "sha256-St1/kUOOnKojdkKGSo8VhBVdbZ67u9Db+iSlYw9fF/Q=";
    };

    # patches = [
    #     ../../Assets/patches/0001-feat-add-qml-disk-cache-and-opt-in-render-control-with-partial-damage.patch
    # ];

    nativeBuildInputs = [
        cmake
        ninja
        qt6.qtshadertools
        spirv-tools
        vulkan-headers
        wayland-scanner
        qt6.wrapQtAppsHook
        pkg-config
    ];

    buildInputs = [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtwayland
        qt6.qtsvg
        cli11
        wayland
        wayland-protocols
        libdrm
        libgbm
        cpptrace
        jemalloc
        libxcb
        pam
        pipewire
        glib
        polkit
    ];

    cmakeFlags = [
        (lib.cmakeFeature "DISTRIBUTOR" "Nixpkgs")
        (lib.cmakeFeature "INSTALL_QML_PREFIX" qt6.qtbase.qtQmlPrefix)
        (lib.cmakeFeature "GIT_REVISION" "tag-v${finalAttrs.version}")
    ];

    cmakeBuildType = "RelWithDebInfo";
    separateDebugInfo = true;
    dontStrip = false;

    meta = {
        homepage = "https://quickshell.org";
        description = "Flexible QtQuick based desktop shell toolkit";
        license = lib.licenses.lgpl3Only;
        platforms = lib.platforms.linux;
        mainProgram = "quickshell";
        maintainers = with lib.maintainers; [outfoxxed];
    };
})
