package hypr

import (
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
	output, err := exec.Command("hyprctl", "globalshortcuts", "-j").Output()
	if err != nil {
		return nil, fmt.Errorf("hyprctl globalshortcuts: %w", err)
	}

	var raw []struct {
		Name        string `json:"name"`
		Description string `json:"description"`
	}

	if err := json.Unmarshal(output, &raw); err != nil {
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
