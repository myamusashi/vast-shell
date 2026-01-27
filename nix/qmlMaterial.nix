{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
  xdg-desktop-portal,
}:
stdenv.mkDerivation rec {
  pname = "QmlMaterial";
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "hypengw";
    repo = pname;
    tag = "v${version}";
    sha256 = "sha256-dWUXLRMHAQNvR+ThQ2e0vGvSYn4Z/bYEbwCYMXHm2Vk=";
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
