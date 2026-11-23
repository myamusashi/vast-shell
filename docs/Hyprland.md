# Hyprland settings

[Back to README](../README.md)

> [!WARNING]
> Requires **Hyprland 0.57.0 or later** (Lua config). Other versions are untested.

The Settings window has a **Hyprland Configurations** section for editing Hyprland options from a UI:

- **Monitors:** per-monitor position, mode, scale, color and more.
- **General options:** one page per category (general, decoration, input, render, misc, and so on).
- **Window Rules** and **Layer Rules.**

## Setup

Add these lines at the **bottom** of your `~/.config/hypr/hyprland.lua`:

```lua
require("vast_shell")
require("vast_shell_rules")
```

## How it works

**Apply** on a page writes your changes to JSON files and runs `hyprctl reload`. On every reload, two Lua files read the JSON and register it with Hyprland.

| File | Purpose |
|---|---|
| `~/.config/vast-shell/monitor.json` | Monitor settings, applied with `hl.monitor{...}` |
| `~/.config/vast-shell/generals.json` | General options, applied with `hl.config{...}` |
| `~/.config/vast-shell/windowrules.json` | Window rules, applied with `hl.window_rule{...}` |
| `~/.config/vast-shell/layerrules.json` | Layer rules, applied with `hl.layer_rule{...}` |
| `~/.config/hypr/vast_shell.lua` | Reads the monitor and general JSON |
| `~/.config/hypr/vast_shell_rules.lua` | Reads the rule JSON, in array order |

The two Lua files are created once, when you first open a Hyprland settings page, and are never overwritten.

## Monitors

- Options: mode, scale, transform, bit depth, color preset (`cm`), SDR brightness and saturation, ICC profile (absolute path) and a disabled switch.
- `monitor.json` only holds monitors you changed and applied. If the file is missing, vast-shell emits nothing and your setup is untouched.
- Monitors are identified by `description` (falling back to `model`), not connector name, so settings survive unplugging.
- Monitors that are saved but disconnected or disabled are listed below the connected ones, so you can edit or re-enable them.

## Window and layer rules

- **Window Rules** supports every match property and effect that `hl.window_rule` has on 0.57.0. Each effect is labeled **static** or **dynamic**.
- **Layer Rules** matches on `namespace` only and offers the ten layer effects.
- Rules apply top to bottom, and the **last matching rule wins**. Reorder them with the arrows.
- Regular expressions are RE2 and must match the **whole** value, so use `.*Hyprland.*` for a substring.
- Prefix a value with `negative:` to invert it (`class = "negative:^kitty$"`). Set a boolean property to `false` to negate it.
- Rule names are optional but must be unique across your whole config, because Hyprland silently merges rules with the same name.
- **Pick from running** fills regex fields from live windows, or for layers from `hyprctl layers -j` and the shell's own namespaces (`shell:drawers`, `shell:wallpaper`, `shell:dynamicIsland`, `shell:screenshot-overlay`).
- Apply is disabled while a rule has no match property, a duplicate name, or a value outside its range. Anything Hyprland itself rejects is reported on reload.

## Not in the UI

- Keybinds, animations and curves, workspace rules, environment variables, permissions, gestures and autostart.
- Gradient options (`general.col.*`, `group.col.*`, `group.groupbar.col.*`, `decoration.shadow.color` and `color_inactive`).
- Per-device properties that need `hl.device`. Device-class tables such as `input.touchpad.*` are on the Input page.
- Monitor fields mirror, vrr, sdr_eotf, reserved_area, luminance and modeline. Set these in your own config.
