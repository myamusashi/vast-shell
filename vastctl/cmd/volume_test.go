package cmd

import (
	"testing"
)

// TestVolumeSystemSet pins the absolute/relative split. The two go to
// different shell methods, so a sign that reaches the wrong branch
// turns `volume system set +10%` into setting the volume to 10% —
// quieter, and the opposite of what was asked.
func TestVolumeSystemSet(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"absolute with a percent sign", []string{"50%"}, []string{"volume", "systemSet", "50"}},
		{"absolute without a percent sign", []string{"50"}, []string{"volume", "systemSet", "50"}},
		{"zero", []string{"0%"}, []string{"volume", "systemSet", "0"}},
		{"full", []string{"100%"}, []string{"volume", "systemSet", "100"}},
		{"relative up", []string{"+10%"}, []string{"volume", "systemChange", "10"}},
		{"relative down", []string{"-10%"}, []string{"volume", "systemChange", "-10"}},
		{"relative down is not parsed as a flag", []string{"--", "-10%"}, []string{"volume", "systemChange", "-10"}},
		{"the json flag is still accepted", []string{"--json", "50%"}, []string{"volume", "systemSet", "50"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, append([]string{"volume", "system", "set"}, tc.args...)...)
		})
	}
}

// TestVolumeSystemSetRejects pins the bounds. The shell would happily
// set 150% if asked, and the user hears nothing wrong until they
// adjust the volume again.
func TestVolumeSystemSetRejects(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
	}{
		{"above the range", []string{"101"}},
		{"far above the range", []string{"1000"}},
		{"not a number", []string{"loud"}},
		{"no argument", nil},
		{"two arguments", []string{"10", "20"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			recordShell(t)
			if _, err := runCLI(t, append([]string{"volume", "system", "set"}, tc.args...)...); err == nil {
				t.Fatal("an out-of-range percent must be rejected")
			}
		})
	}
}

// TestVolumeSystemMutations pins the mute verbs, each of which is a
// separate method rather than a shared one with a flag.
func TestVolumeSystemMutations(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"get", []string{"volume", "system", "get"}, []string{"volume", "systemGet"}},
		{"mute", []string{"volume", "system", "mute"}, []string{"volume", "systemMute"}},
		{"unmute", []string{"volume", "system", "unmute"}, []string{"volume", "systemUnmute"}},
		{"toggle-mute", []string{"volume", "system", "toggle-mute"}, []string{"volume", "systemToggleMute"}},
		{"app list", []string{"volume", "app", "list"}, []string{"volume", "appList"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

// TestVolumeAppSet pins that the node id is forwarded ahead of the
// percent. The two are positional, and swapping them would set a
// volume on a node that does not exist while ignoring the one that
// does.
func TestVolumeAppSet(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"absolute", []string{"42", "50%"}, []string{"volume", "appSet", "42", "50"}},
		{"relative up", []string{"42", "+10%"}, []string{"volume", "appChange", "42", "10"}},
		// The relative-down form is the reason this command disables
		// flag parsing. With parsing on, pflag reads the leading '-'
		// of "-10%" as a flag and the percent never reaches the parser,
		// so a command that advertises the form in its usage string and
		// its completion has to actually accept it.
		{"relative down", []string{"42", "-10%"}, []string{"volume", "appChange", "42", "-10"}},
		{"the end-of-flags marker is dropped", []string{"42", "--", "-10%"}, []string{"volume", "appChange", "42", "-10"}},
		{"a large node id is not truncated", []string{"4294967295", "50%"}, []string{"volume", "appSet", "4294967295", "50"}},
		{"a percent is not required", []string{"42", "50"}, []string{"volume", "appSet", "42", "50"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, append([]string{"volume", "app", "set"}, tc.args...)...)
		})
	}
}

// TestVolumeAppSetDoesNotParseTheNodeID pins that only the second
// positional is read as a percent. A node id is forwarded verbatim, so
// a leading '-' there is a malformed id rather than a sign.
func TestVolumeAppSetDoesNotParseTheNodeID(t *testing.T) {
	runCall(t, []string{"volume", "appSet", "-7", "50"}, "volume", "app", "set", "--", "-7", "50")
}

// TestVolumeAppSetValidatesPercent pins that the percent is checked
// before the shell is called. Validating first is what keeps a typo
// from setting a stream to a nonsensical level.
func TestVolumeAppSetValidatesPercent(t *testing.T) {
	log := recordShell(t)

	_, err := runCLI(t, "volume", "app", "set", "42", "150")
	wantError(t, err, "must be 0-100")
	if calls := shimInvocations(t, log); len(calls) != 0 {
		t.Fatalf("the shell was called with %q despite a bad percent", calls)
	}
}

// TestVolumeAppSetRequiresBothArguments pins the arity. A missing node
// id must not be sent as an empty one, which the shell would resolve
// to whatever node happens to be first.
func TestVolumeAppSetRequiresBothArguments(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
	}{
		{"no arguments", nil},
		{"node id only", []string{"42"}},
		{"three arguments", []string{"42", "50%", "extra"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			recordShell(t)
			if _, err := runCLI(t, append([]string{"volume", "app", "set"}, tc.args...)...); err == nil {
				t.Fatal("a bad argument count must be rejected")
			}
		})
	}
}

// TestVolumeAppMutations pins the per-app mute verbs.
func TestVolumeAppMutations(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"mute", []string{"volume", "app", "mute", "42"}, []string{"volume", "appMute", "42"}},
		{"unmute", []string{"volume", "app", "unmute", "42"}, []string{"volume", "appUnmute", "42"}},
		{"toggle-mute", []string{"volume", "app", "toggle-mute", "42"}, []string{"volume", "appToggleMute", "42"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

// TestVolumeAppMutationsRequireNode pins that an empty node id is
// rejected rather than forwarded. Muting "no node in particular" is
// not a thing the shell can do, and passing "" would hide that.
func TestVolumeAppMutationsRequireNode(t *testing.T) {
	for _, verb := range []string{"mute", "unmute", "toggle-mute"} {
		t.Run(verb, func(t *testing.T) {
			recordShell(t)
			if _, err := runCLI(t, "volume", "app", verb); err == nil {
				t.Fatal("a missing node id must be rejected")
			}
		})
	}
}

// TestVolumeAppSetPrintsNothingOnSuccess pins that a set stays quiet.
// A mutation that echoes a line makes the command unusable inside a
// keybinding that captures its output.
func TestVolumeAppSetPrintsNothingOnSuccess(t *testing.T) {
	res := runCall(t, []string{"volume", "appSet", "42", "50"}, "volume", "app", "set", "42", "50%")
	if res.output() != "" {
		t.Fatalf("a void call printed %q", res.output())
	}
}
