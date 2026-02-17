#!/usr/bin/env bash

set -euo pipefail

readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die() {
	error "$*"
	exit 1
}

check_root() {
	[[ $EUID -eq 0 ]] || die "System-wide installation requires root. Run with sudo."
}

check_distro() {
	command -v pacman &>/dev/null || die "This script is designed for Arch Linux and derivatives"
}

install_system_packages() {
	local -a missing=()
	local -r pkg_list=(
		base-devel git go cmake ninja extra-cmake-modules patchelf
		qt6-{base,declarative,svg,graphs,multimedia,5compat,shadertools,tools}
		findutils grep sed gawk util-linux networkmanager libnotify
		iw polkit wl-clipboard ffmpeg foot hyprland xdg-desktop-portal
	)

	log "Checking system dependencies..."
	for pkg in "${pkg_list[@]}"; do
		pacman -Qi "$pkg" &>/dev/null || missing+=("$pkg")
	done

	if ((${#missing[@]})); then
		log "Installing ${#missing[@]} system packages..."
		pacman -S --needed --noconfirm "${missing[@]}"
	else
		log "All system packages already installed"
	fi
}

setup_aur_helper() {
	command -v yay &>/dev/null && return 0

	log "Installing yay AUR helper..."
	local -r aur_user="${SUDO_USER:-nobody}"

	git clone https://aur.archlinux.org/yay.git "$BUILD_DIR/yay"
	chown -R "$aur_user:$aur_user" "$BUILD_DIR/yay"

	if [[ -n ${SUDO_USER:-} ]]; then
		sudo -u "$SUDO_USER" makepkg -si --noconfirm -C "$BUILD_DIR/yay"
	else
		warn "SUDO_USER not set. Attempting to build as nobody..."
		sudo -u nobody makepkg -si --noconfirm -C "$BUILD_DIR/yay" || die "Failed to build yay"
	fi
}

install_aur_packages() {
	local -r aur_user="${SUDO_USER:-}"
	local -a missing=()
	local -r pkg_list=(
		quickshell-git matugen-bin wl-screenrec ttf-weather-icons
		app2unit ttf-material-symbols-variable-git
	)

	log "Checking AUR packages..."
	for pkg in "${pkg_list[@]}"; do
		pacman -Qi "$pkg" &>/dev/null || missing+=("$pkg")
	done

	((${#missing[@]})) || {
		log "All AUR packages already installed"
		return 0
	}
	[[ -n $aur_user ]] || die "AUR builds require a non-root user. Run with sudo."

	log "Installing ${#missing[@]} AUR packages..."
	sudo -u "$aur_user" yay -S --needed --noconfirm "${missing[@]}"
}

build_keystate() {
	[[ -f $BIN_DIR/keystate-bin ]] && {
		log "keystate-bin already installed"
		return 0
	}
	[[ -f $PROJECT_ROOT/Assets/keystate.go ]] || {
		warn "keystate.go not found, skipping"
		return 0
	}

	log "Building keystate-bin..."
	local -r gopath="$BUILD_DIR/gopath"
	mkdir -p "$gopath"

	GOPATH="$gopath" go build -C "$BUILD_DIR" -o keystate-bin "$PROJECT_ROOT/Assets/keystate.go"
	install -Dm755 "$BUILD_DIR/keystate-bin" "$BIN_DIR/keystate-bin"
	install -Dm755 "$BUILD_DIR/keystate-bin" "$PROJECT_ROOT/Assets/keystate-bin"
}

build_m3shapes() {
	local -r plugin="$QML_DIR/M3Shapes/libm3shapesplugin.so"
	[[ -f $plugin ]] && {
		log "m3shapes already installed"
		return 0
	}

	log "Building m3shapes..."
	local -r src="$BUILD_DIR/m3shapes"

	[[ -d $src ]] || git clone https://github.com/myamusashi/m3shapes.git "$src"
	git -C "$src" checkout "$M3SHAPES_REV" 2>/dev/null || {
		git -C "$src" fetch
		git -C "$src" checkout "$M3SHAPES_REV"
	}

	cmake -S "$src" -B "$src/build" -G Ninja \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DCMAKE_INSTALL_PREFIX="$BUILD_DIR/m3shapes-install"
	ninja -C "$src/build"
	ninja -C "$src/build" install

	mkdir -p "$QML_DIR/M3Shapes"
	local install_base="$BUILD_DIR/m3shapes-install"
	[[ -d $install_base/M3Shapes ]] && cp -r "$install_base/M3Shapes/"* "$QML_DIR/M3Shapes/"
	[[ -d $install_base/lib/qt6/qml/M3Shapes ]] && cp -r "$install_base/lib/qt6/qml/M3Shapes/"* "$QML_DIR/M3Shapes/"

	[[ -f $plugin ]] && patchelf --set-rpath "$QML_DIR/M3Shapes:$(pkg-config --variable=libdir Qt6Core)" "$plugin" 2>/dev/null || true
}

build_qmlmaterial() {
	local -r plugin="$QML_DIR/Qcm/Material/libqml_materialplugin.so"
	local -r lib="$QML_DIR/Qcm/Material/libqml_material.so"

	if [[ -f $plugin && -f $lib && ${FORCE_REBUILD:-0} -ne 1 ]]; then
		log "QmlMaterial already installed (set FORCE_REBUILD=1 to rebuild)"
		return 0
	fi

	[[ ${FORCE_REBUILD:-0} -eq 1 ]] && log "Force rebuilding QmlMaterial..."
	log "Building QmlMaterial..."

	local -r src="$BUILD_DIR/QmlMaterial"
	[[ -d $src ]] || git clone --recurse-submodules https://github.com/hypengw/QmlMaterial.git "$src"

	git -C "$src" checkout "$QMLMATERIAL_REV" 2>/dev/null || {
		git -C "$src" fetch
		git -C "$src" checkout "$QMLMATERIAL_REV"
	}
	git -C "$src" submodule update --init --recursive

	if [[ -f $src/qml/Token.qml ]]; then
		log "Patching Token.qml font paths..."
		sed -i \
			-e 's|source: root\.iconFontUrl|source: Qt.resolvedUrl("file:///usr/share/fonts/TTF/MaterialSymbolsOutlined[FILL,GRAD,opsz,wght].ttf")|g' \
			-e 's|source: root\.iconFill0FontUrl|source: Qt.resolvedUrl("file:///usr/share/fonts/TTF/MaterialSymbolsOutlined[FILL,GRAD,opsz,wght].ttf")|g' \
			-e 's|source: root\.iconFill1FontUrl|source: Qt.resolvedUrl("file:///usr/share/fonts/TTF/MaterialSymbolsOutlined[FILL,GRAD,opsz,wght].ttf")|g' \
			"$src/qml/Token.qml"

		if grep -q 'Qt.resolvedUrl.*MaterialSymbolsOutlined' "$src/qml/Token.qml"; then
			log "Font paths successfully patched"
		else
			warn "Font path patching may have failed, check $src/qml/Token.qml"
		fi
	else
		warn "$src/qml/Token.qml not found, skipping font patch"
	fi

	cmake -S "$src" -B "$src/build" -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$BUILD_DIR/qmlmaterial-install" \
		-DQM_BUILD_EXAMPLE=OFF
	ninja -C "$src/build"
	ninja -C "$src/build" install

	mkdir -p "$QML_DIR/Qcm/Material"
	local install_base="$BUILD_DIR/qmlmaterial-install"

	for dir in "$install_base/Qcm/Material" "$install_base/qml_modules/Qcm/Material" "$install_base/lib/qt6/qml/Qcm/Material"; do
		[[ -d $dir ]] && cp -r "$dir/"* "$QML_DIR/Qcm/Material/"
	done

	find "$install_base/lib" "$src/build" -name "libqml_material*.so*" -o -name "libQcm*.so*" 2>/dev/null |
		while read -r f; do [[ -f $f ]] && cp "$f" "$QML_DIR/Qcm/Material/"; done

	chmod 755 "$QML_DIR/Qcm/Material"/*.so* 2>/dev/null || true

	local qt_libs
	qt_libs="$(pkg-config --variable=libdir Qt6Core):$(pkg-config --variable=libdir Qt6Qml):$(pkg-config --variable=libdir Qt6Quick)"
	for f in "$QML_DIR/Qcm/Material"/*.so*; do
		[[ -f $f && ! -L $f ]] && patchelf --set-rpath "$QML_DIR/Qcm/Material:$qt_libs" "$f" 2>/dev/null || true
	done

	[[ -f $plugin ]] || warn "QmlMaterial plugin not found after installation"
	[[ -f $lib ]] || warn "libqml_material.so not found after installation"
}

build_translation_manager() {
	local -r plugin="$QML_DIR/TranslationManager/libTranslationManagerplugin.so"
	[[ -f $plugin ]] && {
		log "TranslationManager already installed"
		return 0
	}
	[[ -d $PROJECT_ROOT/plugins/TranslationManager ]] || {
		warn "TranslationManager not found, skipping"
		return 0
	}

	log "Building TranslationManager..."
	local -r build="$BUILD_DIR/TranslationManager-build"

	cmake -S "$PROJECT_ROOT/plugins/TranslationManager" -B "$build" -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$BUILD_DIR/translationmanager-install"
	ninja -C "$build"
	ninja -C "$build" install

	mkdir -p "$QML_DIR/TranslationManager"
	local install_base="$BUILD_DIR/translationmanager-install"
	[[ -d $install_base/TranslationManager ]] && cp -r "$install_base/TranslationManager/"* "$QML_DIR/TranslationManager/"
	[[ -d $install_base/lib/qt6/qml/TranslationManager ]] && cp -r "$install_base/lib/qt6/qml/TranslationManager/"* "$QML_DIR/TranslationManager/"

	local qt_libs
	qt_libs="$(pkg-config --variable=libdir Qt6Core):$(pkg-config --variable=libdir Qt6Qml)"
	[[ -f $plugin ]] && patchelf --set-rpath "$QML_DIR/TranslationManager:$qt_libs" "$plugin" 2>/dev/null || true

	local lib="$QML_DIR/TranslationManager/libTranslationManager.so"
	[[ -f $lib ]] && patchelf --set-rpath "$qt_libs" "$lib" 2>/dev/null || true
}

compile_translations() {
	[[ -d $PROJECT_ROOT/translations ]] || return 0
	command -v lrelease &>/dev/null || {
		warn "lrelease not found, skipping translations"
		return 0
	}

	log "Compiling translations..."
	lrelease "$PROJECT_ROOT/translations/"*.ts 2>/dev/null || true
}

install_quickshell_config() {
	log "Installing quickshell configuration..."
	rm -rf "$INSTALL_DIR"
	mkdir -p "$INSTALL_DIR"

	shopt -s extglob
	cp -r "$PROJECT_ROOT"/!(build) "$INSTALL_DIR/" 2>/dev/null || true
	shopt -u extglob

	for dir in Assets Components Widgets; do
		[[ -d $PROJECT_ROOT/$dir ]] && cp -r "$PROJECT_ROOT/$dir" "$INSTALL_DIR/"
	done

	chmod -R 755 "$INSTALL_DIR"
	chown -R root:root "$INSTALL_DIR"

	if [[ -f $INSTALL_DIR/shell.qml ]]; then
		sed -i 's/ShellRoot {/ShellRoot { settings.watchFiles: false/' "$INSTALL_DIR/shell.qml"
	fi

	[[ -f $BIN_DIR/keystate-bin ]] && install -Dm755 "$BIN_DIR/keystate-bin" "$INSTALL_DIR/Assets/keystate-bin"
}

create_wrapper() {
	log "Creating wrapper script..."
	cat >"$BIN_DIR/shell" <<'EOF'
#!/bin/bash
export QUICKSHELL_CONFIG_DIR="/usr/local/share/quickshell"
export QT_QPA_FONTDIR="/usr/local/share/fonts"
export QML2_IMPORT_PATH="/usr/lib/qt6/qml${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin${HOME:+:$HOME/.local/bin}${PATH:+:$PATH}"
export PATH="$PATH:/opt/bin:/usr/games:/usr/local/games"
export PATH="$PATH:/var/lib/flatpak/exports/bin${HOME:+:$HOME/.local/share/flatpak/exports/bin}"
[[ -d /snap/bin ]] && export PATH="$PATH:/snap/bin"
exec quickshell -p "$QUICKSHELL_CONFIG_DIR" "$@"
EOF
	chmod +x "$BIN_DIR/shell"
}

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

readonly INSTALL_DIR="/usr/local/share/quickshell"
readonly BIN_DIR="/usr/local/bin"
readonly FONT_DIR="/usr/local/share/fonts"
readonly QML_DIR="/usr/lib/qt6/qml"
readonly BUILD_DIR="/tmp/quickshell-build"
readonly PROJECT_ROOT
readonly M3SHAPES_REV="1c8e6751febf230d7f94bf8015eaeb643bb4521e"
readonly QMLMATERIAL_REV="21efe0c0d9fde4a9a041ab52e9ed3cc055c35796"

main() {
	check_root
	check_distro

	log "Creating directories..."
	mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$FONT_DIR/truetype" "$QML_DIR" "$BUILD_DIR"

	install_system_packages
	setup_aur_helper
	install_aur_packages
	build_keystate
	build_m3shapes
	build_qmlmaterial
	build_translation_manager
	compile_translations
	install_quickshell_config
	create_wrapper

	rm -rf "$BUILD_DIR"

	log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	log "Run 'shell' to start quickshell."
	log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

main "$@"
