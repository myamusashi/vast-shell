package cmd

import "testing"

// TestCaptureActions pins the three capture surfaces and their default
// action. The default is the difference between a screenshot that
// lands on the clipboard and one that only lands in a file, so it
// cannot be left to whatever the shell does with an empty string.
func TestCaptureActions(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"screen defaults to copy", []string{"captureScreenImage", "screen"}, []string{"captureScreenImage", "screen", "copy"}},
		{"region defaults to copy", []string{"captureScreenImage", "region"}, []string{"captureScreenImage", "region", "copy"}},
		{"window defaults to copy", []string{"captureScreenImage", "window"}, []string{"captureScreenImage", "window", "copy"}},
		{"screen save", []string{"captureScreenImage", "screen", "save"}, []string{"captureScreenImage", "screen", "save"}},
		{"region save+copy", []string{"captureScreenImage", "region", "save+copy"}, []string{"captureScreenImage", "region", "save+copy"}},
		{"window copy", []string{"captureScreenImage", "window", "copy"}, []string{"captureScreenImage", "window", "copy"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, append([]string{"capture"}, tc.args[1:]...)...)
		})
	}
}

// TestCaptureAlias pins the `capture` alias, which is what the Short
// and the docs use. Without it the alias silently rots the moment the
// command is renamed.
func TestCaptureAlias(t *testing.T) {
	for _, name := range []string{"capture", "captureScreenImage"} {
		t.Run(name, func(t *testing.T) {
			runCall(t, []string{"captureScreenImage", "screen", "copy"}, name, "screen")
		})
	}
}

// TestCaptureRejectsExtraArgs pins the arity. The action is one of a
// fixed set and is forwarded as-is, so a second argument would become
// an argument the shell does not expect.
func TestCaptureRejectsExtraArgs(t *testing.T) {
	for _, sub := range []string{"screen", "region", "window"} {
		t.Run(sub, func(t *testing.T) {
			recordShell(t)
			if _, err := runCLI(t, "capture", sub, "save", "extra"); err == nil {
				t.Fatal("a second action must be rejected")
			}
		})
	}
}
