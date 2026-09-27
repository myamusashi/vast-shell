package pretty

import (
	"encoding/json"
	"fmt"
	"sort"
	"strings"
	"unicode/utf8"
)

// Tree renders JSON input as a directory-tree style listing.
// For a JSON array, each element becomes a top-level entry with fields indented.
// For a JSON object, fields are listed directly under the root.
// For scalars (bool, number, string), it returns the value as-is.
func Tree(raw string) (string, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" || raw == "null" {
		return "(empty)", nil
	}
	if len(raw) >= 2 && raw[0] == '[' {
		return treeArray(raw)
	}
	if len(raw) >= 2 && raw[0] == '{' {
		return treeObject(raw)
	}
	return raw, nil
}

func treeArray(raw string) (string, error) {
	var items []map[string]json.RawMessage
	if err := json.Unmarshal([]byte(raw), &items); err != nil {
		return "", fmt.Errorf("tree: invalid JSON array: %w", err)
	}
	if len(items) == 0 {
		return "(empty)", nil
	}
	sb := new(strings.Builder)
	for i, item := range items {
		last := i == len(items)-1
		printItem(sb, "", item, last)
	}
	return sb.String(), nil
}

func treeObject(raw string) (string, error) {
	var obj map[string]json.RawMessage
	if err := json.Unmarshal([]byte(raw), &obj); err != nil {
		return "", fmt.Errorf("tree: invalid JSON object: %w", err)
	}
	if len(obj) == 0 {
		return "(empty)", nil
	}
	sb := new(strings.Builder)
	fields := sortedKeys(obj)
	for i, k := range fields {
		last := i == len(fields)-1
		conn := branch
		if last {
			conn = corner
		}
		val := formatValue(obj[k])
		sb.WriteString(conn)
		sb.WriteString(k)
		sb.WriteString(": ")
		// A pretty-printed value spans lines; the ones after the first
		// have to be pushed to the value's own column or they fall
		// back to column zero and land left of the field. The column
		// is counted in runes, not bytes: the connector glyphs are
		// three bytes each in UTF-8, so len() would overshoot by six.
		sb.WriteString(alignMultiline(val, utf8.RuneCountInString(conn)+utf8.RuneCountInString(k)+2))
		sb.WriteByte('\n')
	}
	return sb.String(), nil
}

const (
	branch = "├── "
	corner = "└── "
	pipe   = "│   "
	space  = "    "
)

func printItem(sb *strings.Builder, prefix string, item map[string]json.RawMessage, last bool) {
	conn := branch
	subIndent := pipe
	if last {
		conn = corner
		subIndent = space
	}

	label := firstLabel(item)
	if label == "" {
		label = "(entry)"
	}
	sb.WriteString(prefix)
	sb.WriteString(conn)
	sb.WriteString(label)
	sb.WriteByte('\n')

	fields := sortedKeys(item)
	for i, k := range fields {
		fieldLast := i == len(fields)-1
		fieldConn := branch
		if fieldLast {
			fieldConn = corner
		}
		val := formatValue(item[k])
		sb.WriteString(prefix)
		sb.WriteString(subIndent)
		sb.WriteString(fieldConn)
		sb.WriteString(k)
		sb.WriteString(": ")
		sb.WriteString(alignMultiline(val,
			utf8.RuneCountInString(prefix)+utf8.RuneCountInString(subIndent)+
				utf8.RuneCountInString(fieldConn)+utf8.RuneCountInString(k)+2))
		sb.WriteByte('\n')
	}
}

// alignMultiline indents every line of a value after the first by col
// spaces. A single-line value is returned untouched, which is the
// overwhelmingly common case and must stay allocation-free.
func alignMultiline(val string, col int) string {
	if !strings.Contains(val, "\n") {
		return val
	}
	lines := strings.Split(val, "\n")
	pad := strings.Repeat(" ", col)
	for i := 1; i < len(lines); i++ {
		lines[i] = pad + lines[i]
	}
	return strings.Join(lines, "\n")
}

func firstLabel(item map[string]json.RawMessage) string {
	for _, k := range []string{"name", "identity", "readable", "description"} {
		raw, ok := item[k]
		if !ok {
			continue
		}
		// A blank label must not shadow a later key. formatValue renders
		// "" as the placeholder <empty>, so the emptiness has to be
		// decided on the raw value — the formatted one never comes back
		// empty, which made this check below dead code.
		if s, isString := unquoteJSON(raw); isString && s == "" {
			continue
		}
		if s := formatValue(raw); s != "" && s != `""` {
			return s
		}
	}
	return ""
}

func sortedKeys(item map[string]json.RawMessage) []string {
	keys := make([]string, 0, len(item))
	for k := range item {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

func formatValue(raw json.RawMessage) string {
	if len(raw) == 0 || string(raw) == "null" {
		return "<nil>"
	}
	if isJSONString(raw) {
		s, _ := unquoteJSON(raw)
		if s == "" {
			return "<empty>"
		}
		return s
	}
	if isJSONBool(raw) {
		if string(raw) == "true" {
			return "yes"
		}
		return "no"
	}
	if isJSONNumber(raw) {
		n, _ := parseJSONNumber(raw)
		return n
	}
	out, _ := json.MarshalIndent(json.RawMessage(raw), "", "  ")
	return string(out)
}

func isJSONString(raw []byte) bool {
	return len(raw) >= 2 && raw[0] == '"'
}

func unquoteJSON(raw []byte) (string, bool) {
	var s string
	if err := json.Unmarshal(raw, &s); err != nil {
		return "", false
	}
	return s, true
}

func isJSONBool(raw []byte) bool {
	return string(raw) == "true" || string(raw) == "false"
}

func isJSONNumber(raw []byte) bool {
	for _, c := range raw {
		if c != '-' && c != '.' && c != '+' && c != 'e' && c != 'E' && (c < '0' || c > '9') {
			return false
		}
	}
	return len(raw) > 0
}

func parseJSONNumber(raw []byte) (string, bool) {
	var f float64
	if err := json.Unmarshal(raw, &f); err != nil {
		return string(raw), false
	}
	if f == float64(int64(f)) {
		return fmt.Sprintf("%d", int64(f)), true
	}
	return fmt.Sprintf("%v", f), true
}
