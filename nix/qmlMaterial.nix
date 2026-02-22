{
    lib,
    stdenv,
    fetchFromGitHub,
    cmake,
    pkg-config,
    qt6,
    xdg-desktop-portal,
    callPackage,
}: let
    material-symbols = callPackage ./material-symbols.nix {};
in
    stdenv.mkDerivation {
        pname = "QmlMaterial";
        version = "0.1.5";

        src = fetchFromGitHub {
            owner = "hypengw";
            repo = "QmlMaterial";
            rev = "21efe0c0d9fde4a9a041ab52e9ed3cc055c35796";
            sha256 = "sha256-ZOWgkyLs2Erb77D2K/CteqBgMeReY37cg2opG26VATY=";
            fetchSubmodules = true;
        };

        nativeBuildInputs = [
            cmake
            pkg-config
            qt6.wrapQtAppsHook
        ];

        buildInputs = [
            qt6.qtbase
            qt6.qtdeclarative
            qt6.qtshadertools
            xdg-desktop-portal
        ];

        cmakeFlags = [
            "-DQM_BUILD_EXAMPLE=OFF"
            "-DQML_INSTALL_DIR=${placeholder "out"}/${qt6.qtbase.qtQmlPrefix}"
        ];

        prePatch = ''
            substituteInPlace qml/Token.qml \
              --replace-fail 'source: root.iconFontUrl' \
                             'source: "file://${material-symbols}/share/fonts/truetype/MaterialSymbolsOutlined[FILL,GRAD,opsz,wght].ttf"' \
              --replace-fail 'source: root.iconFill0FontUrl' \
                             'source: "file://${material-symbols}/share/fonts/truetype/MaterialSymbolsOutlined[FILL,GRAD,opsz,wght].ttf"' \
              --replace-fail 'source: root.iconFill1FontUrl' \
                             'source: "file://${material-symbols}/share/fonts/truetype/MaterialSymbolsOutlined[FILL,GRAD,opsz,wght].ttf"'
        '';

        postInstall = ''
            mkdir -p $out/${qt6.qtbase.qtQmlPrefix}/Qcm/Material
            cp -r $out/qml_modules/Qcm/Material/* $out/${qt6.qtbase.qtQmlPrefix}/Qcm/Material/ || true
        '';

        meta = with lib; {
            description = "Material Design 3 for Qml";
            license = licenses.mit;
            platforms = platforms.linux;
            maintainer = [myamusashi];
        };
    }
