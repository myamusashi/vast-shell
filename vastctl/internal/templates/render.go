package templates

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"
)

// hookTimeout is how long a post hook may run before it is killed.
const hookTimeout = 30 * time.Second

// paletteSource hands the renderer the wallpaper and the palette it
// renders from. The CLI fills it with the shell's IPC, the tests fill
// it with a fixed palette.
type paletteSource interface {
	CurrentWallpaper() (string, error)
	Palette(wallpaper, mode, scheme string) (map[string]string, error)
}

type Renderer struct {
	ConfigPath string
	Source     paletteSource
	Out        io.Writer
	Stderr     io.Writer
}

type RenderOptions struct {
	Wallpaper    string
	Mode         string
	Scheme       string
	TemplateName string
}

// Render renders the selected templates. Every template is attempted,
// so one broken template does not hide the state of the others; the
// failures are reported together.
func (r *Renderer) Render(options RenderOptions) error {
	templateList, err := loadConfig(r.ConfigPath)
	if err != nil {
		return err
	}
	selected, err := templateList.templatesFor(options.TemplateName)
	if err != nil {
		return fmt.Errorf("%w in %s", err, r.ConfigPath)
	}
	if len(selected) == 0 {
		return nil
	}

	wallpaper, err := r.resolveWallpaper(options)
	if err != nil {
		return err
	}
	roles, err := r.loadPalette(wallpaper, options)
	if err != nil {
		return err
	}
	values := variables{Mode: options.Mode, Image: wallpaper}

	var failures []error
	for _, entry := range selected {
		if err := r.renderTemplate(entry, roles, values); err != nil {
			failures = append(failures, err)
		}
	}
	return errors.Join(failures...)
}

// resolveWallpaper returns the wallpaper the palette is built from.
func (r *Renderer) resolveWallpaper(options RenderOptions) (string, error) {
	if options.Wallpaper != "" {
		return options.Wallpaper, nil
	}
	wallpaper, err := r.Source.CurrentWallpaper()
	if err != nil {
		return "", fmt.Errorf("read the current wallpaper: %w", err)
	}
	if wallpaper == "" {
		return "", errors.New("there is no wallpaper to render from")
	}
	return wallpaper, nil
}

// loadPalette asks the source for the palette of a wallpaper.
func (r *Renderer) loadPalette(wallpaper string, options RenderOptions) (palette, error) {
	raw, err := r.Source.Palette(wallpaper, options.Mode, options.Scheme)
	if err != nil {
		return palette{}, fmt.Errorf("generate the palette: %w", err)
	}
	return buildPalette(raw)
}

func (r *Renderer) renderTemplate(entry template, roles palette, values variables) error {
	inputPath, err := expandPath(entry.Input)
	if err != nil {
		return fmt.Errorf("template %q: %w", entry.Name, err)
	}
	source, err := os.ReadFile(inputPath)
	if err != nil {
		return fmt.Errorf("template %q: read %s: %w", entry.Name, inputPath, err)
	}
	rendered, err := render(inputPath, string(source), roles, values)
	if err != nil {
		return fmt.Errorf("template %q: %w", entry.Name, err)
	}
	outputPath, err := resolveOutputPath(entry, inputPath)
	if err != nil {
		return fmt.Errorf("template %q: %w", entry.Name, err)
	}
	written, err := writeFile(outputPath, []byte(rendered))
	if err != nil {
		return fmt.Errorf("template %q: %w", entry.Name, err)
	}
	if !written {
		r.report(fmt.Sprintf("%s is already up to date", outputPath))
		return nil
	}
	r.report(fmt.Sprintf("rendered %s -> %s", inputPath, outputPath))
	if entry.PostHook != "" {
		if err := runHook(entry.PostHook, filepath.Dir(outputPath), hookTimeout); err != nil {
			r.reportError(fmt.Sprintf("template %q: post hook failed: %v", entry.Name, err))
		}
	}
	return nil
}

func (r *Renderer) report(message string) {
	if r.Out == nil {
		return
	}
	_, _ = fmt.Fprintln(r.Out, message)
}

func (r *Renderer) reportError(message string) {
	if r.Stderr == nil {
		return
	}
	_, _ = fmt.Fprintln(r.Stderr, message)
}

// resolveOutputPath returns the file a template renders into. An
// explicit output path wins; otherwise the template suffix is stripped
// and the result lands next to the template.
func resolveOutputPath(entry template, inputPath string) (string, error) {
	if entry.OutputPath != "" {
		expanded, err := expandPath(entry.OutputPath)
		if err != nil {
			return "", err
		}
		if !filepath.IsAbs(expanded) {
			expanded = filepath.Join(filepath.Dir(inputPath), expanded)
		}
		return expanded, nil
	}
	switch {
	case strings.HasSuffix(inputPath, ".tmpl"):
		return strings.TrimSuffix(inputPath, ".tmpl"), nil
	case strings.HasSuffix(inputPath, ".template"):
		return strings.TrimSuffix(inputPath, ".template"), nil
	default:
		return inputPath + ".rendered", nil
	}
}

func expandPath(path string) (string, error) {
	expanded := os.ExpandEnv(path)
	if expanded == "~" || strings.HasPrefix(expanded, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("resolve %s: %w", path, err)
		}
		expanded = filepath.Join(home, strings.TrimPrefix(expanded[1:], "/"))
	}
	return expanded, nil
}

// writeFile writes content to a path and replaces the file that is
// there. The write is atomic: the content lands in a temporary file in
// the same directory and is renamed over the target, so a reader never
// sees a half-written file. A file that already holds the same content
// is left alone, so a watcher does not fire for nothing.
func writeFile(path string, content []byte) (bool, error) {
	if existing, err := os.ReadFile(path); err == nil && bytes.Equal(existing, content) {
		return false, nil
	}
	directory := filepath.Dir(path)
	if err := os.MkdirAll(directory, 0o755); err != nil {
		return false, fmt.Errorf("create %s: %w", directory, err)
	}
	temporary, err := os.CreateTemp(directory, ".vastctl-template-*")
	if err != nil {
		return false, fmt.Errorf("create a temporary file in %s: %w", directory, err)
	}
	temporaryPath := temporary.Name()
	defer func() { _ = os.Remove(temporaryPath) }()
	if _, err := temporary.Write(content); err != nil {
		_ = temporary.Close()
		return false, fmt.Errorf("write %s: %w", temporaryPath, err)
	}
	if err := temporary.Close(); err != nil {
		return false, fmt.Errorf("write %s: %w", temporaryPath, err)
	}
	if err := os.Chmod(temporaryPath, 0o644); err != nil {
		return false, fmt.Errorf("write %s: %w", temporaryPath, err)
	}
	if err := os.Rename(temporaryPath, path); err != nil {
		return false, fmt.Errorf("write %s: %w", path, err)
	}
	return true, nil
}

// runHook runs the post hook in the directory of the file it rendered.
func runHook(command, directory string, timeout time.Duration) error {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	hook := exec.CommandContext(ctx, "/bin/sh", "-c", command)
	hook.Dir = directory
	// The hook runs in its own group, so a timeout takes the children it
	// started with it instead of leaving them behind.
	hook.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	hook.Cancel = func() error {
		if hook.Process == nil {
			return nil
		}
		return syscall.Kill(-hook.Process.Pid, syscall.SIGKILL)
	}
	hook.WaitDelay = time.Second
	output, err := hook.CombinedOutput()
	if err != nil {
		if ctx.Err() != nil {
			return fmt.Errorf("timed out after %s", timeout)
		}
		details := strings.TrimSpace(string(output))
		if details == "" {
			return err
		}
		return fmt.Errorf("%w: %s", err, details)
	}
	return nil
}
