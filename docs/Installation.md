# Installation

[Back to README](../README.md)

## NixOS (Flakes)

Add vast-shell to your flake inputs:

```nix
inputs.vast-shell = {
  url = "github:myamusashi/vast-shell";
};
```

Then you can either add the package directly, or use the NixOS module:

**Option 1 — Add the package directly:**

```nix
environment.systemPackages = [
  inputs.vast-shell.packages.${system}.default
];
```

**Option 2 — Use the NixOS module (recommended):**

```nix
{
  imports = [ inputs.vast-shell.nixosModules.default ];

  programs.quickshell-shell = {
    enable = true;

    # Optional: install extra packages accessible to the shell
    extraPackages = with pkgs; [ spotify ];

    # Optional: disable font installation if you manage fonts separately
    installFonts = false;

    # Optional: also install a greetd greeter (see below)
    greetd.enable = true;
  };
}
```

The module registers a systemd user service (`quickshell-shell.service`) that auto-starts with your graphical session, exports `VAST_SHELL_DIRECTORY`, and automatically installs the required fonts (`material-symbols`, `weather-icons`).

**Options** (`programs.quickshell-shell`):

| Option | Type | Default | Description |
|---|---|---|---|
| `enable` | bool | `false` | Enable the quickshell shell. |
| `package` | package | `self.packages.${system}.default` | The shell package to use. |
| `installFonts` | bool | `true` | Install the required fonts. |
| `extraPackages` | list of package | `[]` | Extra packages put on quickshell's `PATH`. |
| `greetd.enable` | bool | `false` | Install and start a greetd greeter running `Qml/greeter.qml`. |
| `greetd.user` | string | `"greeter"` | The user the greeter session runs as. |
| `greetd.restart` | bool | `true` | Restart the greeter when it exits. Turn off while testing. |
| `greetd.compositorPackage` | package | `pkgs.mango` | Greeter compositor. **Must implement `ext-session-lock-v1`** — `cage` does not, so the greeter would run but never display. |
| `greetd.extraConfig` | lines | `""` | Extra lines appended to the greeter compositor config. |

---

## Arch Linux

> [!IMPORTANT]
> Requires Arch Linux or an Arch-based distro. Run with `sudo`.

```bash
git clone https://github.com/myamusashi/vast-shell.git
cd vast-shell
sudo ./archInstall.sh
```

The script installs all dependencies, builds the plugins, compiles shaders, and sets up the shell. Once complete, start it with:

```bash
shell
```

### Dependencies

**Build**

| Package | Purpose |
|---|---|
| `cmake`, `qt6-shadertools`, `qt6-tools` | Build system, shader compiler (`qsb`), translation compiler (`lrelease`) |
| `qt6-base`, `qt6-declarative`, `qt6-multimedia` | Qt6 build-time libraries |
| `wayland` | Provides `libwayland-client` + `wayland-scanner` for the clipboard manager's native `ext_data_control_v1` binding |

**Runtime** (what `archInstall.sh` actually installs via `pacman -S`):

```
base-devel git cmake ninja clang mold extra-cmake-modules patchelf pkgconf
qt6-base qt6-declarative qt6-wayland qt6-svg qt6-graphs qt6-multimedia
qt6-5compat qt6-shadertools qt6-tools rust pipewire ddcutil i2c-tools go python
wayland wayland-protocols findutils grep sed gawk util-linux libnotify iw
polkit wl-clipboard ffmpeg foot hyprland xdg-desktop-portal spirv-tools
vulkan-headers cli11 cpptrace jemalloc libdrm mesa libxcb glib2 libvdpau-va-gl
```

**AUR** (installed with `yay`): `ttf-weather-icons`, `ttf-material-symbols-variable-git`, `app2unit`

**pip** (installed into `/usr/local/libexec/remove-bg-venv` by the script): `rembg`, exposed as
`/usr/local/bin/remove-bg.py`. This is the Arch equivalent of the Nix `remove-bg` package, which
resolves to `python314Packages.rembg`. The AUR `python-rembg` package is not used: it pulls the
`gradio`/`transformers` chain, whose `check()` currently fails on `huggingface-hub` 2.x. A failure
here is non-fatal — the depth-wallpaper feature is skipped with a warning.

> [!NOTE]
> The script also builds these from source rather than installing them:
> - `quickshell` 0.3.1 — via `packaging/arch/quickshell/PKGBUILD`
> - `wl-screenrec` (pinned git rev)
> - `m3shapes` and `AnotherRipple` (pinned git revs, installed into the Qt module path)
> - `vastctl` (Go, → `/usr/local/bin`)
> - the C++ plugins (CMake → `/usr/lib/qt6/qml`)
> - shaders via `qsb`, translations via `lrelease`

| Category | Packages |
|---|---|
| Qt6 | `qt6-base`, `qt6-declarative`, `qt6-wayland`, `qt6-svg`, `qt6-graphs`, `qt6-multimedia`, `qt6-5compat`, `qt6-shadertools`, `qt6-tools` |
| Shell | `hyprland`, `foot`, `polkit`, `xdg-desktop-portal` |
| Media | `ffmpeg`, `wl-clipboard`, `wl-screenrec`, `libvdpau-va-gl` |
| Network / Notifications | `iw`, `libnotify` |
| Fonts | `ttf-material-symbols-variable-git`, `ttf-weather-icons` |
| Utils | `findutils`, `grep`, `gawk`, `sed`, `util-linux` |
| AI / Depth Wallpaper | `python`, `rembg` |
| Other | `app2unit` (AUR), `ddcutil`, `i2c-tools` |

After install, `shell` is available on `PATH` and your config lives in `~/.config/vast-shell/` (seeded from `Data/`). See [Configuration](Configuration.md).

> [!IMPORTANT]
> **Brightness control (ddcutil):** Controlling external monitor brightness requires non-root access to I2C devices. `archInstall.sh` handles this automatically. For manual setup, load the `i2c-dev` module, apply the appropriate udev rules (see `setup_i2c` in `archInstall.sh`), and add your user to the `i2c` and `video` groups.

---

## Other Distros

> [!WARNING]
> Package names below were accurate at time of writing but **may be outdated**. Always verify against your distro's official package index. PRs to keep this list updated are welcome.
>
> **`rembg`** is not available in most distro repositories. Install it via `pip install rembg` (requires Python 3.9+). NixOS users get it automatically via the flake definition.
>
> - **Fedora** → https://packages.fedoraproject.org
> - **openSUSE** → https://software.opensuse.org
> - **Gentoo** → https://packages.gentoo.org
> - **Void** → https://voidlinux.org/packages

The following packages must always be built from source, regardless of distro:

| Package | Source | Note |
|---|---|---|
| `quickshell` | https://github.com/quickshell/quickshell | 0.3.1; a PKGBUILD is provided in `packaging/arch/quickshell/` |
| `app2unit` | https://github.com/valpackett/app2unit | |
| `wl-screenrec` | https://github.com/russelltg/wl-screenrec | |
| `m3shapes` | https://github.com/soramanew/m3shapes | Material shape library, built into the Qt module path |
| `AnotherRipple` | https://github.com/myamusashi/Another-Ripple | |
| Material Symbols font | https://github.com/google/material-design-icons | |
| Weather Icons font | https://github.com/erikflowers/weather-icons | |

> [!NOTE]
> You no longer need Python packages for theming. Material colors are generated by the bundled C++ engine, and `materialyoucolor` / `generate-colors-material` are legacy — see [Configuration → Material Colors](Configuration.md#material-colors).

<details>
<summary>Fedora</summary>

```bash
# System & build
sudo dnf install git cmake ninja-build extra-cmake-modules patchelf pkgconf \
                 gcc gcc-c++ make rust cargo wayland-devel

# Qt6
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtsvg-devel \
                 qt6-qtmultimedia-devel qt6-qt5compat-devel \
                 qt6-qtshadertools-devel qt6-qttools-devel

# Runtime
sudo dnf install pipewire iw libnotify polkit \
                 wl-clipboard ffmpeg foot hyprland findutils grep sed gawk util-linux
```

> [!NOTE]
> `ffmpeg` requires [RPM Fusion](https://rpmfusion.org): `sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm`
>
> `qt6-qtgraphs` is not yet packaged in Fedora — build from source if required.

</details>

<details>
<summary>openSUSE Tumbleweed</summary>

```bash
# System & build
sudo zypper install git cmake ninja extra-cmake-modules patchelf pkgconf \
                    gcc gcc-c++ make rust cargo wayland-devel

# Qt6
sudo zypper install qt6-base-devel qt6-declarative-devel qt6-svg-devel \
                    qt6-multimedia-devel qt6-5compat-devel \
                    qt6-shadertools-devel qt6-tools-devel

# Runtime
sudo zypper install pipewire iw libnotify-tools polkit \
                    wl-clipboard ffmpeg foot hyprland findutils grep sed gawk util-linux
```

</details>

<details>
<summary>Gentoo</summary>

```bash
# System & build
sudo emerge -av dev-vcs/git dev-build/cmake dev-build/ninja \
                kde-frameworks/extra-cmake-modules dev-util/patchelf \
                dev-util/pkgconf dev-lang/rust dev-libs/wayland

# Qt6 (ensure USE="qt6" where applicable)
sudo emerge -av dev-qt/qtbase:6 dev-qt/qtdeclarative:6 dev-qt/qtsvg:6 \
                dev-qt/qtmultimedia:6 dev-qt/qt5compat:6 \
                dev-qt/qtshadertools:6 dev-qt/qttools:6

# Runtime
sudo emerge -av media-video/pipewire net-wireless/iw \
                x11-libs/libnotify sys-auth/polkit \
                gui-apps/wl-clipboard media-video/ffmpeg gui-apps/foot \
                gui-wm/hyprland sys-apps/util-linux
```

</details>

<details>
<summary>Void Linux</summary>

```bash
# System & build
sudo xbps-install -S git cmake ninja extra-cmake-modules patchelf pkgconf \
                     base-devel rust cargo wayland-devel

# Qt6
sudo xbps-install -S qt6-base-devel qt6-declarative-devel qt6-svg-devel \
                     qt6-multimedia-devel qt6-5compat-devel \
                     qt6-shadertools-devel qt6-tools

# Runtime
sudo xbps-install -S pipewire iw libnotify polkit \
                     wl-clipboard ffmpeg foot hyprland findutils grep sed gawk util-linux
```

</details>

---

## Bluetooth — Phone pairing troubleshooting

The shell's Bluetooth UI (`BluetoothServices`) calls `Device1.Pair()` via [`Quickshell.Bluetooth`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Bluetooth/BluetoothDevice/). BlueZ **requires a registered pairing agent** (`org.bluez.AgentManager1`) to answer SSP confirmations; without one you get:

```
[SIGNAL] BREDR.Disconnected - org.bluez.Reason.Local  Connection terminated by local host
WARN quickshell.bluetooth.device: Failed to pair ... "Authentication Failed"
```

...which surfaces as `No agent available for request type 2` inside `bluetoothd` ([bluez#63], [bleak#1434], [bdteo.com](https://bdteo.com/bluez-pairing-python-agent-workaround-authentication-failed/)). This affects phone ↔ laptop (Android 16 `DisplayYesNo`) in both directions — also when `NoInputNoOutput` downgrades Secure Connections to `0x05 Insufficient Authentication` ([bluez#650]).

**The shell now provides its own agent.** `Vast.Utils.BluetoothAgentManager` registers `org.bluez.Agent1` over the system bus at `/io/quickshell/BluetoothAgent` with the `KeyboardDisplay` capability, and `Vast.Utils.BluetoothAgentManager.{providePinCode, providePasskey, confirmPairing, authorizeService}` answer the requests from `Qml/Modules/BluetoothAgent/PairingDialog.qml`. It activates as soon as the pairing dialog opens and unregisters when it closes.

Only one agent can hold the slot at a time. If `blueman` or another agent is `default-agent`, BlueZ will not route requests to the shell. To fall back to the desktop's agent, unregister the shell's:

```bash
busctl call org.bluez /org/bluez org.bluez.AgentManager1 UnregisterAgent ao /io/quickshell/BluetoothAgent
```

> **Always:** after a failed attempt clean stale bonding before retry:
> ```bash
> bluetoothctl remove XX:XX:XX:XX:XX:XX   # your phone's MAC (e.g. from `bluetoothctl devices`)
> # also "Forget" the laptop on the phone's Bluetooth settings
> ```

<details>
<summary>NixOS (recommended: <code>services.blueman</code>)</summary>

Do **not** modify `github:myamusashi/vast-shell`'s flake — fix your system flake (`/etc/nixos/flake.nix` + `configuration.nix`):

```nix
{ config, pkgs, ... }: {
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.enableAllFirmware = true;

  # Persistent DisplayYesNo agent (fixes Android 16 SSP). Don't use NoInputNoOutput for phones.
  services.blueman.enable = true;
  security.polkit.enable = true;

  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
      ClassicBondedOnly = false;   # required for phone BR/EDR + JustWorks fallback
      JustWorksRepairing = "always";
      Enable = "Source,Sink,Media,Socket,Gateway";
    };
    Policy.AutoEnable = true;
  };
  environment.systemPackages = with pkgs; [ bluez bluez-tools ];
}
```

Rebuild and verify:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)
systemctl status bluetooth --no-pager
bluetoothctl
# inside bluetoothctl
agent DisplayYesNo
default-agent
scan on
pair XX:XX:XX:XX:XX:XX
trust XX:XX:XX:XX:XX:XX
connect XX:XX:XX:XX:XX:XX
```


`journalctl -u bluetooth -f` should then show `Paired: yes` `Trusted: yes`, not `[DEL] Device`.

**If still `AuthenticationFailed` on BlueZ 5.66+/5.70+** ([bluez#605] regression):

```nix
# flake.nix
inputs.nixpkgs-bt.url = "github:NixOS/nixpkgs/<commit-with-bluez-5.64>";

# configuration.nix
hardware.bluetooth.package = inputs.nixpkgs-bt.legacyPackages.${pkgs.system}.bluez;
# alternate: nixpkgs.overlays = [ (final: prev: { bluez = prev.bluez.overrideAttrs (o: { version = "5.64"; }); }) ];
```

Then `nix flake update && sudo nixos-rebuild switch`.

**Note:** on NixOS the `blueman` applet is no longer required — the shell's built-in agent handles the pairing dialog itself. Keep `services.blueman.enable = true` only if you want the desktop's agent as a fallback for other clients.

</details>

<details>
<summary>Arch Linux / Manjaro / EndeavourOS</summary>

```bash
sudo pacman -S bluez bluez-utils blueman
sudo systemctl enable --now bluetooth
sudo systemctl enable --now blueman-mechanism
# autostart blueman-applet in Hyprland exec-once or systemd user:
# exec-once = blueman-applet
sudo sed -i 's/#Experimental = false/Experimental = true/' /etc/bluetooth/main.conf
sudo sed -i 's/#ClassicBondedOnly.*/ClassicBondedOnly = false/' /etc/bluetooth/main.conf
# add under [General] if missing:
# JustWorksRepairing = always
# Enable = Source,Sink,Media,Socket,Gateway
sudo systemctl restart bluetooth
bluetoothctl # then agent DisplayYesNo / default-agent as above
```

On Arch, `archInstall.sh` does **not** set up Bluetooth — apply the above manually.

</details>

<details>
<summary>Fedora / openSUSE / Void / Gentoo (generic)</summary>

```bash
# Fedora
sudo dnf install bluez blueman
sudo systemctl enable --now bluetooth
# blueman-applet autostart via Hyprland exec-once

# openSUSE
sudo zypper install bluez blueman
sudo systemctl enable --now bluetooth

# Void
sudo xbps-install -S bluez blueman
sudo ln -s /etc/sv/bluetoothd /var/service/

# Gentoo
sudo emerge -av net-wireless/bluez net-wireless/blueman
sudo rc-update add bluetooth default && sudo rc-service bluetooth start
```

Then either let the shell's own agent handle pairing (it registers automatically when the pairing dialog opens), or ensure a desktop agent is running (`blueman-applet` or `bluetoothctl agent DisplayYesNo`). Note that `bluetoothctl agent` unregisters on exit, so it only survives while that process is alive. Also set `ClassicBondedOnly = false` in `/etc/bluetooth/main.conf`.

**Upstream docs**

- Kynetics: [Pairing Agents in the BlueZ Stack](https://technotes.kynetics.com/2018/pairing-agents-bluez/) — `bluetoothctl` agent unregisters on exit, `simple-agent`/`bt-agent` daemonizes.
- BlueZ `org.bluez.AgentManager1` — `RegisterAgent` + `RequestDefaultAgent`.
- `bdteo.com`: [BlueZ Pairing Fix: External Python Agent & D-Bus Polling](https://bdteo.com/bluez-pairing-python-agent-workaround-authentication-failed/) — why internal `sd-bus` agent races `Pair()` on 5.66+ and requires polling fallback.

</details>

