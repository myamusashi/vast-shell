{self}: {
    config,
    lib,
    pkgs,
    ...
}: let
    cfg = config.programs.quickshell-shell;

    compositorName = lib.getName cfg.greetd.compositorPackage;
    compositorVersion = lib.getVersion cfg.greetd.compositorPackage;
    isLegacyHyprland = compositorVersion != "" && lib.versionOlder compositorVersion "0.55";

    greeterLauncher = pkgs.writeShellScript "vast-greeter-launch" ''
        export PATH="${cfg.greetd.compositorPackage}/bin:${cfg.package}/bin:$PATH"
        export VAST_QUICKSHELL_BIN="${cfg.package}/bin/quickshell"
        export VAST_GREETER_QML="${cfg.package}/share/quickshell/Qml/greeter.qml"
        ${lib.optionalString (cfg.greetd.exitCommand != null) ''
            export VAST_GREETER_EXIT_CMD=${lib.escapeShellArg cfg.greetd.exitCommand}
        ''}
        exec "${cfg.package}/share/quickshell/Assets/shell/greeter-launch.sh"
    '';

    greeterConfig =
        if lib.hasPrefix "mango" compositorName then
            pkgs.writeText "mango-greeter.conf" ''
                animations=0
                layer_animations=0
                root_color=0x000000ff
                ${cfg.greetd.extraConfig}
                exec_once=${greeterLauncher}
            ''
        else if lib.hasPrefix "sway" compositorName then
            pkgs.writeText "sway-greeter.conf" ''
                output * bg #000000 solid_color
                ${cfg.greetd.extraConfig}
                exec ${greeterLauncher}
            ''
        else if lib.hasPrefix "hyprland" compositorName && isLegacyHyprland then
            pkgs.writeText "hyprland-greeter.conf" ''
                animations {
                    enabled = false
                }
                misc {
                    disable_hyprland_logo = true
                    disable_splash_rendering = true
                    background_color = 0x000000
                }
                ${cfg.greetd.extraConfig}
                exec-once = ${greeterLauncher}
            ''
        else if lib.hasPrefix "hyprland" compositorName then
            pkgs.writeText "hyprland-greeter.lua" ''
                hl.config({
                    animations = {
                        enabled = false,
                    },
                    misc = {
                        disable_hyprland_logo = true,
                        disable_splash_rendering = true,
                        background_color = 0x000000,
                    },
                })
                ${cfg.greetd.extraConfig}
                hl.on("hyprland.start", function()
                    hl.exec_cmd(${builtins.toJSON "${greeterLauncher}"})
                end)
            ''
        else if lib.hasPrefix "niri" compositorName then
            pkgs.writeText "niri-greeter.kdl" ''
                animations {
                    off
                }
                layout {
                    background-color "#000000"
                }
                ${cfg.greetd.extraConfig}
                spawn-at-startup "${greeterLauncher}"
            ''
        else
            pkgs.writeText "greeter.conf" ''
                ${cfg.greetd.extraConfig}
                exec=${greeterLauncher}
            '';

    defaultGreeterCommand =
        if lib.hasPrefix "river" compositorName then
            "${lib.getExe cfg.greetd.compositorPackage} -c ${greeterLauncher}"
        else if lib.hasPrefix "labwc" compositorName then
            "${lib.getExe cfg.greetd.compositorPackage} -S ${greeterLauncher}"
        else
            "${lib.getExe cfg.greetd.compositorPackage} -c ${greeterConfig}";
in {
    options.programs.quickshell-shell = {
        enable = lib.mkEnableOption "quickshell shell";

        systemd = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Start vast-shell with systemd-services";
        };

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

        greetd = {
            enable = lib.mkEnableOption "greetd login manager with the quickshell greeter";

            user = lib.mkOption {
                type = lib.types.str;
                default = "greeter";
                description = "The user to run the greeter session";
            };

            restart = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = ''
                    Restart the greeter when it exits. Disable while testing to
                    drop back to a console instead of respawning the greeter.
                '';
            };

            compositorPackage = lib.mkOption {
                type = lib.types.package;
                default = pkgs.mango;
                description = ''
                    The compositor used to run the greeter. Must implement the
                    ext-session-lock-v1 protocol (required by WlSessionLock in
                    the greeter). Note: cage does NOT implement it, so the
                    greeter would run but never display.
                '';
            };

            extraConfig = lib.mkOption {
                type = lib.types.lines;
                default = "";
                description = "Extra lines appended to the greeter compositor config";
            };

            exitCommand = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                    Optional command run after quickshell exits to cleanly close
                    the greeter compositor. When null, greeter-launch.sh
                    auto-detects the running compositor (mango, hyprland, sway,
                    niri, labwc, river) and exits it cleanly.
                '';
            };

            command = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                    Optional override for greetd's default_session.command when
                    using a custom compositor not covered by the built-in presets.
                '';
            };
        };
    };

    config = lib.mkIf cfg.enable {
        environment.systemPackages = [cfg.package] ++ cfg.extraPackages;

        programs.gpu-screen-recorder.enable = true;

        fonts.packages = lib.optionals cfg.installFonts [
            pkgs.weather-icons
        ];

        systemd.user.services.quickshell-shell = {
            enable = cfg.systemd;
            description = "Shell widget using quickshell";
            after = ["graphical-session.target"];
            partOf = ["graphical-session.target"];
            wantedBy = ["graphical-session.target"];

            serviceConfig = {
                Type = "simple";
                ExecStart = "${cfg.package}/bin/vastctl daemon run";
                Restart = "on-failure";
                RestartSec = "5s";
                Environment = [
                    "WAYLAND_DISPLAY=wayland-1"
                    "XDG_RUNTIME_DIR=/run/user/%U"
                    "QT_QPA_PLATFORM=wayland"
                    "DISPLAY=:0"
                    "PATH=${cfg.package}/bin"
                ];
            };
        };

        services.greetd = lib.mkIf cfg.greetd.enable {
            enable = true;

            settings.default_session = {
                command =
                    if cfg.greetd.command != null then
                        cfg.greetd.command
                    else
                        defaultGreeterCommand;
                user = cfg.greetd.user;
                inherit (cfg.greetd) restart;
                # source_profile = true;
            };
        };
    };
}
