{pkgs}:
pkgs.mkShell {
    nativeBuildInputs = [
        pkgs.qt6Packages.wrapQtAppsHook
        pkgs.cmake
    ];

    buildInputs = [
        pkgs.qt6Packages.qtbase
        pkgs.qt6Packages.qtdeclarative
        pkgs.ddcutil
        pkgs.pipewire.dev
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
        pkgs.gcc
        pkgs.gdb
        pkgs.cmake
        pkgs.clang-tools
    ];

    shellHook = ''
        go build -o ./Assets/go/formatting ./Assets/go/formatting.go

        echo "Compiling shaders..."
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/ImageTransition.vert.qsb Assets/shaders/ImageTransition.vert
        for name in fade wipeDown circleExpand dissolve splitHorizontal slideUp pixelate diagonalWipe boxExpand roll; do
            qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/transitions/$name.frag.qsb Assets/shaders/transitions/$name.frag
        done
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/borderProgress.vert.qsb Assets/shaders/borderProgress.vert
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/borderProgress.frag.qsb Assets/shaders/borderProgress.frag
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/wavy.vert.qsb Assets/shaders/wavy.vert
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/wavy.frag.qsb Assets/shaders/wavy.frag
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/waveForm.vert.qsb Assets/shaders/waveForm.vert
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/waveForm.frag.qsb Assets/shaders/waveForm.frag

        echo "mushell environment"
    '';
}
