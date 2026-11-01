# Hyprland settings

[Back to README](../README.md)

The Settings window has a **Hyprland Configurations** section that lets you edit Hyprland options from a UI: per-monitor settings (position, mode, scale, color, etc) on the *Monitors* page, and the general config options (general, decoration, input, render, misc, etc) on one page per category.

> [!WARNING]
> This feature targets **Hyprland 0.57.0 and later** (Lua config). Behavior on other versions is untested and may not work.

## How it works

JSON is the data, Lua is a static reader:

1. **Apply** (per page) writes the draft to `~/.config/vast-shell/monitor.json` and/or `~/.config/vast-shell/generals.json`, then runs `hyprctl reload`.
2. On every Hyprland (re)load, `~/.config/hypr/vast_shell.lua` reads those two JSON files and applies them with `hl.monitor{...}` and `hl.config{...}`.

`~/.config/hypr/vast_shell.lua` is created **once** when you first open a Hyprland settings page and it is **never overwritten**.

## One-time setup

Add one line at the **bottom** of your own `~/.config/hypr/hyprland.lua`:

```lua
require("vast_shell")
```

The Monitors page shows this line with a copy button. It must be at the bottom because the last `hl.config` call wins: values written by vast-shell shadow whatever your own config set earlier. If you prefer the opposite precedence, put the `require` above your own options instead.

## Requirements

- **lua-cjson** must be requireable from Hyprland's embedded Lua (PUC Lua **5.5**). Without it `vast_shell.lua` silently does nothing. Hyprland does not touch `package.cpath`, so the module has to be reachable from Lua's compiled-in module path, the generated `vast_shell.lua` prepends `~/.config/hypr/?.so` for you, so the easiest fix is to drop a Lua 5.5 `cjson.so` into `~/.config/hypr/`:
  - Nix: Just declared `lua55Packages.lua-cjson` into systemPackages (nix fixes this).
  - Otherwise: install any `lua-cjson` built against Lua 5.5 and copy (or symlink) its `cjson.so` there, or extend `package.cpath` at the top of `vast_shell.lua`.

## Files

| File | Written by | Purpose |
|---|---|---|
| `~/.config/vast-shell/monitor.json` | vast-shell | Monitors you modified and applied, under a `"monitors"` key |
| `~/.config/vast-shell/generals.json` | vast-shell | Config options you changed and applied, under a `"generals"` key |
| `~/.config/hypr/vast_shell.lua` | vast-shell (once) | Yours to edit afterwards |

`monitor.json` only contains monitors you actually modified and applied, a missing file means vast-shell emits nothing and your setup is untouched. Monitors are identified by their `description` (falling back to `model`), never by connector name, so settings survive unplug/replug. Hyprland matches `desc:` by **prefix**, so two connected monitors with the same description receive the same settings; the UI warns when that happens.

> [!IMPORTANT]
> `require("vast_shell")` runs **last**, on every reload. For every monitor stored in `monitor.json`, its `hl.monitor` call overrides the fields it sets in rules your own config set earlier (a rule that does not set a field, like `icc` when the field is empty, leaves that field alone). If you have your own monitor profiles (e.g. re-applied on `monitor.added`), a stored vast-shell entry wins for mode/position/scale/etc. on reconnect. Keep such monitors out of the UI (Revert + Apply removes the entry) or move those fields into the UI.

## Monitors page

- The layout canvas is draggable once more than one enabled monitor is connected: positions snap to edges and overlaps are prevented (Hyprland refuses to register overlapping monitors). With a single monitor the position stays managed by Hyprland.
- Per-monitor options: mode (from the monitor's available modes), scale, transform, bit depth, color preset (`cm`), SDR brightness/saturation, ICC profile (absolute path), and a disabled switch.
- Monitors that are stored but not currently connected (or disabled) are listed below the connected ones so they can be edited or re-enabled.

## Excluded from the UI

- Keybinds (`hl.bind`), animations/curves, window rules, workspace rules, environment variables, permissions, gestures, and autostart are out of scope.
- Gradient-typed options (`general.col.*`, `group.col.*`, `group.groupbar.col.*`, `decoration.shadow.color`/`color_inactive`) need a structured `{colors, angle}` editor and are not exposed yet.
- Per-device properties (`enabled`, `keybinds`, `tags` per named device) require `hl.device` and are not offered; device-class tables (`input.touchpad.*` etc.) are available on the Input page.
- Monitor fields outside the UI's set (mirror, vrr, sdr_eotf, reserved_area, luminance, modeline) can be set directly in your own config.
