package cmd

import "testing"

// TestDragAndDrop pins the IPC verbs. The `dragAndDrop` target name is
// a Go-style identifier that has to match the shell's handler exactly,
// so it is asserted rather than assumed.
func TestDragAndDrop(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"start", []string{"dragAndDrop", "start"}, []string{"dragAndDrop", "start"}},
		{"stop", []string{"dragAndDrop", "stop"}, []string{"dragAndDrop", "stop"}},
		{"toggle", []string{"dragAndDrop", "toggle"}, []string{"dragAndDrop", "toggle"}},
		{"status", []string{"dragAndDrop", "status"}, []string{"dragAndDrop", "status"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

// TestDragAndDropShortcutUsesHyprland pins that the shortcut arming goes
// through Hyprland rather than the IPC target. It dispatches the global
// bind named "dragAndDrop", so the quickshell: prefix the dispatcher
// adds has to line up with the bind the shell registers.
func TestDragAndDropShortcutUsesHyprland(t *testing.T) {
	t.Setenv("SHIM_HYPR_LOG", newHyprLog(t))

	res, err := runCLI(t, "dragAndDrop", "shortcut")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	wantHyprCall(t, "dispatch", `hl.dsp.global("quickshell:dragAndDrop")`)
	if res.output() != "" {
		t.Fatalf("a dispatch printed %q", res.output())
	}
}

// TestDragAndDropShortcutDoesNotCallIPC pins the two paths are
// exclusive. Firing both arms the drop target twice and the second
// arm is a no-op the user cannot see.
func TestDragAndDropShortcutDoesNotCallIPC(t *testing.T) {
	log := recordShell(t)
	t.Setenv("SHIM_HYPR_LOG", newHyprLog(t))

	if _, err := runCLI(t, "dragAndDrop", "shortcut"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if calls := shimInvocations(t, log); len(calls) != 0 {
		t.Fatalf("quickshell was called with %q as well as hyprctl", calls)
	}
}
