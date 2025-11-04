{
  pkgs,
  system,
  lib,
  quickshell,
}: let
  app2unit = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "app2unit";
    version = "1.0.3";

    src = pkgs.fetchFromGitHub {
      owner = "Vladimir-csp";
      repo = "app2unit";
      tag = "v${version}";
      hash = "sha256-7eEVjgs+8k+/NLteSBKgn4gPaPLHC+3Uzlmz6XB0930=";
    };

    nativeBuildInputs = [pkgs.makeWrapper];

    buildInputs = with pkgs; [
      bash
      systemd
      coreutils
      findutils
      gnugrep
      gnused
      gawk
      scdoc
      git
      libnotify
    ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp app2unit $out/bin/
      chmod +x $out/bin/app2unit

      wrapProgram $out/bin/app2unit \
        --prefix PATH : ${lib.makeBinPath [
        pkgs.bash
        pkgs.systemd
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.gawk
        pkgs.scdoc
        pkgs.git
        pkgs.libnotify
      ]}

      runHook postInstall
    '';
  };

  runtimeDeps = with pkgs; [
    coreutils
    findutils
    gnugrep
    gawk
    gnused
    bash
    util-linux
    networkmanager
    matugen
    playerctl
    wl-clipboard
    libnotify
    wl-screenrec
    ffmpeg
    foot
    polkit
    hyprland
    systemd
    app2unit
  ];
in rec {
  inherit runtimeDeps;

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
      cp -r Configs $out/share/quickshell/
      cp -r Data $out/share/quickshell/
      cp -r Helpers $out/share/quickshell/
      cp -r Modules $out/share/quickshell/
      cp -r Widgets $out/share/quickshell/
      cp -r Assets $out/share/quickshell/
      cp shell.qml $out/share/quickshell/

      mkdir -p $out/share/quickshell/Assets
      cp -r ${keystate-bin}/bin/keystate-bin $out/share/quickshell/Assets/keystate-bin

      mkdir -p $out/bin
      cp -r ${app2unit}/bin/app2unit $out/bin/app2unit
      cp -r ${keystate-bin}/bin/keystate-bin $out/bin/keystate-bin
      makeWrapper ${quickshell.packages.${system}.default}/bin/quickshell $out/bin/shell \
        --add-flags "-p $out/share/quickshell" \
        --set QUICKSHELL_CONFIG_DIR "$out/share/quickshell" \
        --suffix PATH : ${lib.makeBinPath runtimeDeps} \
        --suffix PATH : /run/current-system/sw/bin \
        --suffix PATH : /etc/profiles/per-user/$USER/bin \
        --suffix PATH : $HOME/.nix-profile/bin
    '';
  };

  default = shell;
}
