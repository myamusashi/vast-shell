# Module search paths qmllint needs to resolve every import in Qml/.
#
# Quickshell normally hands these to tooling through the .qmlls.ini it writes
# into its per-shell vfs build dir at runtime. That file only exists while a
# shell is running, so CI evaluates this expression instead and the workflow
# feeds the result to qmllint via -I flags.
#
# The paths mirror the QML2_IMPORT_PATH the `qs` wrapper sets in
# nix/default.nix. Keep the two in sync.
{
  pkgs,
  quickshell,
  vastPlugin,
  m3Shapes,
  anotherRipple,
}:
let
  prefix = pkgs.qt6.qtbase.qtQmlPrefix;
in
builtins.concatStringsSep ":" [
  # qs.* — synthesised by Assets/shell/gen-qs-modules.sh, prepended by
  # the caller because it is not a store path.
  "${quickshell}/${prefix}"
  "${vastPlugin}/${prefix}"
  "${m3Shapes}/${prefix}"
  "${anotherRipple}/${prefix}"
  "${pkgs.kdePackages.qtmultimedia}/${prefix}"
  "${pkgs.qt6.qt5compat}/${prefix}"
  "${pkgs.qt6.qtgraphs}/${prefix}"
  "${pkgs.qt6.qtdeclarative}/${prefix}"
  "${pkgs.qt6.qtwayland}/${prefix}"
]
