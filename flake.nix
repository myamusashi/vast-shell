{
    description = "quickshell config";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        wl-screenrec-fork = {
            url = "github:myamusashi/wl-screenrec";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        another-ripple = {
            url = "github:myamusashi/Another-Ripple";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        m3Shapes = {
            url = "github:soramanew/m3shapes";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        quickshell = {
            url = "github:quickshell-mirror/quickshell";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        qmlformat-rs = {
            url = "git+https://git.myamusashi.cc/myamusashi/qmlformat-rs";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = {
        self,
        nixpkgs,
        m3Shapes,
        quickshell,
        another-ripple,
        wl-screenrec-fork,
        qmlformat-rs,
    }: let
        version = "0.1.0";
        revision =
            if self ? rev
            then self.rev
            else if self ? dirtyRev
            then self.dirtyRev
            else "unknown";
        systems = [
            "x86_64-linux"
            "aarch64-linux"
        ];

        forAllSystems = nixpkgs.lib.genAttrs systems;

        pkgsFor = system:
            import nixpkgs {
                inherit system;
                overlays = [];
            };
    in {
        packages = forAllSystems (
            system: let
                pkgs = pkgsFor system;
                quickshellDerivation = quickshell.packages.${system}.default;
            in
                pkgs.callPackage ./nix/default.nix {
                    quickshell = quickshellDerivation;
                    inherit wl-screenrec-fork another-ripple m3Shapes;
                    inherit version revision;
                }
        );

        nixosModules.default = import ./nix/nixos-modules.nix {
            inherit self;
        };

        qmllintModules = forAllSystems (
            system: let
                pkgs = pkgsFor system;
                vastShell = pkgs.callPackage ./nix/default.nix {
                    inherit
                        quickshell
                        wl-screenrec-fork
                        another-ripple
                        m3Shapes
                        ;
                    inherit version revision;
                };
                qmlImports = import ./nix/qmllint-imports.nix {
                    inherit pkgs;
                    quickshell = quickshell.packages.${system}.default;
                    vastPlugin = vastShell.vastPlugin;
                    m3Shapes = m3Shapes.packages.${system}.default;
                    anotherRipple = another-ripple.packages.${system}.default;
                };
            in
                qmlImports.derivation
        );

        qmllintImportPaths = forAllSystems (
            system: let
                pkgs = pkgsFor system;
                vastShell = pkgs.callPackage ./nix/default.nix {
                    inherit
                        quickshell
                        wl-screenrec-fork
                        another-ripple
                        m3Shapes
                        ;
                    inherit version revision;
                };
                qmlImports = import ./nix/qmllint-imports.nix {
                    inherit pkgs;
                    quickshell = quickshell.packages.${system}.default;
                    vastPlugin = vastShell.vastPlugin;
                    m3Shapes = m3Shapes.packages.${system}.default;
                    anotherRipple = another-ripple.packages.${system}.default;
                };
            in
                qmlImports.searchPath
        );

        devShells = forAllSystems (
            system: let
                pkgs = pkgsFor system;
            in {
                default = import ./shell.nix {
                    inherit pkgs;
                    qmlformat-rs = qmlformat-rs.packages.${system}.default;
                };
            }
        );
    };
}
