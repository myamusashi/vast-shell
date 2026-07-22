package hypr

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
)

func Dispatch(shortcut string) error {
	cmd := exec.Command("hyprctl", "dispatch", "submap", "vast")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("hyprctl dispatch submap vast: %w", err)
	}
	_ = cmd

	cmd2 := exec.Command("hyprctl", "dispatch", "exec", fmt.Sprintf("vast-dispatch %s", shortcut))
	if err := cmd2.Run(); err != nil {
		return fmt.Errorf("hyprctl dispatch exec: %w", err)
	}
	_ = cmd2

	return nil
}

type Shortcut struct {
	Name          string `json:"name"`
	Description   string `json:"description"`
	Keys          string `json:"keys"`
}

func ListShortcuts() ([]Shortcut, error) {
	// Probes hyprctl binds for the live bind table
	output, err := exec.Command("hyprctl", "binds", "-j").Output()
	if err != nil {
		return nil, fmt.Errorf("hyprctl binds: %w", err)
	}

	var raw []struct {
		Submap      string `json:"submap"`
		Description string `json:"description"`
		Dispatcher  string `json:"dispatcher"`
		Arg         string `json:"arg"`
		Key         string `json:"key"`
		Mods        int    `json:"modmask"`
		Locked      bool   `json:"locked"`
	}

	if err := json.Unmarshal(output, &raw); err != nil {
		return nil, fmt.Errorf("hyprctl binds json: %w", err)
	}

	var shortcuts []Shortcut
	for _, b := range raw {
		if b.Submap != "vast" {
			continue
		}
		if b.Dispatcher != "exec" {
			continue
		}
		name := strings.TrimPrefix(b.Arg, "vast-dispatch ")
		key := b.Key
		if key == "" {
			key = "none"
		}
		shortcuts = append(shortcuts, Shortcut{
			Name:        name,
			Description: b.Description,
			Keys:        key,
		})
	}
	return shortcuts, nil
}
