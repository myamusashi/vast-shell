package cmd

import "testing"

func TestHyprDispatch(t *testing.T) {
	t.Setenv("SHIM_HYPR_LOG", newHyprLog(t))

	if _, err := runCLI(t, "hypr", "dispatch", "wallpaperSwitcher"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	wantHyprCall(t, "dispatch", `hl.dsp.global("quickshell:wallpaperSwitcher")`)
}

func TestHyprDispatchRequiresShortcut(t *testing.T) {
	newHyprLog(t)
	if _, err := runCLI(t, "hypr", "dispatch"); err == nil {
		t.Fatal("a missing shortcut name must be rejected")
	}
}

func TestHyprDispatchFailure(t *testing.T) {
	newHyprLog(t)
	t.Setenv("SHIM_HYPR_CODE", "1")

	_, err := runCLI(t, "hypr", "dispatch", "nope")

	wantError(t, err, "hyprctl dispatch", "exit status 1")
}

func TestHyprShortcutsList(t *testing.T) {
	t.Setenv("SHIM_HYPR_LOG", newHyprLog(t))
	t.Setenv("SHIM_HYPR_OUT", `[
	  {"name":"quickshell:bar","description":"toggle the bar"},
	  {"name":"special:workspace,1","description":"a hyprland bind"},
	  {"name":"quickshell:launcher","description":""}
	]`)

	res, err := runCLI(t, "hypr", "shortcuts", "list")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	want := "├── bar\n" +
		"│   ├── description: toggle the bar\n" +
		"│   └── name: bar\n" +
		"└── launcher\n" +
		"    ├── description: <empty>\n" +
		"    └── name: launcher\n\n"
	if res.stdout != want {
		t.Fatalf("stdout =\n%q\nwant\n%q", res.stdout, want)
	}
	wantHyprCall(t, "globalshortcuts", "-j")
}

func TestHyprShortcutsListJSON(t *testing.T) {
	newHyprLog(t)
	t.Setenv("SHIM_HYPR_OUT", `[{"name":"quickshell:bar","description":"toggle"}]`)

	res, err := runCLI(t, "hypr", "shortcuts", "list", "--json")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	want := `[{"name":"bar","description":"toggle"}]` + "\n"
	if res.stdout != want {
		t.Fatalf("stdout = %q, want %q", res.stdout, want)
	}
}

func TestHyprShortcutsListEmpty(t *testing.T) {
	newHyprLog(t)
	t.Setenv("SHIM_HYPR_OUT", "[]")

	res, err := runCLI(t, "hypr", "shortcuts", "list")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if want := "(empty)\n"; res.stdout != want {
		t.Fatalf("stdout = %q, want %q", res.stdout, want)
	}
}

func TestHyprShortcutsListFailure(t *testing.T) {
	newHyprLog(t)
	t.Setenv("SHIM_HYPR_CODE", "1")
	t.Setenv("SHIM_HYPR_OUT", "could not connect to display\n")

	res, err := runCLI(t, "hypr", "shortcuts", "list")

	wantError(t, err, "hyprctl globalshortcuts")
	if res.output() != "" {
		t.Fatalf("a failed listing printed %q", res.output())
	}
}
