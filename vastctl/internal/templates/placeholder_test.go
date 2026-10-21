package templates

import (
	"strings"
	"testing"
)

// testPalette is the palette the placeholder tests render with.
func testPalette(t *testing.T) palette {
	t.Helper()
	roles, err := buildPalette(map[string]string{
		"onSurface":   "#dce0e8",
		"surface":     "#112233",
		"primary":     "#ff0000",
		"sourceColor": "#4285f4",
	})
	if err != nil {
		t.Fatalf("buildPalette: %v", err)
	}
	return roles
}

// TestRenderPlaceholders pins the placeholder syntax. Both spellings of
// a role name have to resolve to the same color, and every format has
// to write the color the way the target expects it.
func TestRenderPlaceholders(t *testing.T) {
	roles := testPalette(t)
	values := variables{Mode: "dark", Image: "/home/user/wall.png"}

	for _, testCase := range []struct {
		name     string
		template string
		want     string
	}{
		{"camel case role", "{{colors.onSurface.hex}}", "#dce0e8"},
		{"snake case role", "{{colors.on_surface.hex}}", "#dce0e8"},
		{"upper case role", "{{colors.ON_SURFACE.hex}}", "#dce0e8"},
		{"hex stripped", "{{colors.onSurface.hex_stripped}}", "dce0e8"},
		{"rgb", "{{colors.onSurface.rgb}}", "rgb(220, 224, 232)"},
		{"rgba", "{{colors.onSurface.rgba}}", "rgba(220, 224, 232, 1)"},
		{"alpha filter", "{{colors.surface.hex | alpha: 0.5}}", "#11223380"},
		{"alpha filter on rgb", "{{colors.surface.rgb | alpha: 0.5}}", "rgb(17, 34, 51)"},
		{"alpha filter with rgba", "{{colors.surface.rgba | alpha: 0.5}}", "rgba(17, 34, 51, 0.5)"},
		{"mode", "{{mode}}", "dark"},
		{"image", "{{image}}", "/home/user/wall.png"},
		{"text around a placeholder", "bg = {{colors.surface.hex}};\n", "bg = #112233;\n"},
		{"two placeholders", "{{colors.surface.hex}} {{colors.primary.hex}}", "#112233 #ff0000"},
		{"no placeholder", "plain text", "plain text"},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			got, err := render("colors.conf.tmpl", testCase.template, roles, values)
			if err != nil {
				t.Fatalf("render(%q): %v", testCase.template, err)
			}
			if got != testCase.want {
				t.Fatalf("render(%q) = %q, want %q", testCase.template, got, testCase.want)
			}
		})
	}
}

// TestRenderKeepsHexAlpha pins that the alpha of a palette color
// survives a render: #dce0e880 has to come back as #dce0e880.
func TestRenderKeepsHexAlpha(t *testing.T) {
	roles, err := buildPalette(map[string]string{"onSurface": "#dce0e880"})
	if err != nil {
		t.Fatalf("buildPalette: %v", err)
	}
	got, err := render("colors.conf.tmpl", "{{colors.onSurface.hex}}", roles, variables{})
	if err != nil {
		t.Fatalf("render: %v", err)
	}
	if want := "#dce0e880"; got != want {
		t.Fatalf("render = %q, want %q", got, want)
	}
}

// TestRenderUnknownRole pins the error of a role that is not in the
// palette. The message has to name the file, the line and the
// placeholder, and it has to offer the roles that were meant.
func TestRenderUnknownRole(t *testing.T) {
	roles := testPalette(t)
	_, err := render("colors.conf.tmpl", "first\n{{colors.onSurfce.hex}}\n", roles, variables{})
	if err == nil {
		t.Fatal("an unknown role must fail")
	}
	message := err.Error()
	for _, fragment := range []string{"colors.conf.tmpl:2", "{{colors.onSurfce.hex}}", "onSurface"} {
		if !strings.Contains(message, fragment) {
			t.Errorf("error %q does not mention %q", message, fragment)
		}
	}
}

// TestRenderUnknownPlaceholder pins the errors of the placeholders the
// renderer does not know. A template must never render an empty value
// where it asked for a color.
func TestRenderUnknownPlaceholder(t *testing.T) {
	roles := testPalette(t)
	for _, testCase := range []struct {
		name      string
		template  string
		fragments []string
	}{
		{"unknown name", "{{wallpaper}}", []string{"unknown placeholder"}},
		{"unknown format", "{{colors.surface.hsv}}", []string{"unknown format"}},
		{"missing format", "{{colors.surface}}", []string{"unknown placeholder"}},
		{"unterminated", "{{colors.surface.hex", []string{"unterminated placeholder"}},
		{"unknown filter", "{{colors.surface.hex | blur: 2}}", []string{"unknown filter"}},
		{"malformed filter", "{{colors.surface.hex | 0.5}}", []string{"malformed filter"}},
		{"alpha out of range", "{{colors.surface.hex | alpha: 2}}", []string{"outside 0-1"}},
		{"alpha not a number", "{{colors.surface.hex | alpha: half}}", []string{"needs a number"}},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			_, err := render("colors.conf.tmpl", testCase.template, roles, variables{})
			if err == nil {
				t.Fatalf("%q must fail", testCase.template)
			}
			for _, fragment := range testCase.fragments {
				if !strings.Contains(err.Error(), fragment) {
					t.Errorf("error %q does not mention %q", err, fragment)
				}
			}
		})
	}
}

// TestBuildPaletteCollision pins that two roles that fold into the same
// name are an error. Picking one of them would render a color the
// template did not ask for.
func TestBuildPaletteCollision(t *testing.T) {
	_, err := buildPalette(map[string]string{
		"onSurface":  "#dce0e8",
		"on_surface": "#112233",
	})
	if err == nil {
		t.Fatal("two roles with the same canonical name must fail")
	}
	for _, fragment := range []string{"onSurface", "on_surface"} {
		if !strings.Contains(err.Error(), fragment) {
			t.Errorf("error %q does not mention %q", err, fragment)
		}
	}
}

// TestBuildPaletteRejectsBadColor pins that a palette with a color the
// renderer cannot read is an error instead of a black template.
func TestBuildPaletteRejectsBadColor(t *testing.T) {
	_, err := buildPalette(map[string]string{"surface": "not-a-color"})
	if err == nil {
		t.Fatal("a palette with an unreadable color must fail")
	}
	if !strings.Contains(err.Error(), "surface") {
		t.Errorf("error %q does not name the role", err)
	}
}

// TestCanonicalRole pins the folding of a role name.
func TestCanonicalRole(t *testing.T) {
	for _, testCase := range []struct {
		name string
		want string
	}{
		{"onSurface", "onSurface"},
		{"on_surface", "onSurface"},
		{"ON_SURFACE", "onSurface"},
		{"onSurfaceVariant", "onSurfaceVariant"},
		{"on_surface_variant", "onSurfaceVariant"},
		{"surface", "surface"},
	} {
		if got := canonicalRole(testCase.name); got != testCase.want {
			t.Errorf("canonicalRole(%q) = %q, want %q", testCase.name, got, testCase.want)
		}
	}
}

// TestParsePalette pins the payload the shell answers with.
func TestParsePalette(t *testing.T) {
	colors, err := ParsePalette(`{"colors":{"background":"#112233","onSurface":"#dce0e8"}}`)
	if err != nil {
		t.Fatalf("ParsePalette: %v", err)
	}
	if len(colors) != 2 || colors["onSurface"] != "#dce0e8" {
		t.Fatalf("ParsePalette returned %v", colors)
	}
	if _, err := ParsePalette(`{"error":"failed to decode image"}`); err == nil {
		t.Error("a palette error must fail")
	}
	if _, err := ParsePalette(`{"colors":{}}`); err == nil {
		t.Error("an empty palette must fail")
	}
	if _, err := ParsePalette("not json"); err == nil {
		t.Error("a payload that is not json must fail")
	}
}
