# Usage

[Back to README](../README.md)

## vastctl (CLI Companion)

`vastctl` is a standalone Go binary for scripting vast-shell from the command line. It can launch the shell in the background and control every feature through IPC.

```
vastctl [--json]
├── audio profile list / set <name>
│       device list / set <name>
├── brightness get
│           set [+|-]<%>
├── captureScreenImage screen / region / window [action]   # alias: capture
├── captureScreenVideo start / stop / toggle / status     # alias: record
├── clipboard list / status / remove <id> / clear / search <query>
├── color generate <image-path>                           # --mode, --scheme, --out, --raw
│       from <hex-color>
│       render                                           # --template, --wallpaper, --mode, --scheme
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

`set` commands accept absolute percentages (`50`, `50%`) and relative adjustments (`+10%`, `-10%`) that change the current value instead of replacing it:

```sh
vastctl volume system set +10%
vastctl brightness set -5%
```

### Flags

| Command | Flag | Default | Description |
|---|---|---|---|
| (global) | `--json` | `false` | Print raw JSON instead of the rendered tree. |
| `daemon start` | `-v`, `--verbose` | `false` | Stream quickshell output to the terminal. |
| `daemon` | `-f`, `--foreground` | `false` | Run the supervisor in the foreground. |
| `daemon` | `--config` | `$VAST_SHELL_DEV_DIRECTORY`, else the installed config | Config directory to run. Honoured only when starting a daemon, never by IPC commands. |
| `log` | `-n`, `--lines` | `20` | Number of trailing lines to print. |
| `log` | `--no-follow` | `false` | Print the tail once and exit instead of following. |
| `toast open` | `-H`, `--header` | `vast-shell` | Toast header. |
| `toast open` | `-i`, `--icon` | `notification-active` | Icon name or absolute image path. |
| `toast open` | `-d`, `--duration` | `5000` | Display time in milliseconds. |
| `color` | `--mode` | `dark` | `dark` or `light`. |
| `color` | `--scheme` | `tonal-spot` | Any of the nine Material schemes. |
| `color` | `--out` | *(stdout)* | Write the JSON result to a file. |
| `color` | `--raw` | `false` | Skip the tree renderer (implied by `--out`). |
| `color render` | `--template` | *(every enabled template)* | Render only the template with this name. |
| `color render` | `--wallpaper` | *(the current wallpaper)* | Render from this wallpaper instead of the current one. |

### Color templates

`vastctl color render` renders your own templates with the palette of the current wallpaper. 
The palette comes from the running shell, so a rendered file always matches the colors
the shell is using.

A template is a plain text file with placeholders:

```
{{colors.<role>.<format>}}
```

- `role` is a Material role name. `onSurface` and `on_surface` are the same role.
- `format` is one of `hex`, `hex_stripped`, `rgb` or `rgba`.
- `{{mode}}` is the color mode (`dark` or `light`), `{{image}}` is the wallpaper path.
- `| alpha: 0.5` sets the alpha of a single placeholder.

Example, `~/.config/hypr/colors.conf.tmpl`:

```
$primary = 0x{{colors.primary.hex_stripped | alpha: 0.6}}
$background = {{colors.background.rgba | alpha: 0.5}}
$text = {{colors.onSurface.rgb}}
$surface = {{colors.surface.hex}}
$dim = {{colors.onSurfaceVariant.hex | alpha: 0.6}}
```

The output file is named after the template: `colors.conf.tmpl` and
`colors.conf.template` are rendered into `colors.conf`, and a template
without one of those suffixes is rendered into `<name>.rendered`. The file
lands next to the template unless `output_path` says otherwise.

> [!WARNING]
> A rendered file **replaces** the file that is already there. A file you
> edited by hand is lost when the template is rendered again.

A **video wallpaper** is rendered from a frame of it: the frame the shell
already cached (`~/.cache/vast-shell/vast-wallpaper-<hash>-1024.png`), or a
new one taken from the middle of the video with `ffmpeg` when the cache does
not have it yet.

The templates live in `~/.config/vast-shell/templates.json`:

```json
{
  "templates": [
    {
      "name": "hyprland",
      "input": "~/.config/hypr/colors.conf.tmpl",
      "output_path": "",
      "post_hook": "hyprctl reload",
      "enabled": true
    }
  ]
}
```

| Key | Description |
|---|---|
| `name` | The name `--template` selects. |
| `input` | The template file. `~` and environment variables are expanded. |
| `output_path` | Optional. Empty means next to the template. |
| `post_hook` | Optional command that runs after the file was written. |
| `enabled` | Optional, defaults to `true`. A disabled template is skipped. |


### The running daemon is the source of truth

IPC commands only ever connect. They never start a shell, and they never
work out which shell to talk to from your working directory, your
environment or the installed location. A supervisor holds an exclusive
lock and publishes the running shell's identity under
`$XDG_RUNTIME_DIR/vast/`; every `vastctl` command routes to that
identity, whatever directory it is called from.

```sh
vastctl daemon start          # take the lock, launch the shell
vastctl daemon start -v       # also stream quickshell's output to the terminal
vastctl daemon status         # namespace, state file, pid, instance id, config path, uptime
vastctl daemon restart
vastctl daemon stop           # signals the recorded supervisor
vastctl log                   # watch the daemon log (tail -f style)
vastctl log --no-follow -n 50 # print the last 50 lines and exit
```

With no daemon running, an IPC command fails and says how to start one
instead of quietly launching a second shell, two shells on one session
contend for the same IPC targets, and the desktop you get is whichever
process won the race.

`VAST_SHELL_DIRECTORY` and `--config` decide what `vastctl daemon`
**starts**. They are deliberately ignored by IPC commands, so a stray
environment variable cannot redirect a call to a shell that isn't
running.

The package wrappers set `VAST_SHELL_DIRECTORY` themselves, so an
ambient value cannot redirect the installed shell. A development
checkout does not set that variable; it sets
`VAST_SHELL_DEV_DIRECTORY`, which `vastctl` honours when it decides what
to start and which then beats the wrapper value.

### Running two shells on purpose

`VAST_INSTANCE` selects an isolated runtime namespace, giving a daemon
its own lock and state file under `$XDG_RUNTIME_DIR/<name>/`:

```sh
VAST_INSTANCE=dev VAST_SHELL_DEV_DIRECTORY="$PWD" vastctl daemon start
VAST_INSTANCE=dev vastctl daemon status
VAST_INSTANCE=dev vastctl wallpaper get
```

That is the supported way to run a development checkout beside the
installed shell. Each namespace addresses its own daemon, and the two
never fight over the same IPC name.

### Service manager

`vastctl daemon run` is the supervisor: it takes the lock, launches the
shell and stays in the foreground so the service manager tracks it. The
NixOS module uses it as the unit's `ExecStart`, and signal forwarding
means stopping the unit stops the shell cleanly.

### Development

`VAST_SHELL_DEV_DIRECTORY` names the checkout root, but the config path
handed to quickshell is the directory that actually holds `shell.qml` —
`$PWD/Qml` here. `vastctl daemon status` prints the resolved path, which
is the quickest way to confirm which instance a command will reach.

The repo's `.envrc` exports `VAST_SHELL_DEV_DIRECTORY="$PWD"`, so with
direnv enabled, `vastctl daemon start` inside the repo starts the
development checkout. Only `vastctl` reads the dev variable, so a dev
shell is started through it (`vastctl daemon start`, or `vastctl daemon
run` in the foreground) rather than by running `qs` directly — `qs` runs
the installed config. An ambient `VAST_SHELL_DIRECTORY` is ignored by the
packaged wrappers, which is what keeps a rebuilt system from launching
the previous generation's store path.

### Shell completions

```sh
vastctl completion bash   | sudo tee /etc/bash_completion.d/vastctl
vastctl completion fish   | sudo tee /usr/share/fish/vendor_completions.d/vastctl.fish
vastctl completion zsh    | sudo tee /usr/share/zsh/site-functions/_vastctl
vastctl completion nushell | sudo tee /usr/share/nushell/completions/vastctl.nu
```

Completions are generated by [carapace](https://github.com/carapace-sh/carapace) and are dynamic: audio devices, volume sinks, clipboard queries, Hyprland shortcut names, and color modes/schemes are resolved live from the running shell.

### Development

Quickshell routes `ipc call` to the instance launched from the same config path, so vastctl targets whatever config directory it resolves (falling back to the installed `shell` wrapper). To control a shell running from this repository:

```sh
VAST_SHELL_DEV_DIRECTORY="$PWD" vastctl daemon status   # prints the config path vastctl resolved
VAST_SHELL_DEV_DIRECTORY="$PWD" vastctl idle status
```

`VAST_SHELL_DEV_DIRECTORY` names the checkout root, but the config path handed to quickshell is the directory that actually holds `shell.qml` — `$PWD/Qml` here. `vastctl daemon status` prints the resolved path, which is the quickest way to confirm which instance a command will reach.

> [!NOTE]
> `VAST_SHELL_DIRECTORY` selects the *shell instance*, not the config file. Configuration always comes from `~/.config/vast-shell/configurations.json`,
> see [Configuration](Configuration.md).

The repo's `.envrc` exports `VAST_SHELL_DEV_DIRECTORY="$PWD"`, so with direnv enabled every vastctl invocation inside the repo automatically targets the dev instance. `vastctl daemon status` prints the resolved directory, and names `VAST_SHELL_DIRECTORY` when it had to pass one over.

## Hyprland Global Shortcuts

Dispatch a panel or action directly from Hyprland:

Old hyprland command:
```sh
hyprctl dispatch global quickshell:<target>
```

Lua command:
```sh
hyprctl dispatch 'hl.dsp.global("quickshell:<target>")'
```

Available targets (10, all registered as `GlobalShortcut` in the shell):

`wallpaperSwitcher`, `bar`, `launcher`, `quickSettings`, `session`, `weather`, `settings`, `clipboard`, `recordingPanel`, `dragAndDrop`

List what your compositor knows about:

```sh
vastctl hypr shortcuts list
```

## IPC

Call shell functions from a script or keybind:

```sh
# Full form
quickshell -c <shell directory> ipc call <target> <function>

# Short alias
qs -c <shell directory> ipc call <target> <function>

# If installed via archInstall.sh or the Nix flake
shell ipc call <target> <function>
```

**Available targets and functions:**

| Target | Functions |
|---|---|
| `bar`, `wallpaperSwitcher`, `launcher`, `quickSettings`, `session`, `weather`, `settings`, `clipboard`, `recordingPanel` | `open()`, `openWith(query: string)`, `close()`, `toggle()` — `openWith` prefills the launcher search |
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
