package hypr

import (
	"errors"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"
)

// The hyprctl shim stands in for the compositor bridge. Dispatch and
// ListShortcuts are the only things this package shells out to, and
// PATH is narrowed to the shim directory so a test can never reach the
// developer's live Hyprland — dispatching a real global shortcut from a
// unit test would fire whatever that shortcut is bound to.

const hyprctlShim = `#!/bin/sh
if [ -n "$HYPR_LOG" ]; then
  { printf -- '---\n'; for a in "$@"; do printf -- '%s\n' "$a"; done; } > "$HYPR_LOG/$$"
fi
if [ -n "$HYPR_ERR" ]; then printf -- '%s' "$HYPR_ERR" >&2; fi
if [ -n "$HYPR_OUT" ]; then printf -- '%s' "$HYPR_OUT"; fi
exit "${HYPR_CODE:-0}"
`

// installHyprctl puts a recording hyprctl on PATH and returns the path
// of the invocation log. stdout, stderr and the exit status are driven
// by the HYPR_OUT, HYPR_ERR and HYPR_CODE variables.
func installHyprctl(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "hyprctl"), []byte(hyprctlShim), 0o755); err != nil {
		t.Fatalf("write hyprctl shim: %v", err)
	}
	log := t.TempDir()
	t.Setenv("HYPR_LOG", log)
	t.Setenv("PATH", dir)
	return log
}

// hyprctlInvocations returns the argument list of every invocation
// recorded in the shim's log directory, oldest first. Each run writes
// one file named after its own pid.
func hyprctlInvocations(t *testing.T, dir string) [][]string {
	t.Helper()
	entries, err := os.ReadDir(dir)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil
		}
		t.Fatalf("read hyprctl log directory: %v", err)
	}
	type record struct {
		info os.FileInfo
		args []string
	}
	var records []record
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		info, err := e.Info()
		if err != nil {
			t.Fatalf("stat hyprctl record: %v", err)
		}
		data, err := os.ReadFile(filepath.Join(dir, e.Name()))
		if err != nil {
			t.Fatalf("read hyprctl record: %v", err)
		}
		lines := strings.Split(strings.TrimSuffix(string(data), "\n"), "\n")
		if len(lines) == 1 && lines[0] == "---" {
			// A run with no arguments; hyprctl is never called that way
			// here, so this is a leftover rather than a real record.
			continue
		}
		records = append(records, record{info: info, args: lines[1:]})
	}
	sort.Slice(records, func(i, j int) bool {
		if !records[i].info.ModTime().Equal(records[j].info.ModTime()) {
			return records[i].info.ModTime().Before(records[j].info.ModTime())
		}
		return records[i].info.Name() < records[j].info.Name()
	})
	calls := make([][]string, 0, len(records))
	for _, r := range records {
		calls = append(calls, r.args)
	}
	return calls
}

func lastCall(t *testing.T, log string) []string {
	t.Helper()
	calls := hyprctlInvocations(t, log)
	if len(calls) == 0 {
		t.Fatal("hyprctl was never invoked")
	}
	return calls[len(calls)-1]
}

// TestDispatch pins the dispatcher string. Hyprland's Lua dispatcher
// only reaches a vast-shell shortcut through a quickshell: bind, so the
// prefix is not cosmetic — drop it or rename it and every dispatch
// silently does nothing.
func TestDispatch(t *testing.T) {
	log := installHyprctl(t)

	if err := Dispatch("wallpaperSwitcher"); err != nil {
		t.Fatalf("Dispatch returned an unexpected error: %v", err)
	}

	want := []string{"dispatch", `hl.dsp.global("quickshell:wallpaperSwitcher")`}
	got := lastCall(t, log)
	if len(got) != len(want) {
		t.Fatalf("hyprctl %q, want %q", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("hyprctl %q, want %q", got, want)
		}
	}
}

// TestDispatchFailure pins that a rejected dispatch surfaces as an
// error naming the offending argument. Dispatching an unregistered
// shortcut is the common case and hyprctl rejects it silently, so
// swallowing the exit status would leave the user with no clue.
func TestDispatchFailure(t *testing.T) {
	log := installHyprctl(t)
	t.Setenv("HYPR_CODE", "1")

	err := Dispatch("nope")
	if err == nil {
		t.Fatal("a failed hyprctl dispatch must be reported")
	}
	for _, want := range []string{"hyprctl dispatch", `hl.dsp.global("quickshell:nope")`, "exit status 1"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("error %q does not mention %q", err, want)
		}
	}
	if got := lastCall(t, log); len(got) != 2 || got[0] != "dispatch" {
		t.Fatalf("hyprctl %q, want a dispatch invocation", got)
	}
}

// TestDispatchWithoutHyprctl pins the missing-binary case separately
// from the exit-status one: they produce different errors, and only the
// first names the dependency.
func TestDispatchWithoutHyprctl(t *testing.T) {
	t.Setenv("PATH", t.TempDir())

	err := Dispatch("launcher")
	if err == nil {
		t.Fatal("a missing hyprctl must be reported")
	}
	if !strings.Contains(err.Error(), "hyprctl") {
		t.Fatalf("error %q does not name the missing binary", err)
	}
}

// TestListShortcuts pins the quickshell: filter and the prefix trim.
// The bind table also holds Hyprland's own and the user's binds, and
// what the caller receives is the bare shortcut name it has to feed
// back into Dispatch.
func TestListShortcuts(t *testing.T) {
	log := installHyprctl(t)
	t.Setenv("HYPR_OUT", `[
	  {"name":"quickshell:bar","description":"toggle bar"},
	  {"name":"special:workspace,1","description":"hyprland bind"},
	  {"name":"quickshell:launcher","description":""}
	]`)

	shortcuts, err := ListShortcuts()
	if err != nil {
		t.Fatalf("ListShortcuts returned an unexpected error: %v", err)
	}

	want := []Shortcut{
		{Name: "bar", Description: "toggle bar"},
		{Name: "launcher", Description: ""},
	}
	if len(shortcuts) != len(want) {
		t.Fatalf("got %d shortcuts (%+v), want %d", len(shortcuts), shortcuts, len(want))
	}
	for i := range want {
		if shortcuts[i] != want[i] {
			t.Errorf("shortcut %d = %+v, want %+v", i, shortcuts[i], want[i])
		}
	}

	if got := lastCall(t, log); len(got) != 2 || got[0] != "globalshortcuts" || got[1] != "-j" {
		t.Fatalf("hyprctl %q, want [globalshortcuts -j]", got)
	}
}

// TestListShortcutsEmpty pins the two empty answers. Callers print the
// result directly, so "no binds" has to come back as an empty slice
// rather than an error the user has to read past. Empty output is not
// one of them: hyprctl always answers with JSON, so nothing at all
// means the command misbehaved and is reported as such.
func TestListShortcutsEmpty(t *testing.T) {
	for _, tc := range []struct{ name, out string }{
		{"empty array", "[]"},
		{"json null", "null"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			installHyprctl(t)
			t.Setenv("HYPR_OUT", tc.out)

			shortcuts, err := ListShortcuts()
			if err != nil {
				t.Fatalf("ListShortcuts returned an unexpected error: %v", err)
			}
			if len(shortcuts) != 0 {
				t.Fatalf("got %+v, want no shortcuts", shortcuts)
			}
		})
	}
}

// TestListShortcutsInvalidJSON pins that a non-JSON answer is an error.
// Parsing it as an empty table would make a broken Hyprland look
// exactly like a shell with no shortcuts registered.
func TestListShortcutsInvalidJSON(t *testing.T) {
	installHyprctl(t)
	t.Setenv("HYPR_OUT", "could not connect to display")

	shortcuts, err := ListShortcuts()
	if err == nil {
		t.Fatalf("non-JSON output must be reported, got %+v", shortcuts)
	}
	if !strings.Contains(err.Error(), "json") {
		t.Fatalf("error %q does not say the payload was unparseable", err)
	}
}

// TestListShortcutsFailure pins that a failed hyprctl is an error
// rather than an empty list, and that hyprctl's own stderr survives
// into the message.
//
// Capturing stdout alone degrades every failure to a bare "exit status
// 1" naming neither the command nor the reason, which is the case a
// user hits when no Hyprland instance is running.
func TestListShortcutsFailure(t *testing.T) {
	log := installHyprctl(t)
	t.Setenv("HYPR_CODE", "1")
	t.Setenv("HYPR_ERR", "no instances found\n")

	shortcuts, err := ListShortcuts()
	if err == nil {
		t.Fatalf("a failed hyprctl must be reported, got %+v", shortcuts)
	}
	for _, want := range []string{"hyprctl globalshortcuts", "no instances found"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("error %q does not mention %q", err, want)
		}
	}
	if strings.Contains(err.Error(), "exit status") {
		t.Errorf("error %q degrades to a bare exit status", err)
	}
	if got := lastCall(t, log); len(got) != 2 || got[0] != "globalshortcuts" {
		t.Fatalf("hyprctl %q, want [globalshortcuts -j]", got)
	}
}

// TestListShortcutsSilentFailure pins that a failure with nothing on
// stderr still names the command and the exit status. There is nothing
// better to report, but it must not be a bare exit status with no
// indication of what was run.
func TestListShortcutsSilentFailure(t *testing.T) {
	installHyprctl(t)
	t.Setenv("HYPR_CODE", "1")

	_, err := ListShortcuts()
	if err == nil {
		t.Fatal("a failed hyprctl must be reported")
	}
	for _, want := range []string{"hyprctl globalshortcuts", "exit status 1"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("error %q does not mention %q", err, want)
		}
	}
}
