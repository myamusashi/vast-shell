# Installation

[Back to README](../README.md)

## NixOS (Flakes)

Add vast-shell to your flake inputs:

```nix
inputs.vast-shell.url = "github:myamusashi/vast-shell";
```

Then use the NixOS module (recommended):

```nix
{
  imports = [ inputs.vast-shell.nixosModules.default ];

  programs.quickshell-shell = {
    enable = true;
    extraPackages = with pkgs; [ doksli ];
    greetd.enable = true;
  };
}
```

Or add only the package:

```nix
environment.systemPackages = [ inputs.vast-shell.packages.${system}.default ];
```

The module installs a systemd user service (`quickshell-shell.service`) that starts with your graphical session, and installs the `weather-icons` font. Material Symbols and Phosphor are bundled.

**Options** (`programs.quickshell-shell`):

| Option | Type | Default | Description |
|---|---|---|---|
| `enable` | bool | `false` | Enable the shell. |
| `package` | package | `self.packages.${system}.default` | The shell package. |
| `installFonts` | bool | `true` | Install the required fonts. |
| `extraPackages` | list of package | `[]` | Extra packages on quickshell's `PATH`. |
| `greetd.enable` | bool | `false` | Install and start a greetd greeter running `Qml/greeter.qml`. |
| `greetd.user` | string | `"greeter"` | User the greeter runs as. |
| `greetd.restart` | bool | `true` | Restart the greeter when it exits. Turn off while testing. |
| `greetd.compositorPackage` | package | `pkgs.mango` | Greeter compositor. It **must implement `ext-session-lock-v1`**; `cage` does not. Built-in presets cover `mango`, `sway`, `hyprland`, `niri`, `river`, and `labwc`. |
| `greetd.extraConfig` | lines | `""` | Extra lines for the greeter compositor config. |
| `greetd.exitCommand` | null or string | `null` | Optional exit command run after Quickshell quits to terminate the greeter compositor. Defaults to auto-detection in `Assets/shell/greeter-launch.sh`. |
| `greetd.command` | null or string | `null` | Optional override for `greetd`'s `default_session.command` when using a custom greeter compositor. |

---

## Arch Linux

```sh
git clone https://github.com/myamusashi/vast-shell.git
cd vast-shell
sudo ./archInstall.sh
vastctl daemon start
```

The script installs the dependencies, builds the plugins, compiles the shaders and sets up the shell.

<details>
<summary>Packages installed by the script</summary>

```text
base-devel git cmake ninja clang mold extra-cmake-modules patchelf pkgconf
qt6-base qt6-declarative qt6-wayland qt6-svg qt6-graphs qt6-multimedia
qt6-5compat qt6-shadertools qt6-tools rust pipewire ddcutil i2c-tools go
wayland wayland-protocols findutils grep sed gawk util-linux libnotify scdoc iw
polkit wl-clipboard ffmpeg foot hyprland xdg-desktop-portal spirv-tools
vulkan-headers cli11 cpptrace jemalloc libdrm mesa libxcb glib2
```

AUR (via `yay`): `ttf-weather-icons`, `app2unit`

</details>

> [!IMPORTANT]
> External monitor brightness (`ddcutil`) needs non-root access to I2C. `archInstall.sh` sets this up. For a manual setup, load `i2c-dev`, apply the udev rules from `setup_i2c` in `archInstall.sh`, and add your user to the `i2c` and `video` groups.

---

## Other distros

Package names vary by distro. Check your distro's package index:
[Fedora](https://packages.fedoraproject.org), [openSUSE](https://software.opensuse.org), [Gentoo](https://packages.gentoo.org), [Void](https://voidlinux.org/packages).

Build these from source on every distro:

| Package | Source | Note |
|---|---|---|
| `quickshell` | https://github.com/quickshell-mirror/quickshell | Patched `unstable-10-22-2026-9b0f339b`. A PKGBUILD is in `packaging/arch/quickshell/`. |
| `app2unit` | https://github.com/valpackett/app2unit | |
| `m3shapes` | https://github.com/soramanew/m3shapes | Built into the Qt module path. |
| `AnotherRipple` | https://github.com/myamusashi/Another-Ripple | |
| Weather Icons font | https://github.com/erikflowers/weather-icons | |

<details>
<summary>Fedora example</summary>

```sh
# Build tools
sudo dnf install git cmake ninja-build extra-cmake-modules patchelf pkgconf \
                 gcc gcc-c++ make rust cargo wayland-devel

# Qt6
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtsvg-devel \
                 qt6-qtmultimedia-devel qt6-qt5compat-devel \
                 qt6-qtshadertools-devel qt6-qttools-devel

# Runtime
sudo dnf install pipewire iw libnotify polkit wl-clipboard ffmpeg foot hyprland \
                 findutils grep sed gawk util-linux
```

`ffmpeg` needs [RPM Fusion](https://rpmfusion.org). `qt6-qtgraphs` is not packaged in Fedora, so build it from source if required.

</details>

---

## Bluetooth

The shell registers its own pairing agent when the pairing dialog opens. You only need BlueZ running, with `ClassicBondedOnly = false` in `/etc/bluetooth/main.conf`.

<details>
<summary>NixOS</summary>

Add this to your system configuration, not to the vast-shell flake:

```nix
{ pkgs, ... }: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        ClassicBondedOnly = false;
        JustWorksRepairing = "always";
        Enable = "Source,Sink,Media,Socket,Gateway";
      };
      Policy.AutoEnable = true;
    };
  };
  hardware.enableAllFirmware = true;
  services.blueman.enable = true;
  security.polkit.enable = true;
  environment.systemPackages = with pkgs; [ bluez bluez-tools ];
}
```

Rebuild with `sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)`.

</details>

<details>
<summary>Arch Linux</summary>

`archInstall.sh` does not set up Bluetooth:

```sh
sudo pacman -S bluez bluez-utils blueman
sudo systemctl enable --now bluetooth blueman-mechanism
sudo sed -i 's/#Experimental = false/Experimental = true/' /etc/bluetooth/main.conf
sudo sed -i 's/#ClassicBondedOnly.*/ClassicBondedOnly = false/' /etc/bluetooth/main.conf
sudo systemctl restart bluetooth
```

Also add `JustWorksRepairing = always` and `Enable = Source,Sink,Media,Socket,Gateway` under `[General]` if they are missing.

</details>

<details>
<summary>Other distros</summary>

Install `bluez` and `blueman`, enable the `bluetooth` service, and set `ClassicBondedOnly = false` in `/etc/bluetooth/main.conf`.

</details>
