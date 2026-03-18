{pkgs}:
pkgs.mkShell {
    nativeBuildInputs = [
        pkgs.qt6Packages.wrapQtAppsHook
        pkgs.cmake
        pkgs.kdePackages.qtshadertools
        pkgs.spirv-tools
        pkgs.glslang
    ];

    buildInputs = [
        pkgs.qt6Packages.qtbase
        pkgs.qt6Packages.qtdeclarative
        pkgs.pipewire.dev
        pkgs.kdePackages.qtshadertools
    ];

    packages = [
        pkgs.go
        pkgs.nil
        pkgs.pkg-config
        (with pkgs.kdePackages; [
            qtdeclarative
            qttools
            qtbase
            qttranslations
            qtshadertools
        ])
        pkgs.llvm
        pkgs.gcc
        pkgs.gdb
        pkgs.cmake
        pkgs.clang-tools
        pkgs.gopls
        pkgs.spirv-tools
        pkgs.glslang
    ];

    shellHook = ''
        go build -o ./Assets/go/formatting ./Assets/go/formatting.go
        echo "mushell environment"
    '';
}
