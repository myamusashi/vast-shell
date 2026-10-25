package cmd

import "testing"

// Status maps to isLocked, not lock or unlock.
func TestLock(t *testing.T) {
	t.Setenv("SHIM_OUT", "false")

	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"lock", []string{"lock", "lock"}, []string{"lock", "lock"}},
		{"unlock", []string{"lock", "unlock"}, []string{"lock", "unlock"}},
		{"status", []string{"lock", "status"}, []string{"lock", "isLocked"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

func TestLockStatusPrintsState(t *testing.T) {
	t.Setenv("SHIM_OUT", "true")

	res := runCall(t, []string{"lock", "isLocked"}, "lock", "status")

	if want := "true\n"; res.stdout != want {
		t.Fatalf("stdout = %q, want %q", res.stdout, want)
	}
}
