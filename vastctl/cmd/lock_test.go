package cmd

import "testing"

// TestLock pins the screen-lock verbs. Status asks for isLocked,
// which is not the same method name as the lock and unlock verbs —
// a copy-paste slip here would lock the screen when asked for its
// state.
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

// TestLockStatusPrintsState pins that status answers with a value.
// Scripts that gate on `vastctl lock status` have nothing to branch on
// if the command stays silent.
func TestLockStatusPrintsState(t *testing.T) {
	t.Setenv("SHIM_OUT", "true")

	res := runCall(t, []string{"lock", "isLocked"}, "lock", "status")

	if want := "true\n"; res.stdout != want {
		t.Fatalf("stdout = %q, want %q", res.stdout, want)
	}
}
