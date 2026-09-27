package cmd

import "testing"

// TestRecord pins the recording verbs and the `record` alias. The
// alias is what the Short advertises, so a rename that drops it breaks
// every keybinding at once.
func TestRecord(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"start", []string{"record", "start"}, []string{"captureScreenVideo", "start"}},
		{"stop", []string{"record", "stop"}, []string{"captureScreenVideo", "stop"}},
		{"toggle", []string{"record", "toggle"}, []string{"captureScreenVideo", "toggle"}},
		{"status", []string{"record", "status"}, []string{"captureScreenVideo", "status"}},
		{"the full command name is still accepted", []string{"captureScreenVideo", "start"}, []string{"captureScreenVideo", "start"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

// TestRecordStatusPrintsState pins that status answers. A toggle bound
// to a key needs to know whether recording is already running.
func TestRecordStatusPrintsState(t *testing.T) {
	t.Setenv("SHIM_OUT", "true")

	res := runCall(t, []string{"captureScreenVideo", "status"}, "record", "status")

	if want := "true\n"; res.stdout != want {
		t.Fatalf("stdout = %q, want %q", res.stdout, want)
	}
}
