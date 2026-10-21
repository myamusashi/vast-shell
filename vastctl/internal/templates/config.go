package templates

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
)

type template struct {
	Name       string `json:"name"`
	Input      string `json:"input"`
	OutputPath string `json:"output_path"`
	PostHook   string `json:"post_hook"`
	Enabled    *bool  `json:"enabled"`
}

// isEnabled reports whether the template takes part in a render. The
// flag turns a template off, so a template without one is enabled.
func (t template) isEnabled() bool {
	return t.Enabled == nil || *t.Enabled
}

// config is the template list the CLI and the settings page share.
type config struct {
	Templates []template `json:"templates"`
}

// loadConfig reads the template list. A list that does not exist yet is
// an empty list: a shell without templates is not an error.
func loadConfig(path string) (config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return config{}, nil
		}
		return config{}, fmt.Errorf("read %s: %w", path, err)
	}
	var list config
	if err := json.Unmarshal(data, &list); err != nil {
		return config{}, fmt.Errorf("parse %s: %w", path, err)
	}
	return list, nil
}

// templatesFor returns the templates a render works on: every enabled one,
// or the one with the given name.
func (c config) templatesFor(name string) ([]template, error) {
	if name == "" {
		enabled := make([]template, 0, len(c.Templates))
		for _, entry := range c.Templates {
			if entry.isEnabled() {
				enabled = append(enabled, entry)
			}
		}
		return enabled, nil
	}
	for _, entry := range c.Templates {
		if entry.Name == name {
			return []template{entry}, nil
		}
	}
	return nil, fmt.Errorf("no template named %q", name)
}

// DefaultConfigPath is the template list the CLI and the settings page
// share: the shell's own config directory, which honours the same
// XDG_CONFIG_DIR the shell honours.
func DefaultConfigPath() string {
	configDir := os.Getenv("XDG_CONFIG_DIR")
	if configDir == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return ""
		}
		configDir = filepath.Join(home, ".config")
	}
	return filepath.Join(configDir, "vast-shell", "templates.json")
}
