# Usage

[Back to README](../README.md)

## vastctl

`vastctl` is a Go CLI that starts the shell and controls every feature over IPC.

```text
vastctl
├── audio profile list / set <name>
│       device list / set <name>
├── brightness get
│           set [+|-]<%>
├── captureScreenImage screen / region / window [action]   # alias: capture
├── captureScreenVideo start / stop / toggle / status     # alias: record
├── clipboard list / status / remove <id> / clear / search <query>
├── color generate <image-path>                           # --mode, --scheme, --out, --raw
│       from <hex-color>
│       render                                           # --template, --wallpaper, --palette
├── volume system get / set [+|-]<%> / mute / unmute / toggle-mute
│       app list / set <id> [+|-]<%> / mute <id> / unmute <id> / toggle-mute <id>
├── wallpaper get / set <path>
├── mpris play-pause / next / previous / stop / list
├── lock lock / unlock / status
├── idle on / off / status
├── keylock capslock / numlock
├── dragAndDrop start / stop / toggle / status / shortcut
├── toast open <description>
├── hypr dispatch <shortcut-name>
│     shortcuts list
├── daemon start / stop / restart / status
├── log
└── completion bash / fish / zsh / nushell
```

`set` accepts an absolute value (`50`, `50%`) or a relative change (`+10%`, `-10%`):

```sh
vastctl volume system set +10%
vastctl brightness set -5%
```

### Flags

| Command | Flag | Default | Description |
|---|---|---|---|
| (global) | `--json` | `false` | Print raw JSON instead of the tree. |
| `daemon start` | `-v`, `--verbose` | `false` | Stream quickshell output to the terminal. |
| `daemon` | `-f`, `--foreground` | `false` | Run the supervisor in the foreground. |
| `daemon` | `--config` | `$VAST_SHELL_DEV_DIRECTORY`, else the installed config | Config directory to start. Ignored by IPC commands. |
| `log` | `-n`, `--lines` | `20` | Lines to print. |
| `log` | `--no-follow` | `false` | Print once and exit. |
| `toast open` | `-H`, `--header` | `vast-shell` | Toast header. |
| `toast open` | `-i`, `--icon` | `notification-active` | Icon name or absolute image path. |
| `toast open` | `-d`, `--duration` | `5000` | Display time in ms. |
| `color` | `--mode` | `dark` | `dark` or `light`. |
| `color` | `--scheme` | `tonal-spot` | Any of the nine Material schemes. |
| `color` | `--out` | stdout | Write the JSON result to a file. |
| `color` | `--raw` | `false` | Skip the tree renderer (implied by `--out`). |
| `color render` | `--template` | all enabled | Render only this template. |
| `color render` | `--wallpaper` | current wallpaper | Render from this wallpaper. |
| `color render` | `--palette` | wallpaper palette | Render from the palette in this file. |

### Daemon

```sh
vastctl daemon start        # start the shell
vastctl daemon start -v     # also stream quickshell output
vastctl daemon status       # config path, pid, uptime
vastctl daemon restart
vastctl daemon stop
vastctl log                 # follow the daemon log
vastctl log --no-follow -n 50
```

Only one shell runs per session. IPC commands never start a shell: they connect to the running daemon from any directory, and fail with a hint if none is running. Only `daemon start` and `--config` choose which shell to start.

The NixOS module runs `vastctl daemon run` (the foreground supervisor) as the service's `ExecStart`, so stopping the unit stops the shell.

### Development

A development checkout is started with the `VAST_SHELL_DEV_DIRECTORY` environment variable, which `vastctl` reads only when starting a daemon. The repo's `.envrc` sets it to the checkout root, so with direnv, `vastctl daemon start` inside the repo starts your checkout. Run `vastctl daemon status` to confirm which config it is using.

To run a development shell next to the installed one, give it its own instance name:

```sh
VAST_INSTANCE=dev VAST_SHELL_DEV_DIRECTORY="$PWD" vastctl daemon start
VAST_INSTANCE=dev vastctl daemon status
VAST_INSTANCE=dev vastctl wallpaper get
```

### Shell completions

```sh
vastctl completion bash    | sudo tee /etc/bash_completion.d/vastctl
vastctl completion fish    | sudo tee /usr/share/fish/vendor_completions.d/vastctl.fish
vastctl completion zsh     | sudo tee /usr/share/zsh/site-functions/_vastctl
vastctl completion nushell | sudo tee /usr/share/nushell/completions/vastctl.nu
```

Completions are dynamic: audio devices, clipboard queries, shortcut names and color schemes are read from the running shell.

## Color templates

`vastctl color render` fills your own template files with the colors of the current wallpaper. Templates are listed in `~/.config/vast-shell/templates.json` (see [Configuration](Configuration.md#color-templates)).

A template is a text file with placeholders:

```text
{{colors.<role>.<format>}}
{{colors.<role>.<light|dark>.<format>}}
```

- `role` is a Material role name. `onSurface` and `on_surface` are the same.
- `format` is `hex`, `hex_stripped`, `rgb` or `rgba`.
- Without `light` or `dark`, the shell's current mode is used.
- `{{mode}}` is the current mode and `{{image}}` is the wallpaper path.
- `| alpha: 0.5` sets the alpha of one placeholder.

Example, `~/.config/hypr/colors.conf.tmpl`:

```text
$primary = 0x{{colors.primary.hex_stripped | alpha: 0.6}}
$background = {{colors.background.rgba | alpha: 0.5}}
$text = {{colors.onSurface.rgb}}
$surface = {{colors.surface.hex}}
```

The output is named after the template (`colors.conf.tmpl` becomes `colors.conf`; other names get `.rendered`) and is written next to it unless `output_path` says otherwise.

> [!WARNING]
> A rendered file **replaces** any existing file. Hand edits are lost on the next render.

For a video wallpaper, the palette comes from a frame of the video.

To render from a fixed palette, pass a JSON file of roles with `--palette`:

```json
{
  "background": "#1a1111",
  "onSurface": "#f0dede"
}
```

## Hyprland global shortcuts

Dispatch a panel or action from Hyprland:

```sh
# Legacy config
hyprctl dispatch global quickshell:<target>

# Lua config
hyprctl dispatch 'hl.dsp.global("quickshell:<target>")'
```

Targets: `wallpaperSwitcher`, `bar`, `launcher`, `quickSettings`, `session`, `weather`, `settings`, `clipboard`, `recordingPanel`, `dragAndDrop`.

List what your compositor knows with `vastctl hypr shortcuts list`.

## IPC

Call shell functions from a script or keybind:

```sh
vastctl <target> <function> # if you running the shell with vastctl daemon
qs -c <shell directory> ipc call <target> <function> # otherwise
```

| Target | Functions |
|---|---|
| `bar`, `wallpaperSwitcher`, `launcher`, `quickSettings`, `session`, `weather`, `settings`, `clipboard`, `recordingPanel` | `open()`, `openWith(query: string)`, `close()`, `toggle()`. `openWith` prefills the launcher search. |
| `toast` | `open(header: string, description: string, icon: string, duration: int)` |
| `img` | `get(): string`, `set(path: string)` |
| `lock` | `lock()`, `unlock()`, `isLocked(): bool` |
| `captureScreenVideo` | `start()`, `stop()`, `toggle()`, `status(): bool` |
| `captureScreenImage` | `screen(action: string)`, `region(action: string)`, `window(action: string)` |
| `audio` | `deviceList(): string`, `deviceSet(name: string)`, `profileList(): string`, `profileSet(name: string)` |
| `brightness` | `get(): string`, `set(percent: int)`, `change(delta: int)` |
| `volume` | `systemGet(): string`, `systemSet(percent: int)`, `systemChange(delta: int)`, `systemMute()`, `systemUnmute()`, `systemToggleMute()`, `appList(): string`, `appSet(id: int, percent: int)`, `appChange(id: int, delta: int)`, `appMute(id: int)`, `appUnmute(id: int)`, `appToggleMute(id: int)` |
| `mpris` | `togglePlaying()`, `next()`, `previous()`, `stop()`, `status(): bool`, `list(): string` |
| `idle` | `on()`, `off()`, `status(): bool` |
| `keylock` | `capslock(): bool`, `numlock(): bool` |
| `dragAndDrop` | `start()`, `stop()`, `toggle()`, `status(): bool` |
| `clipboardHistory` | `list(): string`, `status(): string`, `remove(id: int)`, `clear(): bool`, `search(query: string)` |
| `color` | `generate(imagePath: string, mode: string, scheme: string): string`, `generateFromColor(colorHex: string, mode: string, scheme: string): string` |
