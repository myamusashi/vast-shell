package hypr

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
)

// Dispatch fires a vast-shell global shortcut via Hyprland's Lua dispatcher.
// Example: hyprctl dispatch 'hl.dsp.global(wallpaperSwitcher)'
func Dispatch(shortcut string) error {
	arg := fmt.Sprintf("hl.dsp.global(\"quickshell:%s\")", shortcut)
	cmd := exec.Command("hyprctl", "dispatch", arg)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("hyprctl dispatch %s: %w", arg, err)
	}
	return nil
}

// Shortcut represents a registered Hyprland global shortcut.
type Shortcut struct {
	Name        string `json:"name"`
	Description string `json:"description"`
}

// ListShortcuts returns all quickshell global shortcut binds from the
// live Hyprland bind table, sourced via `hyprctl globalshortcuts -j`.
func ListShortcuts() ([]Shortcut, error) {
	// stdout and stderr are both captured by hand. Output() takes
	// stdout only, and hyprctl reports "no instance" and friends on
	// stderr, so a failure there would degrade to a bare "exit status
	// 1" that names neither the command nor the reason.
	var stdout, stderr bytes.Buffer
	cmd := exec.Command("hyprctl", "globalshortcuts", "-j")
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		if detail := strings.TrimSpace(stderr.String()); detail != "" {
			return nil, fmt.Errorf("hyprctl globalshortcuts: %s", detail)
		}
		return nil, fmt.Errorf("hyprctl globalshortcuts: %w", err)
	}

	var raw []struct {
		Name        string `json:"name"`
		Description string `json:"description"`
	}

	if err := json.Unmarshal(stdout.Bytes(), &raw); err != nil {
		return nil, fmt.Errorf("hyprctl globalshortcuts json: %w", err)
	}
	var shortcuts []Shortcut
	for _, s := range raw {
		if !strings.HasPrefix(s.Name, "quickshell:") {
			continue
		}
		name := strings.TrimPrefix(s.Name, "quickshell:")
		shortcuts = append(shortcuts, Shortcut{
			Name:        name,
			Description: s.Description,
		})
	}
	return shortcuts, nil
}
