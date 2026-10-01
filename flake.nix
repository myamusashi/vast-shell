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
    };

    outputs = {
        self,
        nixpkgs,
        m3Shapes,
        quickshell,
        another-ripple,
        wl-screenrec-fork,
    }: let
        systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

        forAllSystems = nixpkgs.lib.genAttrs systems;

        pkgsFor = system:
            import nixpkgs {
                inherit system;
                overlays = [];
            };
    in {
        packages = forAllSystems (system: let
            pkgs = pkgsFor system;
            quickshellDerivation = quickshell.packages.${system}.default;
        in
            pkgs.callPackage ./nix/default.nix {
                quickshell = quickshellDerivation;
                inherit wl-screenrec-fork another-ripple m3Shapes;
            });

        nixosModules.default = import ./nix/nixos-modules.nix {
            inherit self;
        };

        # qmllint module search paths plus a buildable stand-in for them, so
        # CI can fetch the module roots without knowing anything about which
        # packages they come from. See nix/qmllint-imports.nix.
        qmllintModules = forAllSystems (system: let
            pkgs = pkgsFor system;
            vastShell = pkgs.callPackage ./nix/default.nix {
                inherit quickshell wl-screenrec-fork another-ripple m3Shapes;
            };
            qmlImports = import ./nix/qmllint-imports.nix {
                inherit pkgs;
                quickshell = quickshell.packages.${system}.default;
                vastPlugin = vastShell.vastPlugin;
                m3Shapes = m3Shapes.packages.${system}.default;
                anotherRipple = another-ripple.packages.${system}.default;
            };
        in
            qmlImports.derivation);

        qmllintImportPaths = forAllSystems (system: let
            pkgs = pkgsFor system;
            vastShell = pkgs.callPackage ./nix/default.nix {
                inherit quickshell wl-screenrec-fork another-ripple m3Shapes;
            };
            qmlImports = import ./nix/qmllint-imports.nix {
                inherit pkgs;
                quickshell = quickshell.packages.${system}.default;
                vastPlugin = vastShell.vastPlugin;
                m3Shapes = m3Shapes.packages.${system}.default;
                anotherRipple = another-ripple.packages.${system}.default;
            };
        in
            qmlImports.searchPath);

        devShells = forAllSystems (system: let
            pkgs = pkgsFor system;
        in {
            default = import ./shell.nix {inherit pkgs;};
        });
    };
}
