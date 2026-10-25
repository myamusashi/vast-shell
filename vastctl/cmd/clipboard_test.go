package cmd

import "testing"

func TestClipboard(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"list", []string{"clipboard", "list"}, []string{"clipboardHistory", "list"}},
		{"status", []string{"clipboard", "status"}, []string{"clipboardHistory", "status"}},
		{"clear", []string{"clipboard", "clear"}, []string{"clipboardHistory", "clear"}},
		{"remove", []string{"clipboard", "remove", "12"}, []string{"clipboardHistory", "remove", "12"}},
		{"search", []string{"clipboard", "search", "needle"}, []string{"clipboardHistory", "search", "needle"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

func TestClipboardSearchForwardsQueryVerbatim(t *testing.T) {
	runCall(t,
		[]string{"clipboardHistory", "search", "two words  and  spaces"},
		"clipboard", "search", "two words  and  spaces")
}

func TestClipboardRequiresArguments(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
	}{
		{"remove without an id", []string{"clipboard", "remove"}},
		{"search without a query", []string{"clipboard", "search"}},
		{"remove with too many ids", []string{"clipboard", "remove", "1", "2"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			recordShell(t)
			if _, err := runCLI(t, tc.args...); err == nil {
				t.Fatal("a missing argument must be rejected")
			}
		})
	}
}
