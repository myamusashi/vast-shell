# Hyprland settings

[Back to README](../README.md)

The Settings window has a **Hyprland Configurations** section that lets you edit Hyprland options from a UI: per-monitor settings (position, mode, scale, color, etc) on the *Monitors* page, the general config options (general, decoration, input, render, misc, etc) on one page per category, and window/layer rules on the *Window Rules* and *Layer Rules* pages.

> [!WARNING]
> This feature targets **Hyprland 0.57.0 and later** (Lua config). Behavior on other versions is untested and may not work.

## How it works

JSON is the data, Lua is a static reader:

1. **Apply** (per page) writes the draft to `~/.config/vast-shell/monitor.json`, `~/.config/vast-shell/generals.json`, `~/.config/vast-shell/windowrules.json` and/or `~/.config/vast-shell/layerrules.json`, then runs `hyprctl reload`.
2. On every Hyprland (re)load, `~/.config/hypr/vast_shell.lua` reads the first two JSON files and applies them with `hl.monitor{...}` and `hl.config{...}`, and `~/.config/hypr/vast_shell_rules.lua` reads the rules files and registers them with `hl.window_rule{...}` / `hl.layer_rule{...}` in array order.

`~/.config/hypr/vast_shell.lua` and `~/.config/hypr/vast_shell_rules.lua` are created **once** when you first open a Hyprland settings page and they are **never overwritten**.

## One-time setup

Add these lines at the **bottom** of your own `~/.config/hypr/hyprland.lua`:

```lua
require("vast_shell")
require("vast_shell_rules")
```

The pages show these lines with copy buttons. They must be at the bottom because the last call wins: values and rules written by vast-shell shadow whatever your own config set earlier. If you prefer the opposite precedence, put the `require` lines above your own options instead.

## Requirements

- **lua-cjson** must be requireable from Hyprland's embedded Lua (PUC Lua **5.5**). Without it `vast_shell.lua` silently does nothing. Hyprland does not touch `package.cpath`, so the module has to be reachable from Lua's compiled-in module path, the generated `vast_shell.lua` prepends `~/.config/hypr/?.so` for you, so the easiest fix is to drop a Lua 5.5 `cjson.so` into `~/.config/hypr/`:
  - Nix: Just declared `lua55Packages.lua-cjson` into systemPackages (nix fixes this).
  - Otherwise: install any `lua-cjson` built against Lua 5.5 and copy (or symlink) its `cjson.so` there, or extend `package.cpath` at the top of `vast_shell.lua`.

## Files

| File | Written by | Purpose |
|---|---|---|
| `~/.config/vast-shell/monitor.json` | vast-shell | Monitors you modified and applied, under a `"monitors"` key |
| `~/.config/vast-shell/generals.json` | vast-shell | Config options you changed and applied, under a `"generals"` key |
| `~/.config/vast-shell/windowrules.json` | vast-shell | Window rules you applied, under a `"rules"` key |
| `~/.config/vast-shell/layerrules.json` | vast-shell | Layer rules you applied, under a `"rules"` key |
| `~/.config/hypr/vast_shell.lua` | vast-shell (once) | Yours to edit afterwards |
| `~/.config/hypr/vast_shell_rules.lua` | vast-shell (once) | Yours to edit afterwards |

`monitor.json` only contains monitors you actually modified and applied, a missing file means vast-shell emits nothing and your setup is untouched. Monitors are identified by their `description` (falling back to `model`), never by connector name, so settings survive unplug/replug. Hyprland matches `desc:` by **prefix**, so two connected monitors with the same description receive the same settings; the UI warns when that happens.

> [!IMPORTANT]
> `require("vast_shell")` runs **last**, on every reload. For every monitor stored in `monitor.json`, its `hl.monitor` call overrides the fields it sets in rules your own config set earlier (a rule that does not set a field, like `icc` when the field is empty, leaves that field alone). If you have your own monitor profiles (e.g. re-applied on `monitor.added`), a stored vast-shell entry wins for mode/position/scale/etc. on reconnect. Keep such monitors out of the UI (Revert + Apply removes the entry) or move those fields into the UI.

## Window & layer rules

- **Window Rules** offers every match property and effect `hl.window_rule` supports on 0.57.0 (typed inputs, enums as dropdowns, `move`/`size`/`max_size`/`min_size` as two expression fields). Each effect is labeled **static** (evaluated once when the window opens) or **dynamic** (re-evaluated when a matched property changes).
- **Layer Rules** matches only on `namespace` (the only property Hyprland consults for layer rules) and offers the ten layer effects.
- Regular expressions are **RE2 full matches**: the pattern must match the whole value, so wrap substrings in `.*` (`.*Hyprland.*`). Prefix a value with `negative:` to invert it (`class = "negative:^kitty$"`). Boolean properties negate by setting them to `false`.
- Rules apply **top to bottom and the last matching rule wins**; the up/down arrows reorder them and the order is stored in the JSON.
- Rule names are optional but must be **unique across your whole config**: Hyprland silently merges rules registered with the same name, so the UI blocks Apply while a name is duplicated.
- "Pick from running" buttons fill regex fields from live windows (via `Hyprland.toplevels`) and, for layers, from `hyprctl layers -j` plus vast-shell's own namespaces (`shell:drawers`, `shell:wallpaper`, `shell:dynamicIsland`, `shell:screenshot-overlay`).
- Apply is disabled while a rule is structurally invalid (no match property, duplicate name, or a value outside its schema range). Anything the compositor itself rejects is reported by Hyprland on reload.

## Monitors page

- The layout canvas is draggable once more than one enabled monitor is connected: positions snap to edges and overlaps are prevented (Hyprland refuses to register overlapping monitors). With a single monitor the position stays managed by Hyprland.
- Per-monitor options: mode (from the monitor's available modes), scale, transform, bit depth, color preset (`cm`), SDR brightness/saturation, ICC profile (absolute path), and a disabled switch.
- Monitors that are stored but not currently connected (or disabled) are listed below the connected ones so they can be edited or re-enabled.

## Excluded from the UI

- Keybinds (`hl.bind`), animations/curves, workspace rules, environment variables, permissions, gestures, and autostart are out of scope.
- Gradient-typed options (`general.col.*`, `group.col.*`, `group.groupbar.col.*`, `decoration.shadow.color`/`color_inactive`) need a structured `{colors, angle}` editor and are not exposed yet.
- Per-device properties (`enabled`, `keybinds`, `tags` per named device) require `hl.device` and are not offered; device-class tables (`input.touchpad.*` etc.) are available on the Input page.
- Monitor fields outside the UI's set (mirror, vrr, sdr_eotf, reserved_area, luminance, modeline) can be set directly in your own config.
