package templates

import (
	"fmt"
	"strconv"
	"strings"
)

type variables struct {
	Mode  string
	Image string
}

type templateError struct {
	File        string
	Line        int
	Placeholder string
	Message     string
}

func (e *templateError) Error() string {
	return fmt.Sprintf("%s:%d: %s: %s", e.File, e.Line, e.Placeholder, e.Message)
}

func render(fileName, source string, roles palette, values variables) (string, error) {
	var rendered strings.Builder
	rendered.Grow(len(source))
	for index := 0; index < len(source); {
		start := strings.Index(source[index:], "{{")
		if start < 0 {
			rendered.WriteString(source[index:])
			break
		}
		start += index
		rendered.WriteString(source[index:start])
		end := strings.Index(source[start:], "}}")
		if end < 0 {
			return "", &templateError{
				File:        fileName,
				Line:        lineOf(source, start),
				Placeholder: "{{",
				Message:     "unterminated placeholder, \"}}\" is missing",
			}
		}
		end += start
		value, err := evaluate(fileName, source, start, source[start+2:end], roles, values)
		if err != nil {
			return "", err
		}
		rendered.WriteString(value)
		index = end + 2
	}
	return rendered.String(), nil
}

func evaluate(fileName, source string, offset int, expression string, roles palette, values variables) (string, error) {
	placeholder := "{{" + expression + "}}"
	failure := func(message string) error {
		return &templateError{
			File:        fileName,
			Line:        lineOf(source, offset),
			Placeholder: placeholder,
			Message:     message,
		}
	}

	parts := strings.Split(expression, "|")
	base := strings.TrimSpace(parts[0])
	filters := parts[1:]

	if base == "mode" || base == "image" {
		if len(filters) > 0 {
			return "", failure("the alpha filter only applies to a color placeholder")
		}
		if base == "mode" {
			return values.Mode, nil
		}
		return values.Image, nil
	}
	return resolveColor(base, filters, roles, values, failure)
}

// resolves a colors.<role>[.<light|dark>].<format> placeholder.
func resolveColor(base string, filters []string, roles palette, values variables, failure func(string) error) (string, error) {
	if !strings.HasPrefix(base, "colors.") {
		return "", failure(fmt.Sprintf("unknown placeholder %q, expected colors.<role>[.<light|dark>].<format>, mode or image", base))
	}
	parts := strings.Split(strings.TrimPrefix(base, "colors."), ".")
	if len(parts) != 2 && len(parts) != 3 {
		return "", failure(fmt.Sprintf("unknown placeholder %q, expected colors.<role>[.<light|dark>].<format>", base))
	}
	role := parts[0]
	format := parts[len(parts)-1]
	selected := roles
	if len(parts) == 3 {
		mode := parts[1]
		if mode != "light" && mode != "dark" {
			return "", failure(fmt.Sprintf("unknown color mode %q, expected light or dark", mode))
		}
		var exists bool
		selected, exists = roles.modes[mode]
		if !exists {
			return "", failure(fmt.Sprintf("color palette for %q mode is unavailable", mode))
		}
	}

	canonical := canonicalRole(role)
	if canonical == "mode" {
		return resolveMode(format, filters, values.Mode, failure)
	}
	roleColor, exists := selected.lookup(canonical)
	if !exists {
		message := fmt.Sprintf("unknown color role %q", role)
		if suggestions := suggestRoles(canonical, selected.roleNames(), 3); len(suggestions) > 0 {
			message += fmt.Sprintf(", did you mean %s", strings.Join(quoteAll(suggestions), ", "))
		}
		return "", failure(message)
	}

	alpha, err := resolveAlpha(filters, roleColor.Alpha, failure)
	if err != nil {
		return "", err
	}
	roleColor.Alpha = alpha

	switch format {
	case "hex":
		return roleColor.hex(), nil
	case "hex_stripped":
		return roleColor.hexStripped(), nil
	case "rgb":
		return roleColor.rgb(), nil
	case "rgba":
		return roleColor.rgba(), nil
	default:
		return "", failure(fmt.Sprintf("unknown format %q, expected hex, hex_stripped, rgb or rgba", format))
	}
}

// resolves the colors.mode.<auto|light|dark> placeholders.
func resolveMode(format string, filters []string, current string, failure func(string) error) (string, error) {
	if len(filters) > 0 {
		return "", failure("the alpha filter only applies to a color placeholder")
	}
	switch format {
	case "auto":
		return current, nil
	case "light", "dark":
		return format, nil
	default:
		return "", failure(fmt.Sprintf("unknown mode %q, expected auto, light or dark", format))
	}
}

// resolveAlpha applies the filters of a placeholder. The alpha filter
// replaces the alpha the palette carries.
func resolveAlpha(filters []string, current float64, failure func(string) error) (float64, error) {
	for _, filter := range filters {
		name, value, found := strings.Cut(strings.TrimSpace(filter), ":")
		if !found {
			return 0, failure(fmt.Sprintf("malformed filter %q, expected alpha: <number>", strings.TrimSpace(filter)))
		}
		if strings.TrimSpace(name) != "alpha" {
			return 0, failure(fmt.Sprintf("unknown filter %q, expected alpha", strings.TrimSpace(name)))
		}
		parsed, err := strconv.ParseFloat(strings.TrimSpace(value), 64)
		if err != nil {
			return 0, failure(fmt.Sprintf("the alpha filter needs a number, got %q", strings.TrimSpace(value)))
		}
		if parsed < 0 || parsed > 1 {
			return 0, failure(fmt.Sprintf("alpha %v is outside 0-1", parsed))
		}
		current = parsed
	}
	return current, nil
}

func lineOf(source string, offset int) int {
	if offset > len(source) {
		offset = len(source)
	}
	return strings.Count(source[:offset], "\n") + 1
}

func quoteAll(names []string) []string {
	quoted := make([]string, 0, len(names))
	for _, name := range names {
		quoted = append(quoted, fmt.Sprintf("%q", name))
	}
	return quoted
}
