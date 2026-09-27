package cmd

import (
	"errors"
	"io"
	"slices"
	"strings"
	"testing"

	"github.com/spf13/cobra"
)

// TestParsePercent pins the percent grammar. Two things depend on
// getting it exactly right: a leading '-' has to mean "adjust
// relatively" rather than a flag (the commands that take a percent
// therefore disable flag parsing), and the IPC payload is the signed
// integer, not the original text. A parser that let "120" through
// would hand the shell a volume of 120%.
func TestParsePercent(t *testing.T) {
	t.Parallel()
	for _, tc := range []struct {
		in        string
		wantValue int
		wantRel   bool
	}{
		{"50", 50, false},
		{"50%", 50, false},
		{"0", 0, false},
		{"0%", 0, false},
		{"100", 100, false},
		{"100%", 100, false},
		{"7", 7, false},
		{"007", 7, false},

		{"+10", 10, true},
		{"+10%", 10, true},
		{"-10", -10, true},
		{"-10%", -10, true},
		{"+0", 0, true},
		{"-0", 0, true},
		{"+100%", 100, true},
		{"-100%", -100, true},

		// A relative +/-0 is still a relative adjustment, not an
		// absolute set. The shell distinguishes the two methods, so
		// collapsing them here would change which method is called.
		{"+0%", 0, true},
		{"-0%", 0, true},
	} {
		t.Run(tc.in, func(t *testing.T) {
			t.Parallel()
			got, err := parsePercent(tc.in)
			if err != nil {
				t.Fatalf("parsePercent(%q) returned an unexpected error: %v", tc.in, err)
			}
			if got.value != tc.wantValue || got.relative != tc.wantRel {
				t.Fatalf("parsePercent(%q) = %+v, want {value:%d relative:%t}",
					tc.in, got, tc.wantValue, tc.wantRel)
			}
		})
	}
}

// TestParsePercentRejects pins the inputs that must not reach the
// shell. Silence here is the failure mode worth guarding: a zero
// volume is a wrong volume, and the shell has no way to tell an
// unparsed argument from a deliberate one.
func TestParsePercentRejects(t *testing.T) {
	t.Parallel()
	for _, tc := range []struct {
		name string
		in   string
		// want, when set, is a fragment the error must mention.
		want string
	}{
		{"empty", "", "invalid percent"},
		{"only a percent sign", "%", "invalid percent"},
		{"only a plus", "+", "invalid percent"},
		{"only a minus", "-", "invalid percent"},
		{"plus then percent", "+%", "invalid percent"},
		{"minus then percent", "-%", "invalid percent"},
		{"above the range", "101", "must be 0-100"},
		{"below the range on a relative value", "-101", "must be 0-100"},
		{"far above the range", "1000", "must be 0-100"},
		{"not a number", "abc", "must be 0-100"},
		{"a fraction", "5.5", "must be 0-100"},
		{"leading space", " 50", "must be 0-100"},
		{"trailing space", "50 ", "must be 0-100"},
		{"a space before the percent sign", "50 %", "must be 0-100"},
		{"an underscore separator", "1_0", "must be 0-100"},
		{"a sign inside the body", "5-0", "must be 0-100"},
		{"a percent in the middle", "5%0", "must be 0-100"},
		{"unicode digits", "٥٠", "must be 0-100"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			got, err := parsePercent(tc.in)
			if err == nil {
				t.Fatalf("parsePercent(%q) = %+v, want an error", tc.in, got)
			}
			if !strings.Contains(err.Error(), tc.want) {
				t.Errorf("error %q does not mention %q", err, tc.want)
			}
			if !strings.Contains(err.Error(), tc.in) {
				t.Errorf("error %q does not name the offending input %q", err, tc.in)
			}
		})
	}
}

// TestRawPositional pins the hand-rolled argument handling that stands
// in for flag parsing. The commands using it disable flag parsing so
// "-10%" reaches the percent parser instead of being eaten as a flag,
// which means this function is also the only place `--json` and `-h`
// are still honoured.
func TestRawPositional(t *testing.T) {
	t.Parallel()
	for _, tc := range []struct {
		name    string
		args    []string
		want    []string
		handled bool
		wantErr string
	}{
		{name: "a lone value", args: []string{"50%"}, want: []string{"50%"}},
		{name: "a relative value", args: []string{"-10%"}, want: []string{"-10%"}},
		{name: "the json flag is dropped", args: []string{"--json", "50%"}, want: []string{"50%"}},
		{name: "the json flag may trail", args: []string{"50%", "--json"}, want: []string{"50%"}},
		{name: "the end-of-flags marker is dropped", args: []string{"--", "-10%"}, want: []string{"-10%"}},
		{name: "markers may combine", args: []string{"--json", "--", "-10%"}, want: []string{"-10%"}},

		// Help is not an error: the command has already printed its
		// usage and the caller must not then complain about the arg
		// count, which would bury the help under a second message.
		{name: "short help is handled", args: []string{"-h"}, handled: true},
		{name: "long help is handled", args: []string{"--help"}, handled: true},
		{name: "help wins over a value", args: []string{"50%", "-h"}, handled: true},

		{name: "no argument", args: nil, wantErr: "accepts 1 arg, received 0"},
		{name: "only the json flag", args: []string{"--json"}, wantErr: "accepts 1 arg, received 0"},
		{name: "only the end-of-flags marker", args: []string{"--"}, wantErr: "accepts 1 arg, received 0"},
		{name: "too many arguments", args: []string{"50", "60"}, wantErr: "accepts 1 arg, received 2"},
		{name: "a flag-looking second argument is still a positional", args: []string{"50", "-x"}, wantErr: "accepts 1 arg, received 2"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			c := &cobra.Command{Use: "set"}
			c.SetOut(io.Discard)
			c.SetErr(io.Discard)

			got, handled, err := rawPositional(c, tc.args, 1)
			if tc.wantErr != "" {
				if err == nil {
					t.Fatalf("rawPositional(%q) = %q, want an error", tc.args, got)
				}
				if err.Error() != tc.wantErr {
					t.Fatalf("error = %q, want %q", err, tc.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatalf("rawPositional(%q) returned an unexpected error: %v", tc.args, err)
			}
			if handled != tc.handled {
				t.Fatalf("handled = %t, want %t", handled, tc.handled)
			}
			if !tc.handled && !slices.Equal(got, tc.want) {
				t.Fatalf("rawPositional(%q) = %q, want %q", tc.args, got, tc.want)
			}
		})
	}
}

// TestActionOrDefault pins the optional-action default. The capture
// commands send "copy" when the user gives no action, and an empty
// action reaching the shell instead would ask it to do nothing while
// reporting success.
func TestActionOrDefault(t *testing.T) {
	t.Parallel()
	for _, tc := range []struct {
		args    []string
		def     string
		want    string
		wantErr bool
	}{
		{args: nil, def: "copy", want: "copy"},
		{args: []string{}, def: "copy", want: "copy"},
		{args: []string{"save"}, def: "copy", want: "save"},
		{args: []string{"save+copy"}, def: "copy", want: "save+copy"},
		{args: []string{"save", "ignored"}, def: "copy", want: "save"},
		// An explicitly empty argument is not an omission: it is the
		// user asking for the empty action, and the default must not
		// silently replace it.
		{args: []string{""}, def: "copy", want: ""},
	} {
		if got := actionOrDefault(tc.args, tc.def); got != tc.want {
			t.Errorf("actionOrDefault(%q, %q) = %q, want %q", tc.args, tc.def, got, tc.want)
		}
	}
}

// TestPercentSetCmd pins the command factory. The relative/absolute
// split is the whole reason this factory exists, and getting it
// backwards turns `volume system set +10%` into an absolute set to
// 10% — the opposite of what was asked.
func TestPercentSetCmd(t *testing.T) {
	t.Parallel()
	for _, tc := range []struct {
		name       string
		args       []string
		wantValue  int
		wantRel    bool
		wantSilent bool
		wantErr    string
	}{
		{name: "absolute", args: []string{"50%"}, wantValue: 50},
		{name: "absolute without the sign", args: []string{"50"}, wantValue: 50},
		{name: "relative up", args: []string{"+10%"}, wantValue: 10, wantRel: true},
		{name: "relative down", args: []string{"-10%"}, wantValue: -10, wantRel: true},
		{name: "the json flag is stripped", args: []string{"--json", "50%"}, wantValue: 50},
		{name: "help prints usage instead of parsing", args: []string{"-h"}, wantSilent: true},
		{name: "out of range", args: []string{"101"}, wantErr: "must be 0-100"},
		{name: "missing argument", args: nil, wantErr: "accepts 1 arg, received 0"},
		{name: "extra argument", args: []string{"10", "20"}, wantErr: "accepts 1 arg, received 2"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			var seen percentArg
			called := false
			c := percentSetCmd("set [+|-]<percent>[%]", "short", "long",
				func(_ *cobra.Command, pct percentArg) error {
					called = true
					seen = pct
					return nil
				})
			c.SetOut(io.Discard)
			c.SetErr(io.Discard)
			// A nil args would make cobra fall back to the test
			// binary's own os.Args, which is not what the case means.
			args := tc.args
			if args == nil {
				args = []string{}
			}
			c.SetArgs(args)

			err := c.Execute()
			if tc.wantErr != "" {
				if err == nil || !strings.Contains(err.Error(), tc.wantErr) {
					t.Fatalf("error = %v, want one mentioning %q", err, tc.wantErr)
				}
				if called {
					t.Error("the callback ran despite a bad argument")
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if tc.wantSilent {
				if called {
					t.Error("the callback ran for a help request")
				}
				return
			}
			if !called {
				t.Fatal("the callback never ran")
			}
			if seen.value != tc.wantValue || seen.relative != tc.wantRel {
				t.Fatalf("callback got %+v, want {value:%d relative:%t}", seen, tc.wantValue, tc.wantRel)
			}
		})
	}
}

// TestPercentSetCmdPropagatesCallbackError pins that a failure from
// the callback reaches the caller. Swallowing it would make a failed
// IPC call exit 0, and a script driving vastctl would never learn that
// the volume did not change.
func TestPercentSetCmdPropagatesCallbackError(t *testing.T) {
	t.Parallel()

	sentinel := errors.New("shell said no")
	c := percentSetCmd("set", "short", "long",
		func(_ *cobra.Command, _ percentArg) error { return sentinel })
	c.SetOut(io.Discard)
	c.SetErr(io.Discard)
	c.SetArgs([]string{"50"})

	if err := c.Execute(); !errors.Is(err, sentinel) {
		t.Fatalf("error = %v, want %v", err, sentinel)
	}
}

// TestPercentSetCmdDisablesFlagParsing pins the property the factory
// exists for. With flag parsing left on, "-10%" is parsed as the flag
// -1 followed by junk and the command never reaches the percent
// parser at all.
func TestPercentSetCmdDisablesFlagParsing(t *testing.T) {
	t.Parallel()
	c := percentSetCmd("set", "short", "long", func(_ *cobra.Command, _ percentArg) error { return nil })
	if !c.DisableFlagParsing {
		t.Fatal("DisableFlagParsing must be set, otherwise a leading - is read as a flag")
	}
}
