package cmd

import (
	"errors"
	"testing"

	"github.com/carapace-sh/carapace"
)

// TestEmptyOnErr pins the guard the completion callbacks use. They run
// inside the user's shell, where a failed quickshell or hyprctl call
// must degrade to "no suggestions" rather than print an error into the
// completion list; returning the wrong way round turns a missing
// completion into a broken prompt.
func TestEmptyOnErr(t *testing.T) {
	t.Parallel()
	if emptyOnErr(nil) {
		t.Error("emptyOnErr(nil) = true, want false")
	}
	if !emptyOnErr(errors.New("boom")) {
		t.Error("emptyOnErr(err) = false, want true")
	}
}

func TestCarapace(t *testing.T) {
	carapace.Test(t)
}
