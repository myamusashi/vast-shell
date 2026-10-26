package templates

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// fakeSource is the palette the renderer tests render with.
type fakeSource struct {
	wallpaper  string
	colors     map[string]string
	modeColors map[string]map[string]string
}

func (f fakeSource) CurrentWallpaper() (string, error) {
	return f.wallpaper, nil
}

func (f fakeSource) Palette(wallpaper, mode, scheme string) (map[string]string, error) {
	if colors, exists := f.modeColors[mode]; exists {
		return colors, nil
	}
	return f.colors, nil
}

// TestResolveOutputPath pins the naming of the rendered file. A
// template suffix is stripped, and a template without one keeps its
// name and gains the rendered suffix.
func TestResolveOutputPath(t *testing.T) {
	for _, testCase := range []struct {
		name     string
		template template
		input    string
		want     string
	}{
		{"tmpl suffix", template{}, "/home/user/colors.conf.tmpl", "/home/user/colors.conf"},
		{"template suffix", template{}, "/home/user/colors.conf.template", "/home/user/colors.conf"},
		{"no suffix", template{}, "/home/user/colors.conf", "/home/user/colors.conf.rendered"},
		{"explicit path", template{OutputPath: "/etc/colors.conf"}, "/home/user/colors.conf.tmpl", "/etc/colors.conf"},
		{"explicit relative path", template{OutputPath: "out.conf"}, "/home/user/colors.conf.tmpl", "/home/user/out.conf"},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			got, err := resolveOutputPath(testCase.template, testCase.input)
			if err != nil {
				t.Fatalf("ResolveOutputPath: %v", err)
			}
			if got != testCase.want {
				t.Fatalf("ResolveOutputPath = %q, want %q", got, testCase.want)
			}
		})
	}
}

// TestRenderWritesTemplate pins a render end to end: the template is
// read, the placeholders are filled and the file lands next to the
// template.
func TestRenderWritesTemplate(t *testing.T) {
	directory := t.TempDir()
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("bg={{colors.surface.hex}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	config := filepath.Join(directory, "templates.json")
	writeConfig(t, config, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true}]}`)

	renderer := Renderer{
		ConfigPath: config,
		Source:     fakeSource{wallpaper: "/wall.png", colors: map[string]string{"surface": "#112233"}},
	}
	if err := renderer.Render(RenderOptions{Mode: "dark", Scheme: "tonal-spot"}); err != nil {
		t.Fatalf("Render: %v", err)
	}
	written, err := os.ReadFile(filepath.Join(directory, "colors.conf"))
	if err != nil {
		t.Fatalf("read the rendered file: %v", err)
	}
	if string(written) != "bg=#112233\n" {
		t.Fatalf("the rendered file holds %q", written)
	}
}

func TestRenderUsesExplicitColorModes(t *testing.T) {
	directory := t.TempDir()
	input := filepath.Join(directory, "colors.conf.tmpl")
	template := "auto={{colors.surface.hex}} light={{colors.surface.light.hex}} dark={{colors.surface.dark.hex}}\n"
	if err := os.WriteFile(input, []byte(template), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	config := filepath.Join(directory, "templates.json")
	writeConfig(t, config, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true}]}`)

	renderer := Renderer{
		ConfigPath: config,
		Source: fakeSource{
			wallpaper: "/wall.png",
			modeColors: map[string]map[string]string{
				"dark":  {"surface": "#112233"},
				"light": {"surface": "#abcdef"},
			},
		},
	}
	if err := renderer.Render(RenderOptions{Mode: "dark", Scheme: "tonal-spot"}); err != nil {
		t.Fatalf("Render: %v", err)
	}
	written, err := os.ReadFile(filepath.Join(directory, "colors.conf"))
	if err != nil {
		t.Fatalf("read the rendered file: %v", err)
	}
	if got, want := string(written), "auto=#112233 light=#abcdef dark=#112233\n"; got != want {
		t.Fatalf("the rendered file holds %q, want %q", got, want)
	}
}

// TestRenderReplacesTheOutput pins that a rendered file replaces the
// file that is already there. A file that was edited by hand is lost,
// which is why the settings page warns about it.
func TestRenderReplacesTheOutput(t *testing.T) {
	directory := t.TempDir()
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("bg={{colors.surface.hex}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	output := filepath.Join(directory, "colors.conf")
	if err := os.WriteFile(output, []byte("edited by hand\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", output, err)
	}
	config := filepath.Join(directory, "templates.json")
	writeConfig(t, config, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true}]}`)

	renderer := Renderer{
		ConfigPath: config,
		Source:     fakeSource{wallpaper: "/wall.png", colors: map[string]string{"surface": "#112233"}},
	}
	if err := renderer.Render(RenderOptions{Mode: "dark", Scheme: "tonal-spot"}); err != nil {
		t.Fatalf("Render: %v", err)
	}
	written, err := os.ReadFile(output)
	if err != nil {
		t.Fatalf("read the rendered file: %v", err)
	}
	if string(written) != "bg=#112233\n" {
		t.Fatalf("the rendered file holds %q", written)
	}
}

// TestRenderSkipsUnchangedOutput pins that a file that already holds
// the rendered content is left alone, so a watcher does not fire for a
// palette that did not change.
func TestRenderSkipsUnchangedOutput(t *testing.T) {
	directory := t.TempDir()
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("bg={{colors.surface.hex}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	output := filepath.Join(directory, "colors.conf")
	if err := os.WriteFile(output, []byte("bg=#112233\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", output, err)
	}
	marker := filepath.Join(directory, "hook-ran")
	config := filepath.Join(directory, "templates.json")
	writeConfig(t, config, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true,"post_hook":"touch `+marker+`"}]}`)

	renderer := Renderer{
		ConfigPath: config,
		Source:     fakeSource{wallpaper: "/wall.png", colors: map[string]string{"surface": "#112233"}},
	}
	if err := renderer.Render(RenderOptions{Mode: "dark", Scheme: "tonal-spot"}); err != nil {
		t.Fatalf("Render: %v", err)
	}
	if _, err := os.Stat(marker); !os.IsNotExist(err) {
		t.Fatal("the post hook ran although nothing was written")
	}
}

// TestRenderRunsHook pins that the post hook runs after a successful
// write.
func TestRenderRunsHook(t *testing.T) {
	directory := t.TempDir()
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("bg={{colors.surface.hex}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	marker := filepath.Join(directory, "hook-ran")
	config := filepath.Join(directory, "templates.json")
	writeConfig(t, config, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true,"post_hook":"touch `+marker+`"}]}`)

	renderer := Renderer{
		ConfigPath: config,
		Source:     fakeSource{wallpaper: "/wall.png", colors: map[string]string{"surface": "#112233"}},
	}
	if err := renderer.Render(RenderOptions{Mode: "dark", Scheme: "tonal-spot"}); err != nil {
		t.Fatalf("Render: %v", err)
	}
	if _, err := os.Stat(marker); err != nil {
		t.Fatalf("the post hook did not run: %v", err)
	}
}

// TestRenderSelectsTemplates pins the selection: without a name every
// enabled template is rendered, and a disabled one is left alone.
func TestRenderSelectsTemplates(t *testing.T) {
	directory := t.TempDir()
	first := filepath.Join(directory, "first.conf.tmpl")
	second := filepath.Join(directory, "second.conf.tmpl")
	for _, path := range []string{first, second} {
		if err := os.WriteFile(path, []byte("bg={{colors.surface.hex}}\n"), 0o644); err != nil {
			t.Fatalf("write %s: %v", path, err)
		}
	}
	config := filepath.Join(directory, "templates.json")
	writeConfig(t, config, `{"templates":[`+
		`{"name":"first","input":"`+first+`","enabled":true},`+
		`{"name":"second","input":"`+second+`","enabled":false}]}`)

	renderer := Renderer{
		ConfigPath: config,
		Source:     fakeSource{wallpaper: "/wall.png", colors: map[string]string{"surface": "#112233"}},
	}
	if err := renderer.Render(RenderOptions{Mode: "dark", Scheme: "tonal-spot"}); err != nil {
		t.Fatalf("Render: %v", err)
	}
	if _, err := os.Stat(filepath.Join(directory, "first.conf")); err != nil {
		t.Fatalf("the enabled template was not rendered: %v", err)
	}
	if _, err := os.Stat(filepath.Join(directory, "second.conf")); !os.IsNotExist(err) {
		t.Fatal("a disabled template was rendered")
	}
}

// TestRenderNamedTemplate pins that a named template is rendered even
// when it is disabled, and that an unknown name is an error.
func TestRenderNamedTemplate(t *testing.T) {
	directory := t.TempDir()
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("bg={{colors.surface.hex}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	config := filepath.Join(directory, "templates.json")
	writeConfig(t, config, `{"templates":[{"name":"colors","input":"`+input+`","enabled":false}]}`)

	renderer := Renderer{
		ConfigPath: config,
		Source:     fakeSource{wallpaper: "/wall.png", colors: map[string]string{"surface": "#112233"}},
	}
	if err := renderer.Render(RenderOptions{Mode: "dark", Scheme: "tonal-spot", TemplateName: "colors"}); err != nil {
		t.Fatalf("Render: %v", err)
	}
	if _, err := os.Stat(filepath.Join(directory, "colors.conf")); err != nil {
		t.Fatalf("the named template was not rendered: %v", err)
	}
	if err := renderer.Render(RenderOptions{Mode: "dark", Scheme: "tonal-spot", TemplateName: "absent"}); err == nil {
		t.Fatal("an unknown template name must fail")
	}
}

// TestRenderUsesCurrentWallpaper pins that the renderer asks for the
// current wallpaper when it was not given one.
func TestRenderUsesCurrentWallpaper(t *testing.T) {
	directory := t.TempDir()
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("image={{image}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	config := filepath.Join(directory, "templates.json")
	writeConfig(t, config, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true}]}`)

	renderer := Renderer{
		ConfigPath: config,
		Source:     fakeSource{wallpaper: "/wall.png", colors: map[string]string{"surface": "#112233"}},
	}
	if err := renderer.Render(RenderOptions{Mode: "dark", Scheme: "tonal-spot"}); err != nil {
		t.Fatalf("Render: %v", err)
	}
	written, err := os.ReadFile(filepath.Join(directory, "colors.conf"))
	if err != nil {
		t.Fatalf("read the rendered file: %v", err)
	}
	if string(written) != "image=/wall.png\n" {
		t.Fatalf("the rendered file holds %q", written)
	}
}

// TestLoadConfig pins the reading of the template list: a list that
// does not exist is empty, and a list that cannot be read is an error.
func TestLoadConfig(t *testing.T) {
	config, err := loadConfig(filepath.Join(t.TempDir(), "absent.json"))
	if err != nil {
		t.Fatalf("LoadConfig: %v", err)
	}
	if len(config.Templates) != 0 {
		t.Fatalf("a missing config returned %d templates", len(config.Templates))
	}
	broken := filepath.Join(t.TempDir(), "templates.json")
	writeConfig(t, broken, "not json")
	if _, err := loadConfig(broken); err == nil {
		t.Fatal("a config that is not json must fail")
	}
}

// TestConfigSelect pins the selection rules of the template list.
func TestConfigSelect(t *testing.T) {
	disabled := false
	config := config{Templates: []template{
		{Name: "first"},
		{Name: "second", Enabled: &disabled},
	}}
	selected, err := config.templatesFor("")
	if err != nil {
		t.Fatalf("Select: %v", err)
	}
	if len(selected) != 1 || selected[0].Name != "first" {
		t.Fatalf("Select returned %v", selected)
	}
	selected, err = config.templatesFor("second")
	if err != nil {
		t.Fatalf("Select: %v", err)
	}
	if len(selected) != 1 || selected[0].Name != "second" {
		t.Fatalf("Select returned %v", selected)
	}
	if _, err := config.templatesFor("absent"); err == nil {
		t.Fatal("an unknown name must fail")
	}
}

// writeConfig writes a template list.
func writeConfig(t *testing.T, path, content string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}

// TestRunHookTimeout pins that a hook that hangs is killed, and that
// the children it started go with it: a hook that leaves a process
// behind would keep running after the render is over.
func TestRunHookTimeout(t *testing.T) {
	directory := t.TempDir()
	marker := filepath.Join(directory, "child-ran")
	command := fmt.Sprintf("(sleep 0.8; touch %s) & sleep 10", marker)

	started := time.Now()
	err := runHook(command, directory, 200*time.Millisecond)
	if err == nil {
		t.Fatal("a hook that hangs must fail")
	}
	if !strings.Contains(err.Error(), "timed out") {
		t.Fatalf("the error %q does not say that the hook timed out", err)
	}
	if elapsed := time.Since(started); elapsed > 5*time.Second {
		t.Fatalf("the hook was killed after %s, not after the timeout", elapsed)
	}
	time.Sleep(1200 * time.Millisecond)
	if _, err := os.Stat(marker); err == nil {
		t.Fatal("the child of the hook outlived the timeout")
	}
}

// TestRenderUsesThePaletteFile pins that a palette file takes the place
// of the palette the shell builds: the shell shows a palette of its own
// when the static colors are on, and the templates have to follow.
func TestRenderUsesThePaletteFile(t *testing.T) {
	directory := t.TempDir()
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("bg={{colors.background.hex}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	paletteFile := filepath.Join(directory, "colors.json")
	if err := os.WriteFile(paletteFile, []byte(`{"background":"#1a1111","onSurface":"#f0dede"}`), 0o644); err != nil {
		t.Fatalf("write %s: %v", paletteFile, err)
	}
	config := filepath.Join(directory, "templates.json")
	writeConfig(t, config, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true}]}`)

	renderer := Renderer{
		ConfigPath: config,
		Source:     fakeSource{wallpaper: "/wall.png", colors: map[string]string{"background": "#000000"}},
	}
	options := RenderOptions{Mode: "dark", Scheme: "tonal-spot", PalettePath: paletteFile}
	if err := renderer.Render(options); err != nil {
		t.Fatalf("Render: %v", err)
	}
	written, err := os.ReadFile(filepath.Join(directory, "colors.conf"))
	if err != nil {
		t.Fatalf("read the rendered file: %v", err)
	}
	if string(written) != "bg=#1a1111\n" {
		t.Fatalf("the rendered file holds %q", written)
	}
}

// TestRenderPaletteFileShapes pins that a palette file is read whether
// it holds the role map flat or under "colors".
func TestRenderPaletteFileShapes(t *testing.T) {
	directory := t.TempDir()
	for name, content := range map[string]string{
		"flat.json":    `{"background":"#1a1111"}`,
		"wrapped.json": `{"colors":{"background":"#1a1111"}}`,
	} {
		path := filepath.Join(directory, name)
		if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
			t.Fatalf("write %s: %v", path, err)
		}
		colors, err := parsePaletteFile(path)
		if err != nil {
			t.Fatalf("parsePaletteFile(%s): %v", name, err)
		}
		if colors["background"] != "#1a1111" {
			t.Fatalf("parsePaletteFile(%s) = %v", name, colors)
		}
	}
}

// TestRenderReportsABrokenPaletteFile pins that a palette file that
// cannot be read fails with a reason.
func TestRenderReportsABrokenPaletteFile(t *testing.T) {
	directory := t.TempDir()
	input := filepath.Join(directory, "colors.conf.tmpl")
	if err := os.WriteFile(input, []byte("bg={{colors.background.hex}}\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", input, err)
	}
	paletteFile := filepath.Join(directory, "colors.json")
	if err := os.WriteFile(paletteFile, []byte("not json"), 0o644); err != nil {
		t.Fatalf("write %s: %v", paletteFile, err)
	}
	config := filepath.Join(directory, "templates.json")
	writeConfig(t, config, `{"templates":[{"name":"colors","input":"`+input+`","enabled":true}]}`)

	renderer := Renderer{
		ConfigPath: config,
		Source:     fakeSource{wallpaper: "/wall.png", colors: map[string]string{"background": "#000000"}},
	}
	options := RenderOptions{Mode: "dark", Scheme: "tonal-spot", PalettePath: paletteFile}
	err := renderer.Render(options)
	if err == nil {
		t.Fatal("a palette file that is not json must fail")
	}
	if !strings.Contains(err.Error(), paletteFile) {
		t.Errorf("the error %q does not name the file", err)
	}
}
