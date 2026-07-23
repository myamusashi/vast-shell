package pretty

import (
	"testing"
)

func TestTreeMpris(t *testing.T) {
	raw := `[{"identity":"spotify","trackTitle":"Dreams","trackArtist":"Fleetwood Mac","playbackStatus":"Playing","volume":0.8},
 {"identity":"firefox","trackTitle":"YouTube","trackArtist":"","playbackStatus":"Paused","volume":0.5}]`
	out, err := Tree(raw)
	if err != nil {
		t.Fatal(err)
	}
	t.Log("\n" + out)
}

func TestTreeShortcuts(t *testing.T) {
	raw := `[{"name":"bar"},{"name":"launcher","description":"quick launcher"},{"name":"settings"}]`
	out, err := Tree(raw)
	if err != nil {
		t.Fatal(err)
	}
	t.Log("\n" + out)
}

func TestTreeBrightness(t *testing.T) {
	raw := `[{"id":"DP-1","name":"DEL DELL","brightness":75,"isInternal":false},
 {"id":"intel_backlight","name":"Internal: intel","brightness":80,"isInternal":true}]`
	out, err := Tree(raw)
	if err != nil {
		t.Fatal(err)
	}
	t.Log("\n" + out)
}

func TestTreeSingleObject(t *testing.T) {
	raw := `{"hello": "world"}`
	_, err := Tree(raw)
	if err == nil {
		t.Fatal("expected error for non-array input")
	}
}

func TestTreeEmpty(t *testing.T) {
	raw := `[]`
	out, err := Tree(raw)
	if err != nil {
		t.Fatal(err)
	}
	if out != "(empty)" {
		t.Fatalf("expected (empty), got %q", out)
	}
}
