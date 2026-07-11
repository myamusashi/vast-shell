{self}: {
    config,
    lib,
    pkgs,
    ...
}: let
    cfg = config.programs.quickshell-shell;

    material-symbols = pkgs.callPackage ./packages/material-symbols.nix {};
in {
    options.programs.quickshell-shell = {
        enable = lib.mkEnableOption "quickshell shell";

        package = lib.mkOption {
            type = lib.types.package;
            default = self.packages.${pkgs.system}.default;
            description = "The quickshell-shell package to use";
        };

        installFonts = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Install required fonts (recommended)";
        };

        extraPackages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [];
            description = "Extra packages to make available to quickshell";
        };
    };

    config = lib.mkIf cfg.enable {
        environment.systemPackages =
            [cfg.package]
            ++ cfg.extraPackages;

        fonts.packages = lib.optionals cfg.installFonts [
            material-symbols
            pkgs.weather-icons
        ];

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
