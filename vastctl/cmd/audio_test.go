package cmd

import (
	"testing"
)

// TestAudio pins the four audio commands' target/method pairs.
func TestAudio(t *testing.T) {
	t.Setenv("SHIM_OUT", `[{"name":"profile-a","description":"flat"}]`)

	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"profile list", []string{"audio", "profile", "list"}, []string{"audio", "profileList"}},
		{"profile set", []string{"audio", "profile", "set", "profile-a"}, []string{"audio", "profileSet", "profile-a"}},
		{"device list", []string{"audio", "device", "list"}, []string{"audio", "deviceList"}},
		{"device set", []string{"audio", "device", "set", "sink-a"}, []string{"audio", "deviceSet", "sink-a"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

// TestAudioProfileSetRequiresName pins that a missing profile is
// rejected. EmptyArgs would otherwise reach the shell and clear the
// active profile, which the user reads as a mute.
func TestAudioProfileSetRequiresName(t *testing.T) {
	t.Run("profile set", func(t *testing.T) {
		if _, err := runCLI(t, "audio", "profile", "set"); err == nil {
			t.Fatal("a missing profile name must be rejected")
		}
	})
	t.Run("device set", func(t *testing.T) {
		if _, err := runCLI(t, "audio", "device", "set"); err == nil {
			t.Fatal("a missing device name must be rejected")
		}
	})
}
