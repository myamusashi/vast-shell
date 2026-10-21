package templates

import (
	"fmt"
	"strconv"
	"strings"
)

// A color is one palette entry: the channels are 0-255, the alpha is 0-1.
type color struct {
	Red   uint8
	Green uint8
	Blue  uint8
	Alpha float64
}

const opaque = 1.0

// parseColor reads a color in any of the accepted spellings and
// normalises it into the same struct.
func parseColor(value string) (color, error) {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return color{}, fmt.Errorf("empty color")
	}
	lowered := strings.ToLower(trimmed)
	switch {
	case strings.HasPrefix(lowered, "#"):
		return parseHexColor(trimmed[1:])
	case strings.HasPrefix(lowered, "rgb(") || strings.HasPrefix(lowered, "rgba("):
		return parseFunctionalColor(lowered)
	default:
		return color{}, fmt.Errorf("unsupported color %q", value)
	}
}

func parseHexColor(digits string) (color, error) {
	switch len(digits) {
	case 3:
		red, err := hexNibble(digits[0:1])
		if err != nil {
			return color{}, err
		}
		green, err := hexNibble(digits[1:2])
		if err != nil {
			return color{}, err
		}
		blue, err := hexNibble(digits[2:3])
		if err != nil {
			return color{}, err
		}
		return color{Red: red, Green: green, Blue: blue, Alpha: opaque}, nil
	case 6:
		red, err := hexByte(digits[0:2])
		if err != nil {
			return color{}, err
		}
		green, err := hexByte(digits[2:4])
		if err != nil {
			return color{}, err
		}
		blue, err := hexByte(digits[4:6])
		if err != nil {
			return color{}, err
		}
		return color{Red: red, Green: green, Blue: blue, Alpha: opaque}, nil
	case 8:
		red, err := hexByte(digits[0:2])
		if err != nil {
			return color{}, err
		}
		green, err := hexByte(digits[2:4])
		if err != nil {
			return color{}, err
		}
		blue, err := hexByte(digits[4:6])
		if err != nil {
			return color{}, err
		}
		alpha, err := hexByte(digits[6:8])
		if err != nil {
			return color{}, err
		}
		return color{Red: red, Green: green, Blue: blue, Alpha: float64(alpha) / 255.0}, nil
	default:
		return color{}, fmt.Errorf("unsupported hex color %q", "#"+digits)
	}
}

func parseFunctionalColor(value string) (color, error) {
	closing := strings.LastIndex(value, ")")
	if closing < 0 {
		return color{}, fmt.Errorf("unterminated color %q", value)
	}
	prefix := len("rgb(")
	if strings.HasPrefix(value, "rgba(") {
		prefix = len("rgba(")
	}
	inner := value[prefix:closing]
	parts := strings.Split(inner, ",")
	for index, part := range parts {
		parts[index] = strings.TrimSpace(part)
	}
	switch len(parts) {
	case 3:
		red, err := colorChannel(parts[0])
		if err != nil {
			return color{}, err
		}
		green, err := colorChannel(parts[1])
		if err != nil {
			return color{}, err
		}
		blue, err := colorChannel(parts[2])
		if err != nil {
			return color{}, err
		}
		return color{Red: red, Green: green, Blue: blue, Alpha: opaque}, nil
	case 4:
		red, err := colorChannel(parts[0])
		if err != nil {
			return color{}, err
		}
		green, err := colorChannel(parts[1])
		if err != nil {
			return color{}, err
		}
		blue, err := colorChannel(parts[2])
		if err != nil {
			return color{}, err
		}
		alpha, err := strconv.ParseFloat(parts[3], 64)
		if err != nil {
			return color{}, fmt.Errorf("invalid alpha %q", parts[3])
		}
		if alpha < 0 || alpha > 1 {
			return color{}, fmt.Errorf("alpha %v is outside 0-1", alpha)
		}
		return color{Red: red, Green: green, Blue: blue, Alpha: alpha}, nil
	default:
		return color{}, fmt.Errorf("unsupported color %q", value)
	}
}

func colorChannel(value string) (uint8, error) {
	parsed, err := strconv.Atoi(value)
	if err != nil {
		return 0, fmt.Errorf("invalid color channel %q", value)
	}
	if parsed < 0 || parsed > 255 {
		return 0, fmt.Errorf("color channel %d is outside 0-255", parsed)
	}
	return uint8(parsed), nil
}

// hexNibble reads one hex digit as a channel: a single digit is
// doubled, so #abc is the same color as #aabbcc.
func hexNibble(digit string) (uint8, error) {
	value, err := strconv.ParseUint(digit, 16, 8)
	if err != nil {
		return 0, fmt.Errorf("invalid hex digit %q", digit)
	}
	return uint8(value * 17), nil
}

func hexByte(digits string) (uint8, error) {
	value, err := strconv.ParseUint(digits, 16, 8)
	if err != nil {
		return 0, fmt.Errorf("invalid hex color %q", digits)
	}
	return uint8(value), nil
}

func (c color) hex() string {
	base := fmt.Sprintf("#%02x%02x%02x", c.Red, c.Green, c.Blue)
	if c.Alpha >= opaque {
		return base
	}
	return base + fmt.Sprintf("%02x", c.alphaByte())
}

func (c color) hexStripped() string {
	return strings.TrimPrefix(c.hex(), "#")
}

func (c color) rgb() string {
	return fmt.Sprintf("rgb(%d, %d, %d)", c.Red, c.Green, c.Blue)
}

func (c color) rgba() string {
	return fmt.Sprintf("rgba(%d, %d, %d, %s)", c.Red, c.Green, c.Blue, formatAlpha(c.Alpha))
}

// alphaByte rounds the alpha into the byte a hex color carries.
func (c color) alphaByte() uint8 {
	scaled := c.Alpha * 255.0
	if scaled <= 0 {
		return 0
	}
	if scaled >= 255 {
		return 255
	}
	return uint8(scaled + 0.5)
}

// formatAlpha writes an alpha with at most three decimals and without
// trailing zeroes, so 0.5 stays 0.5 instead of becoming 0.500.
func formatAlpha(alpha float64) string {
	written := strconv.FormatFloat(alpha, 'f', 3, 64)
	written = strings.TrimRight(written, "0")
	return strings.TrimSuffix(written, ".")
}
