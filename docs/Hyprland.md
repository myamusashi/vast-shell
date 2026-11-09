# Hyprland settings

[Back to README](../README.md)

> [!WARNING]
> This feature targets **Hyprland 0.57.0 and later** (Lua config). Behavior on other versions is untested and may not work.

The Settings window has a **Hyprland Configurations** section that lets you edit Hyprland options from a UI: per-monitor settings (position, mode, scale, color, etc) on the *Monitors* page, the general config options (general, decoration, input, render, misc, etc) on one page per category, and window/layer rules on the *Window Rules* and *Layer Rules* pages.

## How it works

1. **Apply** (per page) writes the draft to `~/.config/vast-shell/monitor.json`, `~/.config/vast-shell/generals.json`, `~/.config/vast-shell/windowrules.json` and/or `~/.config/vast-shell/layerrules.json`, then runs `hyprctl reload`.
2. On every Hyprland (re)load, `~/.config/hypr/vast_shell.lua` reads the first two JSON files and applies them with `hl.monitor{...}` and `hl.config{...}`, and `~/.config/hypr/vast_shell_rules.lua` reads the rules files and registers them with `hl.window_rule{...}` / `hl.layer_rule{...}` in array order.

`~/.config/hypr/vast_shell.lua` and `~/.config/hypr/vast_shell_rules.lua` are created **once** when you first open a Hyprland settings page and they are **never overwritten**.

## One-time setup

Add these lines at the **bottom** of your own `~/.config/hypr/hyprland.lua`:

```lua
require("vast_shell")
require("vast_shell_rules")
```

## Files

- `~/.config/vast-shell/monitor.json`
- `~/.config/vast-shell/generals.json`
- `~/.config/vast-shell/windowrules.json`
- `~/.config/vast-shell/layerrules.json`
- `~/.config/hypr/vast_shell.lua`
- `~/.config/hypr/vast_shell_rules.lua`

`monitor.json` only contains monitors you actually modified and applied. A missing file means vast-shell emits nothing and your setup is untouched. Monitors are identified by their `description` (falling back to `model`), never by connector name, so settings survive unplug/replug.

## Window & layer rules

- **Window Rules** offers every match property and effect `hl.window_rule` supports on 0.57.0. Each effect is labeled **static** or **dynamic**.
- **Layer Rules** matches only on `namespace` and offers the ten layer effects.
- Regular expressions are **RE2 full matches**: the pattern must match the whole value, so wrap substrings in `.*` (`.*Hyprland.*`). Prefix a value with `negative:` to invert it (`class = "negative:^kitty$"`). Boolean properties negate by setting them to `false`.
- Rules apply **top to bottom and the last matching rule wins**; the up/down arrows reorder them and the order is stored in the JSON.
- Rule names are optional but must be **unique across your whole config**: Hyprland silently merges rules registered with the same name, so the UI blocks Apply while a name is duplicated.
- "Pick from running" buttons fill regex fields from live windows (via `Hyprland.toplevels`) and, for layers, from `hyprctl layers -j` plus vast-shell's own namespaces (`shell:drawers`, `shell:wallpaper`, `shell:dynamicIsland`, `shell:screenshot-overlay`).
- Apply is disabled while a rule is structurally invalid (no match property, duplicate name, or a value outside its schema range). Anything the compositor itself rejects is reported by Hyprland on reload.

## Monitors page

- Per-monitor options: mode, scale, transform, bit depth, color preset (`cm`), SDR brightness/saturation, ICC profile (absolute path), and a disabled switch.
- Monitors that are stored but not currently connected (or disabled) are listed below the connected ones so they can be edited or re-enabled.

## Excluded from the UI

- Keybinds (`hl.bind`), animations/curves, workspace rules, environment variables, permissions, gestures, and autostart are out of scope.
- Gradient-typed options (`general.col.*`, `group.col.*`, `group.groupbar.col.*`, `decoration.shadow.color`/`color_inactive`) need a structured `{colors, angle}` editor and are not exposed yet.
- Per-device properties (`enabled`, `keybinds`, `tags` per named device) require `hl.device` and are not offered; device-class tables (`input.touchpad.*` etc.) are available on the Input page.
- Monitor fields outside the UI's set (mirror, vrr, sdr_eotf, reserved_area, luminance, modeline) can be set directly in your own config.
