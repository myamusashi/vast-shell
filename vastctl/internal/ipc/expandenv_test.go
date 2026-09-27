package ipc

import "testing"

// TestExpandEnv pins every supported reference form and the two
// decisions that are easy to get wrong: an unknown variable expands to
// nothing rather than to its own name, and a `$` that starts no
// reference is emitted literally. This runs on a value that becomes a
// quickshell config path, where a variable left unexpanded is a path
// that does not exist.
func TestExpandEnv(t *testing.T) {
	t.Setenv("VAST_TEST_NAME", "vast-shell")
	t.Setenv("VAST_TEST_EMPTY", "")
	t.Setenv("VAST_TEST_PATH", "/opt/vast/Qml")
	t.Setenv("VAST_TEST_V2", "v2")

	for _, tc := range []struct {
		name string
		in   string
		want string
	}{
		{"a path with no reference is returned unchanged", "/opt/vast/Qml", "/opt/vast/Qml"},
		{"an empty string stays empty", "", ""},

		{"$VAR", "$VAST_TEST_NAME", "vast-shell"},
		{"${VAR}", "${VAST_TEST_NAME}", "vast-shell"},
		{"$env.VAR", "$env.VAST_TEST_NAME", "vast-shell"},

		{"text around a reference", "root=$VAST_TEST_NAME:sub", "root=vast-shell:sub"},
		{"two references in a row", "$VAST_TEST_NAME/$VAST_TEST_NAME", "vast-shell/vast-shell"},
		{"a digit is part of the variable name", "$VAST_TEST_V2", "v2"},
		{"a trailing digit is swallowed into the name, not appended to the value", "$VAST_TEST_NAME2", ""},
		{"an unset variable expands to nothing", "[$VAST_TEST_ABSENT]", "[]"},
		{"a variable set to empty expands to nothing", "[$VAST_TEST_EMPTY]", "[]"},
		{"an unset braced variable expands to nothing", "[${VAST_TEST_ABSENT}]", "[]"},
		{"an unset $env variable expands to nothing", "[$env.VAST_TEST_ABSENT]", "[]"},

		// The name is read greedily but only over identifier bytes, so
		// the dot ends it and the rest of the string is literal.
		{"a dot ends the variable name", "$env.VAST_TEST_NAME.Qml", "vast-shell.Qml"},
		{"a slash ends the variable name", "$VAST_TEST_NAME/Qml", "vast-shell/Qml"},
		{"a dash ends the variable name", "$VAST_TEST_NAME-2", "vast-shell-2"},

		{"underscores and digits are name characters", "${VAST_TEST_NAME}_2", "vast-shell_2"},

		// A bare `$` is ordinary text. Emitting it verbatim keeps
		// passwords and shell snippets intact instead of eating the
		// character that follows. The scan resumes after it, so a name
		// spelled out in the remaining text is left alone — only a `$`
		// is a reference.
		{"a trailing dollar is literal", "cost$", "cost$"},
		{"a dollar before punctuation is literal", "100$", "100$"},
		{"a dollar before a space is literal", "$ VAST_TEST_NAME", "$ VAST_TEST_NAME"},
		{"a doubled dollar does not collapse", "$$VAST_TEST_NAME", "$vast-shell"},
		{"an unterminated brace is literal", "${VAST_TEST_NAME", "${VAST_TEST_NAME"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if got := ExpandEnv(tc.in); got != tc.want {
				t.Errorf("ExpandEnv(%q) = %q, want %q", tc.in, got, tc.want)
			}
		})
	}
}

// TestExpandEnvIdentBoundary pins where a variable name stops. The
// characters below are the ones that must NOT be swallowed into a
// variable name, because `$VAR-suffix` has to expand to `value-suffix`
// and not look up a variable called `VAR-suffix`.
func TestExpandEnvIdentBoundary(t *testing.T) {
	t.Setenv("VAST_TEST_V", "v")

	for _, tc := range []struct {
		name string
		in   string
		want string
	}{
		{"space", "$VAST_TEST_V x", "v x"},
		{"dot", "$VAST_TEST_V.x", "v.x"},
		{"slash", "$VAST_TEST_V/x", "v/x"},
		{"hyphen", "$VAST_TEST_V-x", "v-x"},
		{"colon", "$VAST_TEST_V:x", "v:x"},
		{"closing brace", "${VAST_TEST_V}", "v"},
		{"immediately closing brace", "${VAST_TEST_V}x", "vx"},
		// The braced form runs to the FIRST closing brace and the text
		// in between is the name, verbatim and unexpanded. Nested
		// references are therefore not supported, and this pins that
		// rather than leaving it undefined.
		{"a braced name is not a nested reference", "${VAST_TEST_V${VAST_TEST_V}", ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if got := ExpandEnv(tc.in); got != tc.want {
				t.Errorf("ExpandEnv(%q) = %q, want %q", tc.in, got, tc.want)
			}
		})
	}
}
