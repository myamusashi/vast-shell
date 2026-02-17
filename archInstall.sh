#!/usr/bin/env bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() {
	echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

# ─── Configuration ─────────────────────────────────────────────────────────────
INSTALL_DIR="$HOME/.local/share/quickshell"
BIN_DIR="$HOME/.local/bin"
FONT_DIR="$HOME/.local/share/fonts"
QML_DIR="$HOME/.local/lib/qt6/qml"
BUILD_DIR="/tmp/quickshell-build"
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

APP2UNIT_TAG="v1.0.3"
M3SHAPES_REV="1c8e6751febf230d7f94bf8015eaeb643bb4521e"
QMLMATERIAL_REV="21efe0c0d9fde4a9a041ab52e9ed3cc055c35796"
MATERIAL_ICONS_REV="941fa95d7f6084a599a54ca71bc565f48e7c6d9e"

echo_info "Creating directories..."
mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$FONT_DIR/truetype" "$QML_DIR" "$BUILD_DIR"

# ─── Sanity check ──────────────────────────────────────────────────────────────
if ! command -v pacman &>/dev/null; then
	echo_error "This script is designed for Arch Linux and derivatives"
	exit 1
fi

# ─── System packages ───────────────────────────────────────────────────────────
echo_info "Installing system dependencies..."
sudo pacman -S --needed --noconfirm \
	base-devel \
	git \
	go \
	cmake \
	ninja \
	extra-cmake-modules \
	patchelf \
	\
	qt6-base \
	qt6-declarative \
	qt6-svg \
	qt6-graphs \
	qt6-multimedia \
	qt6-5compat \
	qt6-shadertools \
	qt6-tools \
	\
	findutils \
	grep \
	sed \
	gawk \
	util-linux \
	\
	networkmanager \
	libnotify \
	iw \
	polkit \
	\
	wl-clipboard \
	ffmpeg \
	foot \
	hyprland \
	xdg-desktop-portal

# ─── AUR helper ────────────────────────────────────────────────────────────────
if ! command -v yay &>/dev/null; then
	echo_info "Installing yay AUR helper..."
	cd "$BUILD_DIR"
	git clone https://aur.archlinux.org/yay.git
	cd yay
	makepkg -si --noconfirm
	cd "$BUILD_DIR"
fi

# ─── AUR packages ──────────────────────────────────────────────────────────────
echo_info "Installing AUR packages..."
yay -S --needed --noconfirm \
	quickshell-git \
	matugen-bin \
	playerctl \
	wl-screenrec \
	weather-icons

# ─── keystate-bin (from Assets/keystate.go) ───────────────────────────────────
echo_info "Building keystate-bin..."
if [ -f "$PROJECT_ROOT/Assets/keystate.go" ]; then
	cd "$BUILD_DIR"
	cp "$PROJECT_ROOT/Assets/keystate.go" .
	GOPATH="$BUILD_DIR/gopath" go build -o keystate-bin keystate.go
	install -Dm755 keystate-bin "$BIN_DIR/keystate-bin"
	install -Dm755 keystate-bin "$PROJECT_ROOT/Assets/keystate-bin"
	echo_info "keystate-bin installed"
else
	echo_warn "Assets/keystate.go not found, skipping keystate-bin build"
fi

# ─── app2unit ─────────────────────────────────────────────────────────────────
echo_info "Installing app2unit $APP2UNIT_TAG..."
cd "$BUILD_DIR"
if [ ! -d "app2unit" ]; then
	git clone https://github.com/Vladimir-csp/app2unit.git
fi
cd app2unit
git fetch --tags
git checkout "$APP2UNIT_TAG"
install -Dm755 app2unit "$BIN_DIR/app2unit"
echo_info "app2unit installed"

# ─── Material Symbols font ────────────────────────────────────────────────────
echo_info "Installing Material Symbols font (pinned rev $MATERIAL_ICONS_REV)..."
cd "$BUILD_DIR"
if [ ! -d "material-design-icons" ]; then
	git clone --depth 1 --filter=blob:none --sparse \
		https://github.com/google/material-design-icons.git
fi
cd material-design-icons
git fetch origin "$MATERIAL_ICONS_REV" 2>/dev/null || true
git sparse-checkout set variablefont
cp variablefont/*.ttf "$FONT_DIR/truetype/"
fc-cache -f
echo_info "Material Symbols font installed"

# ─── m3shapes QML plugin ──────────────────────────────────────────────────────
echo_info "Building m3shapes (rev $M3SHAPES_REV)..."
cd "$BUILD_DIR"
if [ ! -d "m3shapes" ]; then
	git clone https://github.com/myamusashi/m3shapes.git
fi
cd m3shapes
git checkout "$M3SHAPES_REV" 2>/dev/null || git fetch && git checkout "$M3SHAPES_REV"
mkdir -p build && cd build
cmake .. \
	-G Ninja \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DCMAKE_INSTALL_PREFIX="$HOME/.local" \
	-DINSTALL_QMLDIR="lib/qt6/qml"
ninja
ninja install
# Patch rpath so plugin finds its own dir + Qt
M3SHAPES_PLUGIN="$QML_DIR/M3Shapes/libm3shapesplugin.so"
if [ -f "$M3SHAPES_PLUGIN" ]; then
	patchelf --set-rpath "$QML_DIR/M3Shapes:$(pkg-config --variable=libdir Qt6Core)" \
		"$M3SHAPES_PLUGIN" 2>/dev/null || true
fi
echo_info "m3shapes installed to $QML_DIR"

# ─── QmlMaterial ──────────────────────────────────────────────────────────────
echo_info "Building QmlMaterial (rev $QMLMATERIAL_REV)..."
cd "$BUILD_DIR"
if [ ! -d "QmlMaterial" ]; then
	git clone --recurse-submodules https://github.com/hypengw/QmlMaterial.git
fi
cd QmlMaterial
git checkout "$QMLMATERIAL_REV" 2>/dev/null || git fetch && git checkout "$QMLMATERIAL_REV"
git submodule update --init --recursive

# Patch icon font path to point to locally installed Material Symbols
FONT_TTF="$FONT_DIR/truetype/MaterialSymbolsOutlined[FILL,GRAD,opsz,wght].ttf"
sed -i \
	-e "s|source: root.iconFontUrl|source: \"file://$FONT_TTF\"|g" \
	-e "s|source: root.iconFill0FontUrl|source: \"file://$FONT_TTF\"|g" \
	-e "s|source: root.iconFill1FontUrl|source: \"file://$FONT_TTF\"|g" \
	qml/Token.qml 2>/dev/null || echo_warn "qml/Token.qml not found, skipping font patch"

mkdir -p build && cd build
cmake .. \
	-G Ninja \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX="$HOME/.local" \
	-DQM_BUILD_EXAMPLE=OFF \
	-DQML_INSTALL_DIR="$QML_DIR"
ninja
ninja install
# Move qml_modules output into proper QML prefix if needed
if [ -d "$HOME/.local/qml_modules/Qcm/Material" ]; then
	mkdir -p "$QML_DIR/Qcm/Material"
	cp -r "$HOME/.local/qml_modules/Qcm/Material/"* "$QML_DIR/Qcm/Material/"
fi
echo_info "QmlMaterial installed to $QML_DIR"

# ─── TranslationManager QML plugin ───────────────────────────────────────────
if [ -d "$PROJECT_ROOT/plugins/TranslationManager" ]; then
	echo_info "Building TranslationManager plugin..."
	cd "$BUILD_DIR"
	rm -rf TranslationManager-build
	mkdir -p TranslationManager-build && cd TranslationManager-build
	cmake "$PROJECT_ROOT/plugins/TranslationManager" \
		-G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$HOME/.local" \
		-DQML_INSTALL_DIR="$QML_DIR"
	ninja
	ninja install

	# Ensure plugin lands under $QML_DIR/TranslationManager/
	PLUGIN_INSTALL_DIR="$HOME/.local/TranslationManager"
	if [ -d "$PLUGIN_INSTALL_DIR" ]; then
		mkdir -p "$QML_DIR/TranslationManager"
		cp -r "$PLUGIN_INSTALL_DIR/"* "$QML_DIR/TranslationManager/"
		rm -rf "$PLUGIN_INSTALL_DIR"
	fi

	# Patch rpath
	TM_PLUGIN="$QML_DIR/TranslationManager/libTranslationManagerplugin.so"
	if [ -f "$TM_PLUGIN" ]; then
		patchelf --set-rpath \
			"$QML_DIR/TranslationManager:$(pkg-config --variable=libdir Qt6Core):$(pkg-config --variable=libdir Qt6Qml)" \
			"$TM_PLUGIN" 2>/dev/null || true
	fi
	TM_LIB="$QML_DIR/TranslationManager/libTranslationManager.so"
	if [ -f "$TM_LIB" ]; then
		patchelf --set-rpath \
			"$(pkg-config --variable=libdir Qt6Core):$(pkg-config --variable=libdir Qt6Qml)" \
			"$TM_LIB" 2>/dev/null || true
	fi
	echo_info "TranslationManager plugin installed"
else
	echo_warn "plugins/TranslationManager not found, skipping"
fi

# ─── Compile Qt Translations (.ts → .qm) ─────────────────────────────────────
if [ -d "$PROJECT_ROOT/translations" ] && command -v lrelease &>/dev/null; then
	echo_info "Compiling translations..."
	lrelease "$PROJECT_ROOT/translations/"*.ts 2>/dev/null || true
elif [ -d "$PROJECT_ROOT/translations" ]; then
	echo_warn "lrelease (qt6-tools) not found, skipping .ts compilation"
fi

# ─── Install quickshell configuration ────────────────────────────────────────
echo_info "Installing quickshell configuration..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Mirror nix installPhase: copy everything except build/
shopt -s extglob
cp -r "$PROJECT_ROOT"/!(build) "$INSTALL_DIR/" 2>/dev/null || true
shopt -u extglob

# Ensure key dirs are present (belt-and-suspenders)
for dir in Assets Components Widgets; do
	[ -d "$PROJECT_ROOT/$dir" ] && cp -r "$PROJECT_ROOT/$dir" "$INSTALL_DIR/"
done

# Patch shell.qml
if [ -f "$INSTALL_DIR/shell.qml" ]; then
	echo_info "Patching shell.qml..."
	sed -i "s/ShellRoot {/ShellRoot { settings.watchFiles: false/" "$INSTALL_DIR/shell.qml"
fi

# Install keystate-bin into Assets/
if [ -f "$BIN_DIR/keystate-bin" ]; then
	install -Dm755 "$BIN_DIR/keystate-bin" "$INSTALL_DIR/Assets/keystate-bin"
fi

# ─── Wrapper script ───────────────────────────────────────────────────────────
echo_info "Creating wrapper script..."
cat >"$BIN_DIR/shell" <<EOF
#!/bin/bash

export QUICKSHELL_CONFIG_DIR="\$HOME/.local/share/quickshell"
export QT_QPA_FONTDIR="\$HOME/.local/share/fonts"

# QML import paths: TranslationManager, m3shapes, QmlMaterial
export QML2_IMPORT_PATH="\$HOME/.local/lib/qt6/qml\${QML2_IMPORT_PATH:+:\$QML2_IMPORT_PATH}"

# Runtime PATH mirrors nix runtimeDeps + app2unit
export PATH="\$HOME/.local/bin:/usr/bin:/usr/local/bin:\$PATH"

exec quickshell -p "\$QUICKSHELL_CONFIG_DIR" "\$@"
EOF

chmod +x "$BIN_DIR/shell"

# ─── PATH setup ───────────────────────────────────────────────────────────────
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
	echo_warn "Adding $HOME/.local/bin to PATH in shell rc files..."
	echo "export PATH='$HOME/.local/bin:$PATH'" >>"$HOME/.bashrc"
	echo "export PATH='$HOME/.local/bin:$PATH'" >>"$HOME/.zshrc" 2>/dev/null || true
fi

# ─── Cleanup ──────────────────────────────────────────────────────────────────
echo_info "Cleaning up build directory..."
rm -rf "$BUILD_DIR"

echo_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo_info "Installation complete!"
echo_info "Run 'shell' to start quickshell."
echo_info "You may need to: source ~/.bashrc"
echo_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
