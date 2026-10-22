package templates

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"
	"unicode"
)

type palette struct {
	colors map[string]color
}

func (p palette) lookup(role string) (color, bool) {
	color, exists := p.colors[role]
	return color, exists
}

func (p palette) roleNames() []string {
	roles := make([]string, 0, len(p.colors))
	for role := range p.colors {
		roles = append(roles, role)
	}
	sort.Strings(roles)
	return roles
}

func buildPalette(raw map[string]string) (palette, error) {
	colors := make(map[string]color, len(raw))
	origins := make(map[string]string, len(raw))
	for _, key := range sortedKeys(raw) {
		canonical := canonicalRole(key)
		if canonical == "" {
			return palette{}, fmt.Errorf("palette role %q has no name", key)
		}
		if previous, exists := origins[canonical]; exists {
			return palette{}, fmt.Errorf("palette roles %q and %q collapse to the same role %q", previous, key, canonical)
		}
		parsed, err := parseColor(raw[key])
		if err != nil {
			return palette{}, fmt.Errorf("palette role %q: %w", key, err)
		}
		origins[canonical] = key
		colors[canonical] = parsed
	}
	return palette{colors: colors}, nil
}

func ParsePalette(payload string) (map[string]string, error) {
	var response struct {
		Colors map[string]string `json:"colors"`
		Error  string            `json:"error"`
	}
	if err := json.Unmarshal([]byte(payload), &response); err != nil {
		return nil, fmt.Errorf("parse the palette: %w", err)
	}
	if response.Error != "" {
		return nil, fmt.Errorf("the shell reported: %s", response.Error)
	}
	if len(response.Colors) == 0 {
		return nil, fmt.Errorf("the shell returned no colors")
	}
	return response.Colors, nil
}

func parsePaletteFile(path string) (map[string]string, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}
	var wrapped struct {
		Colors map[string]string `json:"colors"`
	}
	if err := json.Unmarshal(data, &wrapped); err == nil && len(wrapped.Colors) > 0 {
		return wrapped.Colors, nil
	}
	var flat map[string]string
	if err := json.Unmarshal(data, &flat); err != nil {
		return nil, fmt.Errorf("parse %s: %w", path, err)
	}
	if len(flat) == 0 {
		return nil, fmt.Errorf("%s holds no colors", path)
	}
	return flat, nil
}

func canonicalRole(name string) string {
	words := splitWords(name)
	if len(words) == 0 {
		return ""
	}
	var builder strings.Builder
	builder.WriteString(strings.ToLower(words[0]))
	for _, word := range words[1:] {
		builder.WriteString(upperFirst(strings.ToLower(word)))
	}
	return builder.String()
}

func upperFirst(word string) string {
	if word == "" {
		return word
	}
	letters := []rune(word)
	letters[0] = unicode.ToUpper(letters[0])
	return string(letters)
}

func splitWords(name string) []string {
	var words []string
	var current strings.Builder
	flush := func() {
		if current.Len() > 0 {
			words = append(words, current.String())
			current.Reset()
		}
	}
	letters := []rune(name)
	for index, letter := range letters {
		switch {
		case letter == '_' || letter == '-' || letter == ' ':
			flush()
		case unicode.IsUpper(letter):
			if index > 0 {
				previous := letters[index-1]
				nextIsLower := index+1 < len(letters) && unicode.IsLower(letters[index+1])
				if unicode.IsLower(previous) || (unicode.IsUpper(previous) && nextIsLower) {
					flush()
				}
			}
			current.WriteRune(letter)
		default:
			current.WriteRune(letter)
		}
	}
	flush()
	return words
}

func suggestRoles(target string, roles []string, limit int) []string {
	type candidate struct {
		name     string
		distance int
	}
	candidates := make([]candidate, 0, len(roles))
	for _, role := range roles {
		candidates = append(candidates, candidate{name: role, distance: editDistance(target, role)})
	}
	sort.Slice(candidates, func(first, second int) bool {
		if candidates[first].distance != candidates[second].distance {
			return candidates[first].distance < candidates[second].distance
		}
		return candidates[first].name < candidates[second].name
	})
	if limit > len(candidates) {
		limit = len(candidates)
	}
	suggestions := make([]string, 0, limit)
	for _, entry := range candidates[:limit] {
		suggestions = append(suggestions, entry.name)
	}
	return suggestions
}

func editDistance(first, second string) int {
	firstRunes := []rune(first)
	secondRunes := []rune(second)
	previous := make([]int, len(secondRunes)+1)
	current := make([]int, len(secondRunes)+1)
	for column := range previous {
		previous[column] = column
	}
	for row := 1; row <= len(firstRunes); row++ {
		current[0] = row
		for column := 1; column <= len(secondRunes); column++ {
			cost := 1
			if firstRunes[row-1] == secondRunes[column-1] {
				cost = 0
			}
			current[column] = min(previous[column]+1, current[column-1]+1, previous[column-1]+cost)
		}
		previous, current = current, previous
	}
	return previous[len(secondRunes)]
}

func sortedKeys(values map[string]string) []string {
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}
