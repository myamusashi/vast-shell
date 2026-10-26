package cmd

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/myamusashi/vast-shell/vastctl/internal/wallpaper"
)

// renderShim answers the two IPC calls a render makes: the current
// wallpaper and the palette. The shim of cli_test.go answers every
// call the same way, which would hand the renderer a palette where a
// wallpaper belongs.
const renderShim = `#!/bin/sh
if [ -n "$SHIM_LOG" ]; then
  { printf -- '---\n'; for a in "$@"; do printf -- '%s\n' "$a"; done; } > "$SHIM_LOG/$$"
fi
case "$*" in
  *" img get"*) printf '%s' "$SHIM_WALLPAPER" ;;
  *" color generate"*) printf '%s' "$SHIM_PALETTE" ;;
esac
exit 0
`

// installRenderShims puts a quickshell shim in front of the PATH, so a
// test never reaches the shell of the developer.
func installRenderShims(t *testing.T) {
	t.Helper()
	directory := t.TempDir()
	if err := os.WriteFile(filepath.Join(directory, "quickshell"), []byte(renderShim), 0o755); err != nil {
		t.Fatalf("write the quickshell shim: %v", err)
	}
	t.Setenv("PATH", directory+string(os.PathListSeparator)+os.Getenv("PATH"))
}

// fakeFfmpegShim answers the calls a frame extraction makes.
const fakeFfmpegShim = `#!/bin/sh
case "$1" in
  -v)
    printf -- '%s' "$SHIM_DURATION"
    exit 0
    ;;
esac
for argument in "$@"; do
  case "$argument" in
    *.png) output="$argument" ;;
  esac
done
printf -- 'frame' > "$output"
exit 0
`

// installFfmpegShim puts a fake ffmpeg and ffprobe in front of the
// PATH, so a test can extract a frame without the real ones.
func installFfmpegShim(t *testing.T, duration string) {
	t.Helper()
	directory := t.TempDir()
	for _, name := range []string{"ffmpeg", "ffprobe"} {
		if err := os.WriteFile(filepath.Join(directory, name), []byte(fakeFfmpegShim), 0o755); err != nil {
			t.Fatalf("write the %s shim: %v", name, err)
		}
	}
	t.Setenv("PATH", directory+string(os.PathListSeparator)+os.Getenv("PATH"))
	t.Setenv("SHIM_DURATION", duration)
}

// writeTemplateList writes the template list the render reads and
// returns the directory it lives in.
func writeTemplateList(t *testing.T, content string) string {
	t.Helper()
	directory := t.TempDir()
	t.Setenv("XDG_CONFIG_DIR", directory)
	shellDirectory := filepath.Join(directory, "vast-shell")
	if err := os.MkdirAll(shellDirectory, 0o755); err != nil {
		t.Fatalf("create %s: %v", shellDirectory, err)
	}
	if err := os.WriteFile(filepath.Join(shellDirectory, "templates.json"), []byte(content), 0o644); err != nil {
		t.Fatalf("write the template list: %v", err)
	}
	return directory
}

// TestColorRender pins a render through the command: the palette comes
// from the shell and the rendered file lands next to the template.
func TestColorRender(t *testing.T) {
	installRenderShims(t)
	directory := writeTemplateList(t, "")
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("bg={{colors.surface.hex}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	writeTemplateList(t, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true}]}`)
	t.Setenv("SHIM_WALLPAPER", "/wall.png")
	t.Setenv("SHIM_PALETTE", `{"colors":{"surface":"#112233"}}`)

	if _, err := runCLI(t, "color", "render"); err != nil {
		t.Fatalf("vastctl color render: %v", err)
	}
	rendered, err := os.ReadFile(filepath.Join(directory, "colors.conf"))
	if err != nil {
		t.Fatalf("read the rendered file: %v", err)
	}
	if string(rendered) != "bg=#112233\n" {
		t.Fatalf("the rendered file holds %q", rendered)
	}
}

// TestColorRenderAlias pins that the command answers to the plural
// name as well.
func TestColorRenderAlias(t *testing.T) {
	installRenderShims(t)
	directory := writeTemplateList(t, "")
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("bg={{colors.surface.hex}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	writeTemplateList(t, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true}]}`)
	t.Setenv("SHIM_WALLPAPER", "/wall.png")
	t.Setenv("SHIM_PALETTE", `{"colors":{"surface":"#112233"}}`)

	if _, err := runCLI(t, "colors", "render"); err != nil {
		t.Fatalf("vastctl colors render: %v", err)
	}
	if _, err := os.Stat(filepath.Join(directory, "colors.conf")); err != nil {
		t.Fatalf("the template was not rendered: %v", err)
	}
}

// TestColorRenderReplacesTheOutput pins that a rendered file replaces
// the file that is already there.
func TestColorRenderReplacesTheOutput(t *testing.T) {
	installRenderShims(t)
	directory := writeTemplateList(t, "")
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("bg={{colors.surface.hex}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	output := filepath.Join(directory, "colors.conf")
	if err := os.WriteFile(output, []byte("edited by hand\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", output, err)
	}
	writeTemplateList(t, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true}]}`)
	t.Setenv("SHIM_WALLPAPER", "/wall.png")
	t.Setenv("SHIM_PALETTE", `{"colors":{"surface":"#112233"}}`)

	if _, err := runCLI(t, "color", "render"); err != nil {
		t.Fatalf("vastctl color render: %v", err)
	}
	written, err := os.ReadFile(output)
	if err != nil {
		t.Fatalf("read the rendered file: %v", err)
	}
	if string(written) != "bg=#112233\n" {
		t.Fatalf("the rendered file holds %q", written)
	}
}

// TestColorRenderNamedTemplate pins that a named template is rendered
// and that an unknown name is an error.
func TestColorRenderNamedTemplate(t *testing.T) {
	installRenderShims(t)
	directory := writeTemplateList(t, "")
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("bg={{colors.surface.hex}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	writeTemplateList(t, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true}]}`)
	t.Setenv("SHIM_WALLPAPER", "/wall.png")
	t.Setenv("SHIM_PALETTE", `{"colors":{"surface":"#112233"}}`)

	if _, err := runCLI(t, "color", "render", "--template", "colors"); err != nil {
		t.Fatalf("vastctl color render --template colors: %v", err)
	}
	_, err := runCLI(t, "color", "render", "--template", "absent")
	wantError(t, err, "absent")
}

// TestColorRenderUsesWallpaperFlag pins that the wallpaper of the
// command wins over the wallpaper of the shell.
func TestColorRenderUsesWallpaperFlag(t *testing.T) {
	installRenderShims(t)
	directory := writeTemplateList(t, "")
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("image={{image}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	writeTemplateList(t, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true}]}`)
	t.Setenv("SHIM_WALLPAPER", "/wall.png")
	t.Setenv("SHIM_PALETTE", `{"colors":{"surface":"#112233"}}`)

	if _, err := runCLI(t, "color", "render", "--wallpaper", "/other.png"); err != nil {
		t.Fatalf("vastctl color render: %v", err)
	}
	rendered, err := os.ReadFile(filepath.Join(directory, "colors.conf"))
	if err != nil {
		t.Fatalf("read the rendered file: %v", err)
	}
	if string(rendered) != "image=/other.png\n" {
		t.Fatalf("the rendered file holds %q", rendered)
	}
}

// TestColorRenderUsesAFrameOfAVideo pins that a video wallpaper is
// rendered from a frame of it: the palette is built from an image, and
// a video is not one.
func TestColorRenderUsesAFrameOfAVideo(t *testing.T) {
	installRenderShims(t)
	installFfmpegShim(t, "24")
	directory := writeTemplateList(t, "")
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("bg={{colors.surface.hex}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	writeTemplateList(t, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true}]}`)
	t.Setenv("SHIM_WALLPAPER", "/videos/wall.mp4")
	t.Setenv("SHIM_PALETTE", `{"colors":{"surface":"#112233"}}`)
	t.Setenv("XDG_CACHE_DIR", t.TempDir())

	frame, err := wallpaper.CachePath("/videos/wall.mp4")
	if err != nil {
		t.Fatalf("CachePath: %v", err)
	}
	log := recordShell(t)
	if _, err := runCLI(t, "color", "render", "--mode", "dark", "--wallpaper", "/videos/wall.mp4"); err != nil {
		t.Fatalf("vastctl color render: %v", err)
	}
	wantCall(t, log, "color", "generate", frame, "light", "tonal-spot")
	if _, err := os.Stat(frame); err != nil {
		t.Fatalf("the frame was not written: %v", err)
	}
}

// TestColorRenderUsesThePaletteFile pins that a palette file takes the
// place of the palette the shell would build, and that the shell is
// not asked for one.
func TestColorRenderUsesThePaletteFile(t *testing.T) {
	installRenderShims(t)
	directory := writeTemplateList(t, "")
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("bg={{colors.background.hex}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	writeTemplateList(t, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true}]}`)
	paletteFile := filepath.Join(directory, "colors.json")
	if err := os.WriteFile(paletteFile, []byte(`{"background":"#1a1111"}`), 0o644); err != nil {
		t.Fatalf("write %s: %v", paletteFile, err)
	}
	t.Setenv("SHIM_WALLPAPER", "/wall.png")
	t.Setenv("SHIM_PALETTE", `{"colors":{"background":"#000000"}}`)

	log := recordShell(t)
	if _, err := runCLI(t, "color", "render", "--palette", paletteFile); err != nil {
		t.Fatalf("vastctl color render: %v", err)
	}
	written, err := os.ReadFile(filepath.Join(directory, "colors.conf"))
	if err != nil {
		t.Fatalf("read the rendered file: %v", err)
	}
	if string(written) != "bg=#1a1111\n" {
		t.Fatalf("the rendered file holds %q", written)
	}
	wantCall(t, log, "img", "get")
}
