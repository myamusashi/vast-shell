package cmd

import "testing"

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

func TestCaptureAlias(t *testing.T) {
	for _, name := range []string{"capture", "captureScreenImage"} {
		t.Run(name, func(t *testing.T) {
			runCall(t, []string{"captureScreenImage", "screen", "copy"}, name, "screen")
		})
	}
}

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
