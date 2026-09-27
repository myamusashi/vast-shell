package cmd

import "testing"

// TestToastDefaults pins the four positional arguments the shell
// expects. Header, icon and duration have defaults, and the shell
// takes all four positionally, so a dropped or reordered argument
// makes a toast render with the wrong title or never disappear.
func TestToastDefaults(t *testing.T) {
	runCall(t,
		[]string{"toast", "open", "vast-shell", "hello", "notification-active", "5000"},
		"toast", "open", "hello")
}

// TestToastFlags pins that the flags reach the shell as the same
// positional payload, in the same order.
func TestToastFlags(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{
			name: "all three overridden",
			args: []string{"toast", "open", "hello", "--header", "Backup", "--icon", "save", "--duration", "1500"},
			want: []string{"toast", "open", "Backup", "hello", "save", "1500"},
		},
		{
			name: "a zero duration is passed through, not defaulted",
			args: []string{"toast", "open", "hello", "--duration", "0"},
			want: []string{"toast", "open", "vast-shell", "hello", "notification-active", "0"},
		},
		{
			name: "an empty header is passed through",
			args: []string{"toast", "open", "hello", "--header", ""},
			want: []string{"toast", "open", "", "hello", "notification-active", "5000"},
		},
		{
			name: "a description with spaces survives",
			args: []string{"toast", "open", "two words"},
			want: []string{"toast", "open", "vast-shell", "two words", "notification-active", "5000"},
		},
		{
			name: "the short flags are the same",
			args: []string{"toast", "open", "hello", "-H", "Backup", "-i", "save", "-d", "1500"},
			want: []string{"toast", "open", "Backup", "hello", "save", "1500"},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

// TestToastRejectsNegativeDuration pins the one piece of validation the
// command does. A negative duration is meaningless to the shell and
// would leave a toast on screen with no timer to take it down.
func TestToastRejectsNegativeDuration(t *testing.T) {
	log := recordShell(t)

	_, err := runCLI(t, "toast", "open", "hello", "--duration=-1")

	wantError(t, err, "invalid duration", "must be >= 0")
	if calls := shimInvocations(t, log); len(calls) != 0 {
		t.Fatalf("the shell was called with %q despite a bad duration", calls)
	}
}

// TestToastRequiresDescription pins the arity. An empty description
// would show a toast with no text, which looks like a rendering bug.
func TestToastRequiresDescription(t *testing.T) {
	recordShell(t)
	if _, err := runCLI(t, "toast", "open"); err == nil {
		t.Fatal("a missing description must be rejected")
	}
}
