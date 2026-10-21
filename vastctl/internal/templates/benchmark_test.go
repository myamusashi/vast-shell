package templates

import (
	"strings"
	"testing"
)

// realisticTemplate is a template of the size a user writes: a few
// dozen roles over a handful of lines.
var realisticTemplate = strings.TrimSpace(`
$background = {{colors.background.hex}}
$backgroundAlt = {{colors.background.hex_stripped}}
$surface = {{colors.surface.hex}}
$surfaceAlt = {{colors.surface.hex_stripped}}
$surfaceContainer = {{colors.surfaceContainer.hex}}
$surfaceContainerHigh = {{colors.surfaceContainerHigh.hex}}
$surfaceContainerHighest = {{colors.surfaceContainerHighest.hex}}
$onSurface = {{colors.onSurface.hex}}
$onSurfaceVariant = {{colors.onSurfaceVariant.hex}}
$outline = {{colors.outline.hex}}
$outlineVariant = {{colors.outlineVariant.hex}}
$primary = {{colors.primary.hex}}
$onPrimary = {{colors.onPrimary.hex}}
$primaryContainer = {{colors.primaryContainer.hex}}
$onPrimaryContainer = {{colors.onPrimaryContainer.hex}}
$secondary = {{colors.secondary.hex}}
$onSecondary = {{colors.onSecondary.hex}}
$secondaryContainer = {{colors.secondaryContainer.hex}}
$tertiary = {{colors.tertiary.hex}}
$onTertiary = {{colors.onTertiary.hex}}
$error = {{colors.error.hex}}
$onError = {{colors.onError.hex}}
$shadow = {{colors.shadow.rgb}}
$scrim = {{colors.scrim.rgba}}
$inverseSurface = {{colors.inverseSurface.hex}}
$inverseOnSurface = {{colors.inverseOnSurface.hex}}
$primaryFixed = {{colors.primaryFixed.hex}}
$tertiaryFixed = {{colors.tertiaryFixed.hex}}
$background = {{colors.background.rgb}}
$onSurface = {{colors.onSurface.rgb}}
$primary = {{colors.primary.rgb}}
$secondary = {{colors.secondary.rgb}}
$tertiary = {{colors.tertiary.rgb}}
$error = {{colors.error.rgb}}
$scrim = {{colors.scrim.rgba}}
$surface = {{colors.surface.rgba | alpha: 0.5}}
$onSurface = {{colors.onSurface.rgba | alpha: 0.8}}
mode = {{mode}}
image = {{image}}
`)

// benchmarkPalette is a palette of the size the shell returns.
func benchmarkPalette(tb testing.TB) palette {
	raw := make(map[string]string, 64)
	for _, role := range []string{
		"background", "surface", "surfaceContainer", "surfaceContainerHigh",
		"surfaceContainerHighest", "onSurface", "onSurfaceVariant", "outline",
		"outlineVariant", "primary", "onPrimary", "primaryContainer",
		"onPrimaryContainer", "secondary", "onSecondary", "secondaryContainer",
		"tertiary", "onTertiary", "error", "onError", "shadow", "scrim",
		"inverseSurface", "inverseOnSurface", "primaryFixed", "tertiaryFixed",
	} {
		raw[role] = "#dce0e8"
	}
	roles, err := buildPalette(raw)
	if err != nil {
		tb.Fatalf("buildPalette: %v", err)
	}
	return roles
}

// BenchmarkRender measures the render of a realistic template: the
// placeholders are parsed and the colors formatted.
func BenchmarkRender(b *testing.B) {
	roles := benchmarkPalette(b)
	values := variables{Mode: "dark", Image: "/home/user/Pictures/wallpapers/wall.png"}
	b.ReportAllocs()
	for b.Loop() {
		if _, err := render("colors.conf.tmpl", realisticTemplate, roles, values); err != nil {
			b.Fatalf("Render: %v", err)
		}
	}
}

// BenchmarkBuildPalette measures the normalisation of a palette.
func BenchmarkBuildPalette(b *testing.B) {
	raw := make(map[string]string, 64)
	for _, role := range []string{
		"background", "surface", "surfaceContainer", "surfaceContainerHigh",
		"surfaceContainerHighest", "onSurface", "onSurfaceVariant", "outline",
		"outlineVariant", "primary", "onPrimary", "primaryContainer",
		"onPrimaryContainer", "secondary", "onSecondary", "secondaryContainer",
		"tertiary", "onTertiary", "error", "onError", "shadow", "scrim",
		"inverseSurface", "inverseOnSurface", "primaryFixed", "tertiaryFixed",
	} {
		raw[role] = "#dce0e8"
	}
	b.ReportAllocs()
	for b.Loop() {
		if _, err := buildPalette(raw); err != nil {
			b.Fatalf("buildPalette: %v", err)
		}
	}
}

// BenchmarkCanonicalRole measures the folding of a role name, the work
// every placeholder pays for its own role.
func BenchmarkCanonicalRole(b *testing.B) {
	b.ReportAllocs()
	for b.Loop() {
		canonicalRole("surfaceContainerHighest")
	}
}
