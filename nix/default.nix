{
  pkgs,
  system,
  lib,
  quickshell,
}: rec {
  keystate-bin = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "keystate-bin";
    version = "0.1.0";
    src = ../Assets;
    buildInputs = [pkgs.go];
    buildPhase = ''
      export HOME=$TMPDIR
      go build -o ${pname} keystate.go
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp -r ${pname} $out/bin
    '';
  };

  material-symbols = pkgs.stdenvNoCC.mkDerivation {
    pname = "material-symbols";
    version = "4.0.0-unstable-2025-04-11";

    src = pkgs.fetchFromGitHub {
      owner = "google";
      repo = "material-design-icons";
      rev = "941fa95d7f6084a599a54ca71bc565f48e7c6d9e";
      hash = "sha256-5bcEh7Oetd2JmFEPCcoweDrLGQTpcuaCU8hCjz8ls3M=";
      sparseCheckout = ["variablefont"];
    };

    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp $src $out/share/fonts/truetype/MaterialSymbolsOutlined.ttf
    '';
  };

  shell = pkgs.stdenv.mkDerivation {
    pname = "shell";
    version = "0.1.0";
    src = ../.;
    nativeBuildInputs = [pkgs.makeWrapper];

    buildPhase = ''
      substituteInPlace shell.qml \
        --replace-fail 'ShellRoot {' 'ShellRoot { settings.watchFiles: false'
    '';

    installPhase = ''
      mkdir -p $out/share/quickshell
      cp -r Components $out/share/quickshell/
      cp -r Data $out/share/quickshell/
      cp -r Helpers $out/share/quickshell/
      cp -r Modules $out/share/quickshell/
      cp -r Widgets $out/share/quickshell/
      cp -r Assets $out/share/quickshell/
      cp shell.qml $out/share/quickshell/

      mkdir -p $out/share/quickshell/Assets
      cp -r ${keystate-bin}/bin/keystate-bin $out/share/quickshell/Assets/

      mkdir -p $out/share/quickshell/Configs
      cp Configs/*.json $out/share/quickshell/Configs/

      mkdir -p $out/bin
      makeWrapper ${quickshell.packages.${system}.default}/bin/quickshell $out/bin/shell \
        --add-flags "-p $out/share/quickshell" \
        --set QUICKSHELL_CONFIG_DIR "$out/share/quickshell" \
        --prefix PATH : ${lib.makeBinPath [
        pkgs.matugen
        pkgs.playerctl
        pkgs.wl-clipboard
        pkgs.libnotify
        pkgs.wl-screenrec
        pkgs.ffmpeg
        pkgs.foot
        pkgs.polkit
      ]}
    '';
  };

  default = shell;
}
