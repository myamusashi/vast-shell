package templates

import (
	"testing"
)

// TestParseColor pins the accepted spellings. A palette may spell a
// color in any of them, and every one of them has to end up as the
// same color, or a template renders a different shade depending on
// how the palette was written.
func TestParseColor(t *testing.T) {
	for _, testCase := range []struct {
		name  string
		value string
		want  color
	}{
		{"six digits", "#dce0e8", color{Red: 0xdc, Green: 0xe0, Blue: 0xe8, Alpha: 1}},
		{"three digits", "#abc", color{Red: 0xaa, Green: 0xbb, Blue: 0xcc, Alpha: 1}},
		{"eight digits", "#dce0e880", color{Red: 0xdc, Green: 0xe0, Blue: 0xe8, Alpha: 0x80 / 255.0}},
		{"rgb", "rgb(220, 224, 232)", color{Red: 220, Green: 224, Blue: 232, Alpha: 1}},
		{"rgba", "rgba(220, 224, 232, 0.5)", color{Red: 220, Green: 224, Blue: 232, Alpha: 0.5}},
		{"spaces around the value", "  #dce0e8  ", color{Red: 0xdc, Green: 0xe0, Blue: 0xe8, Alpha: 1}},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			got, err := parseColor(testCase.value)
			if err != nil {
				t.Fatalf("parseColor(%q): %v", testCase.value, err)
			}
			if got != testCase.want {
				t.Fatalf("parseColor(%q) = %+v, want %+v", testCase.value, got, testCase.want)
			}
		})
	}
}

// TestParseColorRejects pins the values that are not colors. A palette
// that cannot be read has to say so instead of rendering a black
// template.
func TestParseColorRejects(t *testing.T) {
	for _, testCase := range []struct {
		name  string
		value string
	}{
		{"empty", ""},
		{"without a hash", "dce0e8"},
		{"four digits", "#dce0"},
		{"nine digits", "#dce0e8ff00"},
		{"two channels", "rgb(220, 224)"},
		{"alpha out of range", "rgba(220, 224, 232, 2)"},
		{"channel out of range", "rgb(300, 0, 0)"},
		{"another color model", "hsl(1, 2%, 3%)"},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			if _, err := parseColor(testCase.value); err == nil {
				t.Errorf("parseColor(%q) accepted a value that is not a color", testCase.value)
			}
		})
	}
}

// TestColorFormats pins every output format, including the alpha
// rules: the hex forms drop the alpha of an opaque color, and rgba
// always writes it.
func TestColorFormats(t *testing.T) {
	for _, testCase := range []struct {
		name  string
		color color
		hex   string
		strip string
		rgb   string
		rgba  string
	}{
		{
			name:  "opaque",
			color: color{Red: 0xdc, Green: 0xe0, Blue: 0xe8, Alpha: 1},
			hex:   "#dce0e8",
			strip: "dce0e8",
			rgb:   "rgb(220, 224, 232)",
			rgba:  "rgba(220, 224, 232, 1)",
		},
		{
			name:  "half transparent",
			color: color{Red: 0xdc, Green: 0xe0, Blue: 0xe8, Alpha: 0.5},
			hex:   "#dce0e880",
			strip: "dce0e880",
			rgb:   "rgb(220, 224, 232)",
			rgba:  "rgba(220, 224, 232, 0.5)",
		},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			if got := testCase.color.hex(); got != testCase.hex {
				t.Errorf("Hex() = %q, want %q", got, testCase.hex)
			}
			if got := testCase.color.hexStripped(); got != testCase.strip {
				t.Errorf("HexStripped() = %q, want %q", got, testCase.strip)
			}
			if got := testCase.color.rgb(); got != testCase.rgb {
				t.Errorf("RGB() = %q, want %q", got, testCase.rgb)
			}
			if got := testCase.color.rgba(); got != testCase.rgba {
				t.Errorf("RGBA() = %q, want %q", got, testCase.rgba)
			}
		})
	}
}

// TestFormatAlphaTrims pins the alpha text. A trailing zero makes the
// value look machine written, and more than three decimals is noise in
// a config file.
func TestFormatAlphaTrims(t *testing.T) {
	for _, testCase := range []struct {
		alpha float64
		want  string
	}{
		{1, "1"},
		{0.5, "0.5"},
		{0, "0"},
		{0.125, "0.125"},
		{0.333333, "0.333"},
	} {
		if got := formatAlpha(testCase.alpha); got != testCase.want {
			t.Errorf("formatAlpha(%v) = %q, want %q", testCase.alpha, got, testCase.want)
		}
	}
}
