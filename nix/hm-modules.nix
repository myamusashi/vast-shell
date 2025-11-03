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
      description = "Whether to install required fonts";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Extra packages to make available to quickshell";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [
        cfg.package
        pkgs.matugen
        pkgs.playerctl
        pkgs.wl-clipboard
        pkgs.libnotify
        pkgs.wl-screenrec
        pkgs.ffmpeg
        pkgs.foot
        pkgs.polkit
      ]
      ++ cfg.extraPackages
      ++ lib.optionals cfg.installFonts [
        apple-fonts.packages.${system}.sf-pro
        apple-fonts.packages.${system}.sf-pro-nerd
        apple-fonts.packages.${system}.sf-mono
        apple-fonts.packages.${system}.sf-mono-nerd
        (pkgs.nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
      ];

    # Enable fontconfig
    fonts.fontconfig.enable = lib.mkDefault true;

    # Copy config files to user directory
    home.file.".config/shell/colors.json".source = "${cfg.package}/share/quickshell/Configs/colors.json";
    home.file.".config/shell/configurations.json".source = "${cfg.package}/share/quickshell/Configs/configurations.json";

    # Systemd service
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
        Environment = [
          "PATH=${lib.makeBinPath ([
              cfg.package
              pkgs.matugen
              pkgs.playerctl
              pkgs.wl-clipboard
              pkgs.libnotify
              pkgs.wl-screenrec
              pkgs.ffmpeg
              pkgs.foot
              pkgs.polkit
            ]
            ++ cfg.extraPackages)}"
        ];
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
