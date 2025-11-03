{
  description = "quickshell config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
  };

  outputs = {
    self,
    nixpkgs,
    quickshell,
    apple-fonts,
  }: let
    lib = nixpkgs.lib;

    perSystem = package: (lib.listToAttrs (lib.map (a: {
      name = a;
      value = package {
        pkgs = nixpkgs.legacyPackages.${a};
        system = a;
      };
    }) (lib.attrNames nixpkgs.legacyPackages)));
  in {
    packages = perSystem ({
      pkgs,
      system,
    }:
      import ./nix/default.nix {
        inherit pkgs system lib quickshell;
      });

    homeManagerModules.default = import ./nix/hm-modules.nix {
      inherit self apple-fonts;
    };

    devShells = perSystem ({
      pkgs,
      system,
    }: {
      default = pkgs.mkShell {
        packages = [
          self.packages.${system}.default
          quickshell.packages.${system}.default
          pkgs.go
          pkgs.matugen
          pkgs.playerctl
          pkgs.wl-clipboard
          pkgs.libnotify
          pkgs.wl-screenrec
          pkgs.ffmpeg
          pkgs.foot
          pkgs.polkit
          apple-fonts.packages.${system}.sf-pro
          apple-fonts.packages.${system}.sf-pro-nerd
          apple-fonts.packages.${system}.sf-mono
          apple-fonts.packages.${system}.sf-mono-nerd
        ];

        shellHook = ''
          echo "Quickshell Development Environment"
        '';
      };
    });
  };
}
