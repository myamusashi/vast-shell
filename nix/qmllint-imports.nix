{
    pkgs,
    quickshell,
    vastPlugin,
    m3Shapes,
    anotherRipple,
}: let
    prefix = pkgs.qt6.qtbase.qtQmlPrefix;

    packages = [
        quickshell
        vastPlugin
        m3Shapes
        anotherRipple
        pkgs.kdePackages.qtmultimedia
        pkgs.qt6.qt5compat
        pkgs.qt6.qtgraphs
        pkgs.qt6.qtdeclarative
        pkgs.qt6.qtwayland
    ];

    roots = map (pkg: "${pkg}/${prefix}") packages;
in {
    inherit roots;
    searchPath = builtins.concatStringsSep ":" roots;

    derivation = pkgs.runCommand "vast-shell-qmllint-modules" {
        nativeBuildInputs = packages;
    } ''
        mkdir -p "$out"
        echo "fetched ${toString (builtins.length roots)} qmllint module roots"
    '';
}
