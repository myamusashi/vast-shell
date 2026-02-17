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

# ─── Root check ────────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
	echo_error "System-wide installation requires root. Run with sudo or as root."
	exit 1
fi

# ─── Configuration ─────────────────────────────────────────────────────────────
INSTALL_DIR="/usr/local/share/quickshell"
BIN_DIR="/usr/local/bin"
FONT_DIR="/usr/local/share/fonts"
QML_DIR="/usr/lib/qt6/qml"
BUILD_DIR="/tmp/quickshell-build"
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

M3SHAPES_REV="1c8e6751febf230d7f94bf8015eaeb643bb4521e"
QMLMATERIAL_REV="21efe0c0d9fde4a9a041ab52e9ed3cc055c35796"

echo_info "Creating directories..."
mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$FONT_DIR/truetype" "$QML_DIR" "$BUILD_DIR"

# ─── Sanity check ──────────────────────────────────────────────────────────────
if ! command -v pacman &>/dev/null; then
	echo_error "This script is designed for Arch Linux and derivatives"
	exit 1
fi

# ─── System packages ───────────────────────────────────────────────────────────
echo_info "Checking system dependencies..."
PACKAGES_TO_INSTALL=()
SYSTEM_PACKAGES=(
	base-devel
	git
	go
	cmake
	ninja
	extra-cmake-modules
	patchelf
	qt6-base
	qt6-declarative
	qt6-svg
	qt6-graphs
	qt6-multimedia
	qt6-5compat
	qt6-shadertools
	qt6-tools
	findutils
	grep
	sed
	gawk
	util-linux
	networkmanager
	libnotify
	iw
	polkit
	wl-clipboard
	ffmpeg
	foot
	hyprland
	xdg-desktop-portal
)

for pkg in "${SYSTEM_PACKAGES[@]}"; do
	if ! pacman -Qi "$pkg" &>/dev/null; then
		PACKAGES_TO_INSTALL+=("$pkg")
	fi
done

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
	echo_info "Installing ${#PACKAGES_TO_INSTALL[@]} system packages..."
	pacman -S --needed --noconfirm "${PACKAGES_TO_INSTALL[@]}"
else
	echo_info "All system packages already installed"
fi

# ─── AUR helper ────────────────────────────────────────────────────────────────
# AUR builds must run as a non-root user; use SUDO_USER if available
AUR_USER="${SUDO_USER:-}"
if [ -z "$AUR_USER" ]; then
	echo_warn "SUDO_USER not set. AUR packages may fail (makepkg cannot run as root)."
	echo_warn "Recommended: run this script via: sudo ./install.sh"
fi

run_as_aur_user() {
	if [ -n "$AUR_USER" ]; then
		sudo -u "$AUR_USER" "$@"
	else
		"$@"
	fi
}

if ! command -v yay &>/dev/null; then
	echo_info "Installing yay AUR helper..."
	cd "$BUILD_DIR"
	git clone https://aur.archlinux.org/yay.git
	cd yay
	chown -R "${AUR_USER:-nobody}:${AUR_USER:-nobody}" .
	run_as_aur_user makepkg -si --noconfirm
	cd "$BUILD_DIR"
fi

# ─── AUR packages ──────────────────────────────────────────────────────────────
echo_info "Checking AUR packages..."
AUR_PACKAGES_TO_INSTALL=()
AUR_PACKAGES=(
	quickshell-git
	matugen-bin
	wl-screenrec
	ttf-weather-icons
	app2unit
	ttf-material-symbols-variable-git
)

for pkg in "${AUR_PACKAGES[@]}"; do
	if ! pacman -Qi "$pkg" &>/dev/null; then
		AUR_PACKAGES_TO_INSTALL+=("$pkg")
	fi
done

if [ ${#AUR_PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
	echo_info "Installing ${#AUR_PACKAGES_TO_INSTALL[@]} AUR packages..."
	run_as_aur_user yay -S --needed --noconfirm "${AUR_PACKAGES_TO_INSTALL[@]}"
else
	echo_info "All AUR packages already installed"
fi

# ─── keystate-bin (from Assets/keystate.go) ───────────────────────────────────
if [ -f "$BIN_DIR/keystate-bin" ]; then
	echo_info "keystate-bin already installed, skipping build"
elif [ -f "$PROJECT_ROOT/Assets/keystate.go" ]; then
	echo_info "Building keystate-bin..."
	cd "$BUILD_DIR"
	cp "$PROJECT_ROOT/Assets/keystate.go" .
	GOPATH="$BUILD_DIR/gopath" go build -o keystate-bin keystate.go
	install -Dm755 keystate-bin "$BIN_DIR/keystate-bin"
	install -Dm755 keystate-bin "$PROJECT_ROOT/Assets/keystate-bin"
	echo_info "keystate-bin installed"
else
	echo_warn "Assets/keystate.go not found, skipping keystate-bin build"
fi

# ─── m3shapes QML plugin ──────────────────────────────────────────────────────
M3SHAPES_PLUGIN="$QML_DIR/M3Shapes/libm3shapesplugin.so"
if [ -f "$M3SHAPES_PLUGIN" ]; then
	echo_info "m3shapes already installed at $QML_DIR, skipping build"
else
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
		-DCMAKE_INSTALL_PREFIX="$BUILD_DIR/m3shapes-install"
	ninja
	ninja install

	# Manually copy to system QML directory
	if [ -d "$BUILD_DIR/m3shapes-install/M3Shapes" ]; then
		mkdir -p "$QML_DIR/M3Shapes"
		cp -r "$BUILD_DIR/m3shapes-install/M3Shapes/"* "$QML_DIR/M3Shapes/"
	elif [ -d "$BUILD_DIR/m3shapes-install/lib/qt6/qml/M3Shapes" ]; then
		mkdir -p "$QML_DIR/M3Shapes"
		cp -r "$BUILD_DIR/m3shapes-install/lib/qt6/qml/M3Shapes/"* "$QML_DIR/M3Shapes/"
	fi

	# Patch rpath so plugin finds its own dir + Qt
	if [ -f "$M3SHAPES_PLUGIN" ]; then
		patchelf --set-rpath "$QML_DIR/M3Shapes:$(pkg-config --variable=libdir Qt6Core)" \
			"$M3SHAPES_PLUGIN" 2>/dev/null || true
	fi
	echo_info "m3shapes installed to $QML_DIR"
fi

# ─── QmlMaterial ──────────────────────────────────────────────────────────────
QMLMATERIAL_PLUGIN="$QML_DIR/Qcm/Material/libqml_materialplugin.so"
QMLMATERIAL_LIB="$QML_DIR/Qcm/Material/libqml_material.so"

if [ -f "$QMLMATERIAL_PLUGIN" ] && [ -f "$QMLMATERIAL_LIB" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
	echo_info "QmlMaterial already installed at $QML_DIR, skipping build"
	echo_info "Run with FORCE_REBUILD=1 to rebuild"
else
	[ "${FORCE_REBUILD:-0}" = "1" ] && echo_info "Force rebuilding QmlMaterial..."
	echo_info "Building QmlMaterial (rev $QMLMATERIAL_REV)..."
	cd "$BUILD_DIR"
	if [ ! -d "QmlMaterial" ]; then
		git clone --recurse-submodules https://github.com/hypengw/QmlMaterial.git
	fi
	cd QmlMaterial
	git checkout "$QMLMATERIAL_REV" 2>/dev/null || git fetch && git checkout "$QMLMATERIAL_REV"
	git submodule update --init --recursive

	# Patch icon font path to point to system-installed Material Symbols
	# The ttf-material-symbols-variable-git package installs to /usr/share/fonts/TTF/
	if [ -f "qml/Token.qml" ]; then
		echo_info "Patching Token.qml font paths..."
		# Use single quotes to avoid shell expansion issues
		sed -i \
			-e 's|source: root\.iconFontUrl|source: "file:///usr/share/fonts/TTF/MaterialSymbolsOutlined\[FILL,GRAD,opsz,wght\].ttf"|g' \
			-e 's|source: root\.iconFill0FontUrl|source: "file:///usr/share/fonts/TTF/MaterialSymbolsOutlined\[FILL,GRAD,opsz,wght\].ttf"|g' \
			-e 's|source: root\.iconFill1FontUrl|source: "file:///usr/share/fonts/TTF/MaterialSymbolsOutlined\[FILL,GRAD,opsz,wght\].ttf"|g' \
			qml/Token.qml
		
		# Verify the patch worked
		if grep -q 'file:///usr/share/fonts/TTF/MaterialSymbolsOutlined' qml/Token.qml; then
			echo_info "Font paths successfully patched"
		else
			echo_warn "Font path patching may have failed, check qml/Token.qml manually"
		fi
	else
		echo_warn "qml/Token.qml not found, skipping font patch"
	fi

	mkdir -p build && cd build
	cmake .. \
		-G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$BUILD_DIR/qmlmaterial-install" \
		-DQM_BUILD_EXAMPLE=OFF
	ninja
	ninja install

	# Manually copy to system QML directory - check all possible locations
	mkdir -p "$QML_DIR/Qcm/Material"
	
	if [ -d "$BUILD_DIR/qmlmaterial-install/Qcm/Material" ]; then
		cp -r "$BUILD_DIR/qmlmaterial-install/Qcm/Material/"* "$QML_DIR/Qcm/Material/"
	fi
	
	if [ -d "$BUILD_DIR/qmlmaterial-install/qml_modules/Qcm/Material" ]; then
		cp -r "$BUILD_DIR/qmlmaterial-install/qml_modules/Qcm/Material/"* "$QML_DIR/Qcm/Material/"
	fi
	
	if [ -d "$BUILD_DIR/qmlmaterial-install/lib/qt6/qml/Qcm/Material" ]; then
		cp -r "$BUILD_DIR/qmlmaterial-install/lib/qt6/qml/Qcm/Material/"* "$QML_DIR/Qcm/Material/"
	fi
	
	# Also copy shared libraries from lib directory if they exist
	if [ -d "$BUILD_DIR/qmlmaterial-install/lib" ]; then
		find "$BUILD_DIR/qmlmaterial-install/lib" -name "libqml_material*.so*" -exec cp {} "$QML_DIR/Qcm/Material/" \;
		find "$BUILD_DIR/qmlmaterial-install/lib" -name "libQcm*.so*" -exec cp {} "$QML_DIR/Qcm/Material/" \;
	fi
	
	# Copy from build directory if libraries are there
	if [ -d "$BUILD_DIR/QmlMaterial/build" ]; then
		find "$BUILD_DIR/QmlMaterial/build" -name "libqml_material*.so*" -exec cp {} "$QML_DIR/Qcm/Material/" \;
		find "$BUILD_DIR/QmlMaterial/build" -name "libQcm*.so*" -exec cp {} "$QML_DIR/Qcm/Material/" \;
	fi
	
	# Set proper permissions
	chmod 755 "$QML_DIR/Qcm/Material"/*.so* 2>/dev/null || true
	
	# Patch rpath for all shared libraries
	for lib in "$QML_DIR/Qcm/Material"/*.so*; do
		if [ -f "$lib" ] && [ ! -L "$lib" ]; then
			patchelf --set-rpath \
				"$QML_DIR/Qcm/Material:$(pkg-config --variable=libdir Qt6Core):$(pkg-config --variable=libdir Qt6Qml):$(pkg-config --variable=libdir Qt6Quick)" \
				"$lib" 2>/dev/null || true
		fi
	done
	
	# Verify installation
	if [ ! -f "$QMLMATERIAL_PLUGIN" ]; then
		echo_warn "QmlMaterial plugin not found after installation!"
		echo_warn "Searching for plugin in build directory..."
		find "$BUILD_DIR/qmlmaterial-install" -name "*plugin.so" 2>/dev/null || true
		find "$BUILD_DIR/QmlMaterial/build" -name "*plugin.so" 2>/dev/null || true
	fi
	
	if [ ! -f "$QMLMATERIAL_LIB" ]; then
		echo_warn "libqml_material.so not found after installation!"
		echo_warn "Searching for library in build directory..."
		find "$BUILD_DIR/qmlmaterial-install" -name "libqml_material.so*" 2>/dev/null || true
		find "$BUILD_DIR/QmlMaterial/build" -name "libqml_material.so*" 2>/dev/null || true
	fi
	
	echo_info "QmlMaterial installed to $QML_DIR"
fi

# ─── TranslationManager QML plugin ───────────────────────────────────────────
TM_PLUGIN="$QML_DIR/TranslationManager/libTranslationManagerplugin.so"
if [ -f "$TM_PLUGIN" ]; then
	echo_info "TranslationManager already installed at $QML_DIR, skipping build"
elif [ -d "$PROJECT_ROOT/plugins/TranslationManager" ]; then
	echo_info "Building TranslationManager plugin..."
	cd "$BUILD_DIR"
	rm -rf TranslationManager-build
	mkdir -p TranslationManager-build && cd TranslationManager-build
	cmake "$PROJECT_ROOT/plugins/TranslationManager" \
		-G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$BUILD_DIR/translationmanager-install"
	ninja
	ninja install

	# Manually copy to system QML directory
	if [ -d "$BUILD_DIR/translationmanager-install/TranslationManager" ]; then
		mkdir -p "$QML_DIR/TranslationManager"
		cp -r "$BUILD_DIR/translationmanager-install/TranslationManager/"* "$QML_DIR/TranslationManager/"
	elif [ -d "$BUILD_DIR/translationmanager-install/lib/qt6/qml/TranslationManager" ]; then
		mkdir -p "$QML_DIR/TranslationManager"
		cp -r "$BUILD_DIR/translationmanager-install/lib/qt6/qml/TranslationManager/"* "$QML_DIR/TranslationManager/"
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

# Set proper ownership and permissions for system-wide access
chmod -R 755 "$INSTALL_DIR"
chown -R root:root "$INSTALL_DIR"

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
cat >"$BIN_DIR/shell" <<'EOF'
#!/bin/bash

export QUICKSHELL_CONFIG_DIR="/usr/local/share/quickshell"
export QT_QPA_FONTDIR="/usr/local/share/fonts"

# QML import paths: TranslationManager, m3shapes, QmlMaterial
export QML2_IMPORT_PATH="/usr/lib/qt6/qml${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"

# Runtime PATH - comprehensive coverage for system-wide installation
# Includes: user bins, system bins, local bins, sbin paths, flatpak, snap
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin${HOME:+:$HOME/.local/bin}${PATH:+:$PATH}"

# Additional common binary locations for various package managers and tools
export PATH="$PATH:/opt/bin:/usr/games:/usr/local/games"

# Flatpak and Snap exports
export PATH="$PATH:/var/lib/flatpak/exports/bin${HOME:+:$HOME/.local/share/flatpak/exports/bin}"
[ -d /snap/bin ] && export PATH="$PATH:/snap/bin"

exec quickshell -p "$QUICKSHELL_CONFIG_DIR" "$@"
EOF

chmod +x "$BIN_DIR/shell"

# ─── Cleanup ──────────────────────────────────────────────────────────────────
echo_info "Cleaning up build directory..."
rm -rf "$BUILD_DIR"

echo_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo_info "System-wide installation complete!"
echo_info "Run 'shell' to start quickshell."
echo_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
