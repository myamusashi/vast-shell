package pretty

import (
	"strings"
	"testing"
)

// wantTree is the whole assertion: the tree rendering is the whole
// product here, so tests compare it verbatim rather than probing for
// substrings that would pass on a half-correct tree.
func wantTree(t *testing.T, raw, want string) {
	t.Helper()
	got, err := Tree(raw)
	if err != nil {
		t.Fatalf("Tree(%s) returned an unexpected error: %v", raw, err)
	}
	if got != want {
		t.Errorf("Tree(%s) =\n%s\nwant\n%s", raw, got, want)
	}
}

func wantTreeError(t *testing.T, raw string) {
	t.Helper()
	if got, err := Tree(raw); err == nil {
		t.Fatalf("Tree(%s) = %q, want an error", raw, got)
	}
}

// TestTreeEmptyInput covers every shape that means "nothing to show".
// They all have to collapse to the same marker: a caller printing an
// empty result is a caller printing a blank line otherwise.
func TestTreeEmptyInput(t *testing.T) {
	t.Parallel()
	for _, raw := range []string{"", "   ", "\n", "null", "[]", "{}", "  []  "} {
		wantTree(t, raw, "(empty)")
	}
}

// TestTreeScalars covers payloads that are already human-readable.
// Tree must pass them through untouched rather than wrapping a bare
// string in a tree node.
func TestTreeScalars(t *testing.T) {
	t.Parallel()
	for _, raw := range []string{"true", "false", "42", "0.8", `"/home/me/pic.png"`, "/home/me/pic.png"} {
		wantTree(t, raw, raw)
	}
}

// TestTreeArrayNesting pins the branch glyphs. A list of two items is
// the only shape where the first entry gets a tee and a vertical
// continuation bar, so a wrong pipe or connector shows up here.
func TestTreeArrayNesting(t *testing.T) {
	t.Parallel()
	raw := `[{"name":"spotify","trackTitle":"Dreams","volume":0.8},
 {"identity":"firefox","trackTitle":"","playbackStatus":"Paused"}]`
	wantTree(t, raw, strings.Join([]string{
		"├── spotify",
		"│   ├── name: spotify",
		"│   ├── trackTitle: Dreams",
		"│   └── volume: 0.8",
		"└── firefox",
		"    ├── identity: firefox",
		"    ├── playbackStatus: Paused",
		"    └── trackTitle: <empty>",
		"",
	}, "\n"))
}

// TestTreeSingleArrayItem pins that the only entry closes the list
// instead of dangling a branch and a pipe nobody continues.
func TestTreeSingleArrayItem(t *testing.T) {
	t.Parallel()
	wantTree(t, `[{"name":"bar","description":""}]`,
		"└── bar\n    ├── description: <empty>\n    └── name: bar\n")
}

// TestTreeUnlabelledEntry pins the fallback heading. A payload with
// none of the label keys still has to render one line per entry, or
// the count of entries silently disappears from the output.
func TestTreeUnlabelledEntry(t *testing.T) {
	t.Parallel()
	wantTree(t, `[{"brightness":75},{"brightness":80}]`,
		"├── (entry)\n│   └── brightness: 75\n└── (entry)\n    └── brightness: 80\n")
}

// TestTreeLabelPrecedence pins the order the label keys are tried in:
// name wins over identity, which wins over readable and description.
// A payload carrying several at once is exactly where a reordered
// lookup would still look plausible while picking the wrong heading.
func TestTreeLabelPrecedence(t *testing.T) {
	t.Parallel()
	for _, tc := range []struct{ name, raw, want string }{
		{
			name: "name wins",
			raw:  `[{"name":"n","identity":"i","readable":"r","description":"d"}]`,
			want: "└── n\n    ├── description: d\n    ├── identity: i\n    ├── name: n\n    └── readable: r\n",
		},
		{
			name: "identity wins over readable",
			raw:  `[{"identity":"i","readable":"r"}]`,
			want: "└── i\n    ├── identity: i\n    └── readable: r\n",
		},
		{
			name: "readable wins over description",
			raw:  `[{"readable":"r","description":"d"}]`,
			want: "└── r\n    ├── description: d\n    └── readable: r\n",
		},
		{
			name: "description is the last resort",
			raw:  `[{"description":"d"}]`,
			want: "└── d\n    └── description: d\n",
		},
		{
			// formatValue renders "" as <empty>, so the emptiness has to
			// be read off the raw value. Judging it off the rendered one
			// makes a nameless player print as "<empty>" and the
			// identity below it never gets a chance.
			name: "blank name falls through to identity",
			raw:  `[{"name":"","identity":"firefox"}]`,
			want: "└── firefox\n    ├── identity: firefox\n    └── name: <empty>\n",
		},
		{
			name: "blank name is not a label",
			raw:  `[{"name":""}]`,
			want: "└── (entry)\n    └── name: <empty>\n",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			wantTree(t, tc.raw, tc.want)
		})
	}
}

// TestTreeObject pins the top-level object rendering: fields are listed
// under the root, sorted, with no heading line of their own.
func TestTreeObject(t *testing.T) {
	t.Parallel()
	wantTree(t, `{"capsLock":true,"numLock":false,"level":3,"label":""}`,
		strings.Join([]string{
			"├── capsLock: yes",
			"├── label: <empty>",
			"├── level: 3",
			"└── numLock: no",
			"",
		}, "\n"))
}

func TestTreeEmptyObject(t *testing.T) {
	t.Parallel()
	wantTree(t, "{}", "(empty)")
}

// TestTreeValueFormatting pins each leaf rendering. The <nil>/<empty>
// placeholders and the yes/no booleans are what the shell has to grep
// for, so a silent change to any of them is a behaviour change for
// every caller.
func TestTreeValueFormatting(t *testing.T) {
	t.Parallel()
	for _, tc := range []struct{ name, raw, want string }{
		{"true is yes", `{"a":true}`, "└── a: yes\n"},
		{"false is no", `{"a":false}`, "└── a: no\n"},
		{"null is nil", `{"a":null}`, "└── a: <nil>\n"},
		{"empty string is empty", `{"a":""}`, "└── a: <empty>\n"},
		{"zero is kept", `{"a":0}`, "└── a: 0\n"},
		{"negative integer", `{"a":-3}`, "└── a: -3\n"},
		{"fraction", `{"a":0.5}`, "└── a: 0.5\n"},
		{"exponent folds to an integer", `{"a":1e3}`, "└── a: 1000\n"},
		{"exponent that overflows float64 is kept verbatim", `{"a":1e999}`, "└── a: 1e999\n"},
		{"string is unquoted", `{"a":"hello"}`, "└── a: hello\n"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			wantTree(t, tc.raw, tc.want)
		})
	}
}

// TestTreeNestedValues pins that a non-leaf value is pretty-printed as
// indented JSON rather than collapsed onto one line, and that it lines
// up under the value's own column. Without that, an entry containing an
// object renders its body further left than the field it belongs to.
//
// json.MarshalIndent already indents the body by two, so the body sits
// two columns right of the opening brace and the closing brace lines up
// with it.
func TestTreeNestedValues(t *testing.T) {
	t.Parallel()
	// Top level: the value starts at column 7, under "└── a: ".
	wantTree(t, `{"a":{"b":1}}`, "└── a: {\n         \"b\": 1\n       }\n")
	wantTree(t, `{"a":[1,2]}`, "└── a: [\n         1,\n         2\n       ]\n")
	// Inside an array entry: the value starts at column 11.
	wantTree(t, `[{"a":{"b":1}}]`, "└── (entry)\n    └── a: {\n             \"b\": 1\n           }\n")
	wantTree(t, `[{"a":{"b":{"c":2}}}]`,
		"└── (entry)\n    └── a: {\n             \"b\": {\n               \"c\": 2\n             }\n           }\n")
}

// TestTreeMalformedInput pins that unparseable JSON is reported
// instead of silently echoed. ipcCallPrint falls back to the raw
// string on error, so an error here is what keeps a broken payload
// visible rather than rendering as a plausible tree.
func TestTreeMalformedInput(t *testing.T) {
	t.Parallel()
	for _, raw := range []string{
		`[{"a":1},`,
		`[1,2,3]`,        // array of scalars, not objects
		`{"a":}`,         // truncated
		`{"a" 1}`,        // missing colon
		`[{"a":1}] junk`, // trailing garbage
	} {
		wantTreeError(t, raw)
	}
}

// TestTreePreservesInputOrder pins that a caller cannot steer the field
// order by reordering its JSON. Go map iteration is randomised, so this
// is a real hazard rather than a theoretical one.
func TestTreePreservesInputOrder(t *testing.T) {
	t.Parallel()
	for range 50 {
		wantTree(t, `{"z":1,"a":2,"m":3}`, "├── a: 2\n├── m: 3\n└── z: 1\n")
	}
}
