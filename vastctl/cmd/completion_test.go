package cmd

import (
	"strings"
	"testing"
)

// TestCompletionSnippets pins that each supported shell gets a real
// script. These snippets are what the Nix package installs into the
// shell's completion directory, so one that comes back empty installs
// a completion that silently does nothing on the user's next login.
//
// carapace's snippets are runtime dispatchers rather than embedded
// command tables: each one calls `<program> _carapace <shell>` and asks
// the running binary. The program name is resolved at run time, so the
// fragments asserted here are the hand-off and the shell-specific
// scaffolding — those are what break when the wiring changes.
func TestCompletionSnippets(t *testing.T) {
	for _, tc := range []struct {
		shell string
		want  []string
	}{
		{"bash", []string{"_vastctl_completion", "_carapace bash"}},
		{"zsh", []string{"#compdef", "_carapace zsh"}},
		{"fish", []string{"complete", "_carapace fish"}},
		{"nushell", []string{"vastctl_completer", "_carapace nushell"}},
	} {
		t.Run(tc.shell, func(t *testing.T) {
			res, err := runCLI(t, "completion", tc.shell)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			// The snippet goes through cobra's writer, not stdout.
			snippet := res.cmdOut
			if len(strings.TrimSpace(snippet)) == 0 {
				t.Fatal("the snippet is empty")
			}
			for _, want := range tc.want {
				if !strings.Contains(snippet, want) {
					t.Errorf("the snippet does not mention %q", want)
				}
			}
		})
	}
}

// TestCompletionSnippetsAreDistinct pins that the four shells do not
// all get the same script. A generator that ignored its argument would
// hand the nushell user a bash snippet that fails to source, and the
// only visible symptom is a broken prompt.
func TestCompletionSnippetsAreDistinct(t *testing.T) {
	seen := make(map[string]string)
	for _, shell := range []string{"bash", "zsh", "fish", "nushell"} {
		res, err := runCLI(t, "completion", shell)
		if err != nil {
			t.Fatalf("%s: unexpected error: %v", shell, err)
		}
		if other, dup := seen[res.cmdOut]; dup {
			t.Fatalf("%s and %s produced the same script", shell, other)
		}
		seen[res.cmdOut] = shell
	}
}

// TestCarapaceDispatcherKnowsTheCommandTree pins the other half of the
// hand-off: the snippet is only a caller, so the command table has to
// come from `vastctl _carapace <shell>`, the hidden subcommand it
// invokes. A rename that missed this path would leave the completion
// offering a verb that no longer exists.
func TestCarapaceDispatcherKnowsTheCommandTree(t *testing.T) {
	res, err := runCLI(t, "_carapace", "bash", "vastctl", "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	for _, want := range []string{"wallpaper", "brightness", "dragAndDrop", "hypr", "toast"} {
		if !strings.Contains(res.cmdOut, want) {
			t.Errorf("the completion does not offer the %q command", want)
		}
	}
}

// TestCompletionUnknownShellIsRejected pins that a shell vastctl does
// not generate for is an error naming the four it does. Answering with
// the help text and a zero exit status instead — what cobra does for a
// group command with no RunE — lets a user redirect that help into a
// shell rc file and believe they installed completions.
func TestCompletionUnknownShellIsRejected(t *testing.T) {
	_, err := runCLI(t, "completion", "notashell")

	wantError(t, err, "unknown shell", "notashell")
	for _, shell := range completionShells {
		if !strings.Contains(err.Error(), shell) {
			t.Errorf("the error does not list the supported shell %q: %v", shell, err)
		}
	}
}

// TestCompletionWithoutAShellShowsHelp pins that the bare invocation
// still lists what can be asked for. That is an incomplete command
// rather than a wrong shell, so help is the right answer.
func TestCompletionWithoutAShellShowsHelp(t *testing.T) {
	res, err := runCLI(t, "completion")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	for _, shell := range completionShells {
		if !strings.Contains(res.cmdOut, shell) {
			t.Errorf("the help does not mention %q: %q", shell, res.cmdOut)
		}
	}
}

// TestCompletionTakesNoArguments pins that a stray argument is
// rejected instead of being ignored.
func TestCompletionTakesNoArguments(t *testing.T) {
	if _, err := runCLI(t, "completion", "bash", "extra"); err == nil {
		t.Fatal("an extra argument must be rejected")
	}
}
