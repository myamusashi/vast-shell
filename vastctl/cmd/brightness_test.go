package cmd

import (
	"strings"
	"testing"
)

// TestBrightness pins the target/method pairs and the absolute/relative
// split. BrightnessSet goes straight to ipc.Call rather than through
// the ipcCallVoid helper, so it is the one set command where a
// regression in the helper would not be caught elsewhere.
func TestBrightness(t *testing.T) {
	t.Setenv("SHIM_OUT", `[{"id":"DP-1","brightness":75}]`)

	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"get", []string{"brightness", "get"}, []string{"brightness", "get"}},
		{"absolute", []string{"brightness", "set", "50%"}, []string{"brightness", "set", "50"}},
		{"absolute without a percent sign", []string{"brightness", "set", "50"}, []string{"brightness", "set", "50"}},
		{"zero", []string{"brightness", "set", "0%"}, []string{"brightness", "set", "0"}},
		{"full", []string{"brightness", "set", "100%"}, []string{"brightness", "set", "100"}},
		{"relative up", []string{"brightness", "set", "+10%"}, []string{"brightness", "change", "10"}},
		{"relative down", []string{"brightness", "set", "-10%"}, []string{"brightness", "change", "-10"}},
		{"the json flag is still accepted", []string{"brightness", "set", "--json", "50%"}, []string{"brightness", "set", "50"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

// TestBrightnessSetRejects pins the bounds. An out-of-range brightness
// that reaches the shell is either clamped silently or turns the
// display black, and neither is visible from the CLI.
func TestBrightnessSetRejects(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
	}{
		{"above the range", []string{"101"}},
		{"not a number", []string{"half"}},
		{"no argument", nil},
		{"two arguments", []string{"10", "20"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			recordShell(t)
			if _, err := runCLI(t, append([]string{"brightness", "set"}, tc.args...)...); err == nil {
				t.Fatal("an out-of-range percent must be rejected")
			}
		})
	}
}

// TestBrightnessGetRendersTree pins the display path. The list command
// is what a user reads to find out which display is which, so the
// per-display rows have to survive to the terminal.
func TestBrightnessGetRendersTree(t *testing.T) {
	t.Setenv("SHIM_OUT", `[{"id":"DP-1","name":"DEL DELL","brightness":75,"isInternal":false}]`)

	res := runCall(t, []string{"brightness", "get"}, "brightness", "get")

	// Tree ends every row with a newline and the command adds one more
	// on top, so the payload is followed by a blank line.
	want := "└── DEL DELL\n    ├── brightness: 75\n    ├── id: DP-1\n    ├── isInternal: no\n    └── name: DEL DELL\n\n"
	if res.stdout != want {
		t.Fatalf("stdout = %q, want %q", res.stdout, want)
	}
}

// TestJSONFlagBypassesTree pins the global --json switch. Scripts pipe
// vastctl into jq, and a tree rendering cannot be parsed back; the
// reverse also matters, because a human reading raw JSON loses the
// point of the tree in the first place.
func TestJSONFlagBypassesTree(t *testing.T) {
	const payload = `{"capsLock":true,"numLock":false}`

	t.Run("without --json the payload is a tree", func(t *testing.T) {
		t.Setenv("SHIM_OUT", payload)
		res := runCall(t, []string{"keylock", "numlock"}, "keylock", "numlock")
		if want := "├── capsLock: yes\n└── numLock: no\n\n"; res.stdout != want {
			t.Fatalf("stdout = %q, want %q", res.stdout, want)
		}
	})

	t.Run("with --json the payload is passed through", func(t *testing.T) {
		t.Setenv("SHIM_OUT", payload)
		if _, err := runCLI(t, "keylock", "numlock", "--json"); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		res, err := runCLI(t, "--json", "keylock", "numlock")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if want := payload + "\n"; res.stdout != want {
			t.Fatalf("stdout = %q, want %q", res.stdout, want)
		}
	})
}

// TestIPCFailureReachesUser pins that a rejected call is reported and
// that nothing is printed as if it had succeeded. A script driving
// vastctl turns on the exit status, and a swallowed error makes a
// failed brightness change look like it worked.
func TestIPCFailureReachesUser(t *testing.T) {
	t.Setenv("SHIM_CODE", "255")
	t.Setenv("SHIM_OUT", "No running instances for \"/cfg/Qml/shell.qml\"\n")

	res, err := runCLI(t, "wallpaper", "get")

	wantError(t, err, "img", "get", "No running instances")
	if strings.TrimSpace(res.output()) != "" {
		t.Fatalf("a failed call printed %q as if it had succeeded", res.output())
	}
}
