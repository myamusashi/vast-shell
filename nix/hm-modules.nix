{
  self,
  apple-fonts,
}: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.quickshell-shell;
  system = pkgs.system;

  packages = import ./default.nix {
    inherit pkgs system lib;
    quickshell = null;
  };
  runtimeDeps = packages.runtimeDeps;

  material-symbols = pkgs.material-symbols.overrideAttrs (oldAttrs: {
    version = "4.0.0-unstable-2025-04-11";

    src = pkgs.fetchFromGitHub {
      owner = "google";
      repo = "material-design-icons";
      rev = "bb04090f930e272697f2a1f0d7b352d92dfeee43";
      hash = "sha256-5bcEh7Oetd2JmFEPCcoweDrLGQTpcuaCU8hCjz8ls3M=";
      sparseCheckout = ["variablefont"];
    };
  });
in {
  options.programs.quickshell-shell = {
    enable = lib.mkEnableOption "quickshell shell";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${system}.default;
      description = "The quickshell-shell package to use";
    };

    installFonts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "install required fonts";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Extra packages to make available to quickshell";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [cfg.package]
      ++ runtimeDeps
      ++ cfg.extraPackages
      ++ lib.optionals cfg.installFonts [
        apple-fonts.packages.${system}.sf-pro
        apple-fonts.packages.${system}.sf-mono-nerd
        material-symbols
      ];

    fonts.fontconfig.enable = lib.mkDefault true;

    systemd.user.services.quickshell-shell = {
      Unit = {
        Description = "Shell widget using quickshell";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "exec";
        ExecStart = "${cfg.package}/bin/shell";
        Restart = "on-failure";
        Slice = "session.slice";
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
