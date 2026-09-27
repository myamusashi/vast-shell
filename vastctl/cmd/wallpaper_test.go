package cmd

import (
	"strings"
	"testing"
)

// TestWallpaper pins the img target and its two methods.
func TestWallpaper(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"get", []string{"wallpaper", "get"}, []string{"img", "get"}},
		{"set", []string{"wallpaper", "set", "/tmp/pic.png"}, []string{"img", "set", "/tmp/pic.png"}},
		{"a path with spaces survives", []string{"wallpaper", "set", "/tmp/my pics/a.png"}, []string{"img", "set", "/tmp/my pics/a.png"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

// TestWallpaperGetPrintsPath pins that get returns something usable.
// Scripts assign the result straight to a variable, and a tree
// rendering or a stray blank line would be pasted into whatever
// consumes it.
func TestWallpaperGetPrintsPath(t *testing.T) {
	t.Setenv("SHIM_OUT", "/home/me/Pictures/wall.png\n")

	res := runCall(t, []string{"img", "get"}, "wallpaper", "get")

	if want := "/home/me/Pictures/wall.png\n"; res.stdout != want {
		t.Fatalf("stdout = %q, want %q", res.stdout, want)
	}
}

// TestWallpaperSetPrintsNothing pins that a set stays quiet, so it can
// be bound to a key without spamming the notification layer.
func TestWallpaperSetPrintsNothing(t *testing.T) {
	res := runCall(t, []string{"img", "set", "/tmp/pic.png"}, "wallpaper", "set", "/tmp/pic.png")
	if res.output() != "" {
		t.Fatalf("a void call printed %q", res.output())
	}
}

// TestWallpaperSetRequiresPath pins the arity. An empty path would ask
// the shell to set the wallpaper to nothing.
func TestWallpaperSetRequiresPath(t *testing.T) {
	recordShell(t)
	if _, err := runCLI(t, "wallpaper", "set"); err == nil {
		t.Fatal("a missing path must be rejected")
	}
}

// TestVoidCallPrintsNothing pins the shared ipcCallVoid contract across
// the commands that have no output of their own. A void call that
// printed anything would make every keybinding bound to it noisy.
func TestVoidCallPrintsNothing(t *testing.T) {
	for _, args := range [][]string{
		{"wallpaper", "set", "/tmp/pic.png"},
		{"lock", "lock"},
		{"idle", "on"},
		{"dragAndDrop", "toggle"},
	} {
		t.Run(strings.Join(args, " "), func(t *testing.T) {
			recordShell(t)
			res, err := runCLI(t, args...)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if res.output() != "" {
				t.Fatalf("a void call printed %q", res.output())
			}
		})
	}
}
