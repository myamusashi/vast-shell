package cmd

import (
	"slices"
	"strings"
	"testing"
)

// The carapace callbacks in carapace.go are not just plumbing: each one
// picks a field out of a shell payload, and a wrong field name silently
// completes to something the user then passes to a mutating command.
// These tests drive them through the `_carapace` bridge the generated
// shell snippet actually calls, so what is asserted is the value list a
// user sees on Tab.
//
// A completion reply is "<matched>\x01<value>[\n<value>...]"; the
// leading bool is carapace's own "did anything match" flag and is not
// this code's business.

// completions runs the bridge for the given partial command line and
// returns the offered values, or nil when nothing is offered.
func completions(t *testing.T, line string, args ...string) []string {
	t.Helper()
	t.Setenv("CARAPACE_COMPLINE", "vastctl "+line)
	res, err := runCLI(t, append([]string{"_carapace", "bash", "vastctl"}, args...)...)
	if err != nil {
		t.Fatalf("%s: unexpected error: %v", line, err)
	}
	_, values, found := strings.Cut(res.cmdOut, "\x01")
	if !found {
		return nil
	}
	var out []string
	for _, v := range strings.Split(values, "\n") {
		if v != "" {
			out = append(out, v)
		}
	}
	return out
}

func wantCompletions(t *testing.T, want []string, line string, args ...string) {
	t.Helper()
	got := completions(t, line, args...)
	slices.Sort(got)
	slices.Sort(want)
	if !slices.Equal(got, want) {
		t.Fatalf("%q offered %q, want %q", line, got, want)
	}
}

// TestVolumeAppCompletionOffersStreamIDs pins that the node id comes
// from the payload's id field. Completing to the app name instead would
// hand `volume app set` an argument the shell cannot resolve.
func TestVolumeAppCompletionOffersStreamIDs(t *testing.T) {
	recordShell(t)
	t.Setenv("SHIM_OUT", `[{"id":42,"name":"node-a","appName":"Firefox","mediaName":"Song T"},
	 {"id":7,"name":"node-b","appName":"","mediaName":""}]`)

	wantCompletions(t, []string{"42", "7"},
		"volume app set ", "volume", "app", "set", "")
}

// TestVolumeAppCompletionSecondArgOffersPercents pins that the node id
// and the percent are completed independently. Offering stream ids in
// the percent slot would make every relative adjustment invalid.
func TestVolumeAppCompletionSecondArgOffersPercents(t *testing.T) {
	recordShell(t)

	wantCompletions(t, percentValues,
		"volume app set 42 ", "volume", "app", "set", "42", "")
}

// TestClipboardRemoveCompletionPrefersEntryID pins the fallback. The
// payload carries both entryId and id, and they are not the same value:
// entryId identifies the history entry, id the clipboard record.
// Removing needs the entry, and preferring the wrong one deletes the
// wrong thing.
func TestClipboardRemoveCompletionPrefersEntryID(t *testing.T) {
	recordShell(t)
	t.Setenv("SHIM_OUT", `[{"entryId":0,"id":900,"preview":"hello","type":"text"},
	 {"entryId":12,"id":13,"preview":"","type":""}]`)

	// The first entry has entryId 0 and must fall back to id 900; the
	// second has both set and must use 12, not 13.
	wantCompletions(t, []string{"900", "12"},
		"clipboard remove ", "clipboard", "remove", "")
}

// TestAudioCompletionOffersNames pins that profiles and devices are
// completed from the name field, which is what the setters forward.
// The names deliberately share no prefix: when every match starts the
// same way carapace offers the common prefix instead of the list, which
// is correct behaviour but would hide which values are on offer.
func TestAudioCompletionOffersNames(t *testing.T) {
	t.Run("profiles", func(t *testing.T) {
		recordShell(t)
		t.Setenv("SHIM_OUT", `{"profiles":[{"name":"flat","description":"Flat"},{"name":"hsp","description":"HSP"}]}`)

		wantCompletions(t, []string{"flat", "hsp"},
			"audio profile set ", "audio", "profile", "set", "")
	})

	t.Run("devices", func(t *testing.T) {
		recordShell(t)
		t.Setenv("SHIM_OUT", `[{"name":"sink-builtin","description":"Speakers"},{"name":"usb-dock","description":"Dock"}]`)

		wantCompletions(t, []string{"sink-builtin", "usb-dock"},
			"audio device set ", "audio", "device", "set", "")
	})
}

// TestHyprDispatchCompletionOffersShortcuts pins that dispatch
// completes to the bare shortcut name. Hyprland's own binds are filtered
// out and the quickshell: prefix trimmed, so the value offered is
// exactly what `hypr dispatch` takes back.
func TestHyprDispatchCompletionOffersShortcuts(t *testing.T) {
	newHyprLog(t)
	t.Setenv("SHIM_HYPR_OUT", `[{"name":"quickshell:bar","description":"toggle"},
	 {"name":"special:workspace,1","description":"hyprland's own bind"}]`)

	wantCompletions(t, []string{"bar"},
		"hypr dispatch ", "hypr", "dispatch", "")
}

// TestColorFlagCompletions pins the static flag values. The mode and
// scheme go to the shell as positional arguments, so a scheme that is
// not in the list is one the shell rejects after the image has already
// been read.
func TestColorFlagCompletions(t *testing.T) {
	recordShell(t)

	for _, mode := range []string{"dark", "light"} {
		got := completions(t, "color generate --mode ", "color", "generate", "--mode", "")
		if !slices.Contains(got, mode) {
			t.Errorf("--mode does not offer %q, got %q", mode, got)
		}
	}

	for _, scheme := range colorSchemes {
		got := completions(t, "color generate --scheme ", "color", "generate", "--scheme", "")
		if !slices.Contains(got, scheme) {
			t.Errorf("--scheme does not offer %q, got %q", scheme, got)
		}
	}
}

// TestCompletionDegradesOnBadPayload pins that a failed or unparseable
// shell answer offers nothing rather than a half-built list. The
// callbacks run inside the user's prompt, where a stray value turns
// into a command argument the moment Tab is pressed again.
func TestCompletionDegradesOnBadPayload(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		out  string
		code string
	}{
		{"the shell call fails", []string{"clipboard", "remove", ""}, "", "255"},
		{"the shell call returns junk", []string{"audio", "device", "set", ""}, "not json at all", ""},
		{"the list is empty", []string{"volume", "app", "set", ""}, "[]", ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			recordShell(t)
			t.Setenv("SHIM_OUT", tc.out)
			t.Setenv("SHIM_CODE", tc.code)

			if got := completions(t, strings.Join(tc.args, " "), tc.args...); len(got) != 0 {
				t.Fatalf("offered %q, want nothing", got)
			}
		})
	}
}
