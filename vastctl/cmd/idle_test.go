package cmd

import "testing"

// TestIdle pins the idle monitor verbs.
func TestIdle(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"on", []string{"idle", "on"}, []string{"idle", "on"}},
		{"off", []string{"idle", "off"}, []string{"idle", "off"}},
		{"status", []string{"idle", "status"}, []string{"idle", "status"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

// TestIdleStatusPrintsState pins that status is readable. The whole
// point of the command is to answer "is the monitor on", and a void
// call would answer nothing.
func TestIdleStatusPrintsState(t *testing.T) {
	t.Setenv("SHIM_OUT", "true")

	res := runCall(t, []string{"idle", "status"}, "idle", "status")

	if want := "true\n"; res.stdout != want {
		t.Fatalf("stdout = %q, want %q", res.stdout, want)
	}
}
