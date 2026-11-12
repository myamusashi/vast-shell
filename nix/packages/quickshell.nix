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
    version = "unstable-10-22-2026-9b0f339b";

    src = fetchFromGitHub {
        owner = "quickshell-mirror";
        repo = "quickshell";
        rev = "9b0f339b19057f4731bf3b48293307d7ef241671";
        hash = "sha256-TiCGqLMpNIy7FERewgfKVluPsLVF96uc6x6xwZnMjdQ=";
    };

    patches = [
        ../../Assets/patches/0001-feat-add-qml-disk-cache-and-opt-in-render-control-with-partial-damage.patch
    ];

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
