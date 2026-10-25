package cmd

import "testing"

func TestMpris(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"play-pause", []string{"mpris", "play-pause"}, []string{"mpris", "togglePlaying"}},
		{"next", []string{"mpris", "next"}, []string{"mpris", "next"}},
		{"previous", []string{"mpris", "previous"}, []string{"mpris", "previous"}},
		{"stop", []string{"mpris", "stop"}, []string{"mpris", "stop"}},
		{"list", []string{"mpris", "list"}, []string{"mpris", "list"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

func TestMprisListRendersPlayers(t *testing.T) {
	t.Setenv("SHIM_OUT", `[{"identity":"spotify","trackTitle":"Dreams","playbackStatus":"Playing"}]`)

	res := runCall(t, []string{"mpris", "list"}, "mpris", "list")

	want := "└── spotify\n    ├── identity: spotify\n    ├── playbackStatus: Playing\n    └── trackTitle: Dreams\n\n"
	if res.stdout != want {
		t.Fatalf("stdout = %q, want %q", res.stdout, want)
	}
}
