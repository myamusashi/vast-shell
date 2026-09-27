package cmd

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestColorGenerate pins the argument order. The shell reads them
// positionally as image, mode, scheme, so a reshuffle here is a
// palette generated from the wrong input.
func TestColorGenerate(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{
			name: "defaults",
			args: []string{"color", "generate", "/tmp/pic.png"},
			want: []string{"color", "generate", "/tmp/pic.png", "dark", "tonal-spot"},
		},
		{
			name: "explicit mode and scheme",
			args: []string{"color", "generate", "/tmp/pic.png", "--mode", "light", "--scheme", "vibrant"},
			want: []string{"color", "generate", "/tmp/pic.png", "light", "vibrant"},
		},
		{
			name: "a content scheme is forwarded verbatim",
			args: []string{"color", "generate", "/tmp/pic.png", "--scheme", "content"},
			want: []string{"color", "generate", "/tmp/pic.png", "dark", "content"},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

// TestColorFromHex pins the hash normalisation. The shell parses
// #RRGGBB, so forwarding a bare "ff0000" fails there and a
// double-hashed value would too.
func TestColorFromHex(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"without a hash", []string{"color", "from", "ff0000"}, []string{"color", "generateFromColor", "#ff0000", "dark", "tonal-spot"}},
		{"with a hash", []string{"color", "from", "#00ff00"}, []string{"color", "generateFromColor", "#00ff00", "dark", "tonal-spot"}},
		{"a three-digit shorthand is not expanded here", []string{"color", "from", "abc"}, []string{"color", "generateFromColor", "#abc", "dark", "tonal-spot"}},
		{"with a mode", []string{"color", "from", "ff0000", "--mode", "light"}, []string{"color", "generateFromColor", "#ff0000", "light", "tonal-spot"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

// TestColorOutFile pins the --out path. It is the documented way to
// feed a generated palette to a dotfile generator, so the file has to
// hold the exact payload and the notification has to name it.
func TestColorOutFile(t *testing.T) {
	t.Setenv("SHIM_OUT", `{"primary":"#6750a4"}`)
	out := filepath.Join(t.TempDir(), "palette.json")

	res := runCall(t,
		[]string{"color", "generateFromColor", "#ff0000", "dark", "tonal-spot"},
		"color", "from", "ff0000", "--out", out)

	if want := "wrote " + out + "\n"; res.cmdOut != want {
		t.Fatalf("notification = %q, want %q", res.cmdOut, want)
	}
	if strings.TrimSpace(res.stdout) != "" {
		t.Fatalf("the palette was also printed to stdout: %q", res.stdout)
	}
	data, err := os.ReadFile(out)
	if err != nil {
		t.Fatalf("read %s: %v", out, err)
	}
	if want := `{"primary":"#6750a4"}` + "\n"; string(data) != want {
		t.Fatalf("%s holds %q, want %q", out, data, want)
	}
}

// TestColorOutFileFailure pins that an unwritable destination is
// reported. Writing the palette to stdout anyway would look like it
// worked while the dotfile generator reads a file that was never
// created.
func TestColorOutFileFailure(t *testing.T) {
	t.Setenv("SHIM_OUT", `{"primary":"#6750a4"}`)
	out := filepath.Join(t.TempDir(), "absent", "palette.json")

	res, err := runCLI(t, "color", "from", "ff0000", "--out", out)

	wantError(t, err, "write", out)
	if strings.TrimSpace(res.output()) != "" {
		t.Fatalf("a failed write still printed %q", res.output())
	}
}

// TestColorFromRendersTree pins that a palette is readable as a tree
// by default. The role map is the point of the command, and printing
// one long JSON line makes it unreadable in a terminal.
func TestColorFromRendersTree(t *testing.T) {
	t.Setenv("SHIM_OUT", `{"primary":"#6750a4","onPrimary":"#ffffff"}`)

	res := runCall(t,
		[]string{"color", "generateFromColor", "#ff0000", "dark", "tonal-spot"},
		"color", "from", "ff0000")

	want := "├── onPrimary: #ffffff\n└── primary: #6750a4\n\n"
	if res.stdout != want {
		t.Fatalf("stdout = %q, want %q", res.stdout, want)
	}
}

// TestColorRequiresExactlyOneSource pins the arity of both
// subcommands.
func TestColorRequiresExactlyOneSource(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
	}{
		{"generate without a path", []string{"color", "generate"}},
		{"generate with two paths", []string{"color", "generate", "a.png", "b.png"}},
		{"from without a value", []string{"color", "from"}},
		{"from with two values", []string{"color", "from", "a", "b"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			recordShell(t)
			if _, err := runCLI(t, tc.args...); err == nil {
				t.Fatal("a bad argument count must be rejected")
			}
		})
	}
}
