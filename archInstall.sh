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

INSTALL_DIR=""
BIN_DIR=""
FONT_DIR=""
QML_DIR=""
BUILD_DIR=""
PROJECT_ROOT=""
M3SHAPES_REV=""

init_globals() {
	INSTALL_DIR="/usr/local/share/quickshell"
	BIN_DIR="/usr/local/bin"
	FONT_DIR="/usr/local/share/fonts"
	QML_DIR="/usr/lib/qt6/qml"
	BUILD_DIR="/tmp/quickshell-build"
	PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)" || die "Failed to determine project root"
	M3SHAPES_REV="1c8e6751febf230d7f94bf8015eaeb643bb4521e"
	ANOTHER_RIPPLE_REV="main"

	readonly INSTALL_DIR BIN_DIR FONT_DIR QML_DIR BUILD_DIR PROJECT_ROOT M3SHAPES_REV ANOTHER_RIPPLE_REV
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
		qt6-base qt6-declarative qt6-svg qt6-graphs qt6-multimedia qt6-5compat qt6-shadertools qt6-tools
		findutils grep sed gawk util-linux libnotify wireplumber
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

	pushd "$BUILD_DIR/yay" >/dev/null
	if [[ -n ${SUDO_USER:-} ]]; then
		sudo -u "$SUDO_USER" makepkg -si --noconfirm
	else
		warn "SUDO_USER not set. Attempting to build as nobody..."
		sudo -u nobody makepkg -si --noconfirm || die "Failed to build yay"
	fi
	popd >/dev/null
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
	[[ -f $PROJECT_ROOT/Assets/go/keystate.go ]] || {
		warn "keystate.go not found, skipping"
		return 0
	}

	log "Building keystate-bin..."
	local -r gopath="$BUILD_DIR/gopath"
	mkdir -p "$gopath"

	cp "$PROJECT_ROOT/Assets/go/keystate.go" "$BUILD_DIR/"
	cd "$BUILD_DIR"
	GOPATH="$gopath" go build -o keystate-bin keystate.go
	install -Dm755 "$BUILD_DIR/keystate-bin" "$BIN_DIR/keystate-bin"
	install -Dm755 "$BUILD_DIR/keystate-bin" "$PROJECT_ROOT/Assets/go/keystate-bin"
}

build_audioProfiles() {
	[[ -f $BIN_DIR/audioProfiles ]] && {
		log "audioProfiles already installed"
		return 0
	}
	[[ -f $PROJECT_ROOT/Assets/go/audioProfiles.go ]] || {
		warn "audioProfiles.go not found, skipping"
		return 0
	}

	log "Building audioProfiles..."
	local -r gopath="$BUILD_DIR/gopath"
	mkdir -p "$gopath"

	cp "$PROJECT_ROOT/Assets/go/audioProfiles.go" "$BUILD_DIR/"
	cd "$BUILD_DIR"
	GOPATH="$gopath" go build -o audioProfiles audioProfiles.go
	install -Dm755 "$BUILD_DIR/audioProfiles" "$BIN_DIR/audioProfiles"
	install -Dm755 "$BUILD_DIR/audioProfiles" "$PROJECT_ROOT/Assets/go/audioProfiles"
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

	if [[ -f $plugin ]]; then
		local qt_core_lib
		qt_core_lib=$(pkg-config --variable=libdir Qt6Core)
		patchelf --set-rpath "$QML_DIR/M3Shapes:$qt_core_lib" "$plugin" 2>/dev/null || true
	fi
}

compile_wallpaper_shaders() {
	local -r shader_dir="$PROJECT_ROOT/Assets/shaders"
	local -r vert_src="$shader_dir/ImageTransition.vert"
	local -r frag_src="$shader_dir/ImageTransition.frag"
	local -r vert_out="$shader_dir/ImageTransition.vert.qsb"
	local -r frag_out="$shader_dir/ImageTransition.frag.qsb"

	# Locate qsb tool — packaged as qt6-shadertools on Arch
	local qsb
	qsb=$(command -v qsb 2>/dev/null || command -v qsb6 2>/dev/null || true)
	[[ -n $qsb ]] || qsb=$(find /usr/lib/qt6 /usr/lib/qt /opt/qt6 -name "qsb" -type f 2>/dev/null | head -1 || true)
	[[ -n $qsb ]] || {
		warn "qsb not found — skipping shader compilation (qt6-shadertools required)"
		return 0
	}

	[[ -f $vert_src ]] || {
		warn "Vertex shader not found: $vert_src"
		return 0
	}
	[[ -f $frag_src ]] || {
		warn "Fragment shader not found: $frag_src"
		return 0
	}

	# Skip if already compiled and sources are older than outputs
	if [[ -f $vert_out && -f $frag_out ]]; then
		if [[ $vert_src -ot $vert_out && $frag_src -ot $frag_out ]]; then
			log "Wallpaper shaders already compiled and up to date"
			return 0
		fi
	fi

	log "Compiling wallpaper transition shaders..."

	"$qsb" \
		--glsl "450,330,300 es" \
		--hlsl 50 \
		--msl 12 \
		-o "$vert_out" \
		"$vert_src" ||
		die "Failed to compile vertex shader: $vert_src"

	"$qsb" \
		--glsl "450,330,300 es" \
		--hlsl 50 \
		--msl 12 \
		-o "$frag_out" \
		"$frag_src" ||
		die "Failed to compile fragment shader: $frag_src"

	log "Shaders compiled → $(basename "$vert_out"), $(basename "$frag_out")"
}

build_another_ripple() {
	local -r plugin="$QML_DIR/AnotherRipple/libAnotherRippleplugin.so"
	[[ -f $plugin ]] && {
		log "AnotherRipple already installed"
		return 0
	}

	log "Building AnotherRipple..."
	local -r src="$BUILD_DIR/Another-Ripple"

	[[ -d $src ]] || git clone https://github.com/myamusashi/Another-Ripple.git "$src"
	git -C "$src" checkout "$ANOTHER_RIPPLE_REV" 2>/dev/null || {
		git -C "$src" fetch
		git -C "$src" checkout "$ANOTHER_RIPPLE_REV"
	}

	# The nix derivation appends /AnotherRipple to the source — CMakeLists.txt lives there
	local -r cmake_src="$src/AnotherRipple"
	[[ -d $cmake_src ]] || die "AnotherRipple subdirectory not found in repo: $cmake_src"

	cmake -S "$cmake_src" -B "$src/build" -G Ninja \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
		-DCMAKE_INSTALL_PREFIX="$BUILD_DIR/anotherripple-install" \
		-DINSTALL_QMLDIR="lib/qt6/qml"
	ninja -C "$src/build"
	ninja -C "$src/build" install

	mkdir -p "$QML_DIR/AnotherRipple"
	local install_base="$BUILD_DIR/anotherripple-install"
	for dir in \
		"$install_base/AnotherRipple" \
		"$install_base/lib/qt6/qml/AnotherRipple" \
		"$install_base/lib/qt-6/qml/AnotherRipple"; do
		[[ -d $dir ]] && cp -r "$dir/"* "$QML_DIR/AnotherRipple/"
	done

	local qt_core_lib qt_qml_lib
	qt_core_lib=$(pkg-config --variable=libdir Qt6Core)
	qt_qml_lib=$(pkg-config --variable=libdir Qt6Qml)

	for lib in \
		"$QML_DIR/AnotherRipple/libAnotherRipple.so" \
		"$QML_DIR/AnotherRipple/libAnotherRippleplugin.so"; do
		[[ -f $lib ]] && patchelf --set-rpath "$QML_DIR/AnotherRipple:$qt_core_lib:$qt_qml_lib" "$lib" 2>/dev/null || true
	done

	[[ -f $plugin ]] || warn "AnotherRipple plugin not found after installation"
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

	local qt_core_lib qt_qml_lib
	qt_core_lib=$(pkg-config --variable=libdir Qt6Core)
	qt_qml_lib=$(pkg-config --variable=libdir Qt6Qml)

	[[ -f $plugin ]] && patchelf --set-rpath "$QML_DIR/TranslationManager:$qt_core_lib:$qt_qml_lib" "$plugin" 2>/dev/null || true

	local lib="$QML_DIR/TranslationManager/libTranslationManager.so"
	[[ -f $lib ]] && patchelf --set-rpath "$qt_core_lib:$qt_qml_lib" "$lib" 2>/dev/null || true
}

compile_translations() {
	[[ -d $PROJECT_ROOT/translations ]] || return 0

	# On Arch, qt6-tools installs lrelease to /usr/lib/qt6/bin/ which is NOT in $PATH by default.
	# Check that specific location first, then fall back to whatever is in $PATH.
	local lrelease_bin
	lrelease_bin=$(command -v /usr/lib/qt6/bin/lrelease 2>/dev/null ||
		command -v lrelease 2>/dev/null ||
		true)

	[[ -n $lrelease_bin ]] || {
		warn "lrelease not found — install qt6-tools: pacman -S qt6-tools"
		return 0
	}

	log "Compiling translations with $(basename "$lrelease_bin")..."
	"$lrelease_bin" "$PROJECT_ROOT/translations/"*.ts 2>/dev/null || true
}

install_quickshell_config() {
	log "Installing quickshell configuration..."
	rm -rf "$INSTALL_DIR"
	mkdir -p "$INSTALL_DIR"

	# Copy all except build/
	find "$PROJECT_ROOT" -mindepth 1 -maxdepth 1 ! -name "build" -exec cp -r {} "$INSTALL_DIR/" \; 2>/dev/null || true

	for dir in Assets Components Widgets; do
		[[ -d $PROJECT_ROOT/$dir ]] && cp -r "$PROJECT_ROOT/$dir" "$INSTALL_DIR/"
	done

	chmod -R 755 "$INSTALL_DIR"
	chown -R root:root "$INSTALL_DIR"

	if [[ -f $INSTALL_DIR/shell.qml ]]; then
		sed -i 's/ShellRoot {/ShellRoot { settings.watchFiles: false/' "$INSTALL_DIR/shell.qml"
	fi

	[[ -f $BIN_DIR/keystate-bin ]] && install -Dm755 "$BIN_DIR/keystate-bin" "$INSTALL_DIR/Assets/go/keystate-bin"
	[[ -f $BIN_DIR/audioProfiles ]] && install -Dm755 "$BIN_DIR/audioProfiles" "$INSTALL_DIR/Assets/go/audioProfiles"
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

main() {
	init_globals
	check_root
	check_distro

	log "Creating directories..."
	mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$FONT_DIR/truetype" "$QML_DIR" "$BUILD_DIR"

	install_system_packages
	setup_aur_helper
	install_aur_packages
	build_keystate
	build_audioProfiles
	build_m3shapes
	build_another_ripple
	compile_wallpaper_shaders
	build_translation_manager
	compile_translations
	install_quickshell_config
	create_wrapper

	rm -rf "$BUILD_DIR"

	log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	log "System-wide installation complete!"
	log "Run 'shell' to start quickshell."
	log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

main "$@"
