package ipc

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/myamusashi/vast-shell/vastctl/internal/daemon"
)

// LogFilePath is where background shell output is forwarded. It is a var
// so tests can redirect the log without touching the real file.
var LogFilePath = "/tmp/vast-shell.log"

// LogFile opens the background log file for appending, creating it if
// needed. Returns nil if the file cannot be opened.
func LogFile() *os.File {
	f, err := os.OpenFile(LogFilePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		return nil
	}
	return f
}

// ShellDirectory returns the config directory of the checkout named by
// VAST_SHELL_DIRECTORY, or "" when unset. It resolves the checkout for
// *starting* a daemon; IPC calls deliberately ignore it so a stray
// environment cannot redirect a client to a shell that is not running.
func ShellDirectory() string {
	return ConfigDir(os.Getenv("VAST_SHELL_DIRECTORY"))
}

// ConfigDir resolves a vast-shell root to the directory that holds
// shell.qml, or "" for an empty root. A user names a checkout by its
// root, so the entry point has to be located rather than assumed: it may
// sit directly in the root or in a Qml/ subdirectory, and quickshell
// resolves a config selector to a shell.qml sitting directly in the
// chosen directory. Pointing -p at the wrong one yields "Could not open
// config file".
func ConfigDir(root string) string {
	if root == "" {
		return ""
	}
	root = canonical(ExpandEnv(root))
	if isFile(filepath.Join(root, "shell.qml")) {
		return root
	}
	return filepath.Join(root, "Qml")
}

// ShellBinArgs returns the binary and arguments that select the config
// named by VAST_SHELL_DIRECTORY, falling back to the installed "shell"
// wrapper.
func ShellBinArgs() (string, []string) {
	if dir := ShellDirectory(); dir != "" {
		return "quickshell", []string{"-p", dir}
	}
	if _, err := exec.LookPath("shell"); err == nil {
		return "shell", nil
	}
	return "quickshell", nil
}

// canonical resolves dir to an absolute path with symlinks expanded.
// quickshell matches IPC instances by literal config path, so the path
// handed to it has to be spelled exactly the way the shell is launched.
func canonical(dir string) string {
	abs, err := filepath.Abs(dir)
	if err != nil {
		return dir
	}
	if resolved, err := filepath.EvalSymlinks(abs); err == nil {
		return resolved
	}
	return abs
}

func isFile(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

// ExpandEnv expands session variable references in s. The supported forms
// are $VAR, ${VAR}, and $env.VAR — all read from the process environment.
// Unknown variables expand to an empty string.
func ExpandEnv(s string) string {
	if !strings.ContainsRune(s, '$') {
		return s
	}
	isIdent := func(c byte) bool {
		return c == '_' || c >= '0' && c <= '9' || c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z'
	}
	var b strings.Builder
	for i := 0; i < len(s); {
		if s[i] != '$' {
			b.WriteByte(s[i])
			i++
			continue
		}
		if strings.HasPrefix(s[i:], "$env.") {
			start := i + len("$env.")
			j := start
			for j < len(s) && isIdent(s[j]) {
				j++
			}
			b.WriteString(os.Getenv(s[start:j]))
			i = j
			continue
		}
		if i+1 < len(s) && s[i+1] == '{' {
			end := strings.IndexByte(s[i+2:], '}')
			if end < 0 {
				b.WriteString(s[i:])
				break
			}
			b.WriteString(os.Getenv(s[i+2 : i+2+end]))
			i += 2 + end + 1
			continue
		}
		start := i + 1
		if start < len(s) && isIdent(s[start]) {
			j := start
			for j < len(s) && isIdent(s[j]) {
				j++
			}
			b.WriteString(os.Getenv(s[start:j]))
			i = j
			continue
		}
		b.WriteByte('$')
		i++
	}
	return b.String()
}

// Call invokes `quickshell ipc --id <instance> call <target> <method>
// [args...]` against the running daemon and returns stdout trimmed.
//
// It only ever connects. The target comes from the state file the daemon
// supervisor publishes, so the call reaches whichever shell is actually
// running regardless of the caller's working directory, environment, or
// config path. Starting a daemon from here is what turns a path
// mismatch into a second shell, so Call refuses instead.
func Call(target string, method string, args ...string) (string, error) {
	state, err := daemon.Running()
	if err != nil {
		return "", err
	}
	callArgs := append([]string{"ipc", "--id", state.InstanceID, "call", target, method}, args...)
	output, err := exec.Command("quickshell", callArgs...).Output()
	if err != nil {
		return "", ipcError("quickshell", callArgs, output, err)
	}
	return strings.TrimSpace(string(output)), nil
}

// ipcError turns a failed quickshell invocation into an error carrying
// whatever diagnostics the binary produced. quickshell reports IPC
// failures — a closed socket, an unknown instance — on stdout as often
// as on stderr, so both streams are folded into the message. Dropping
// stdout reduces every routing failure to a bare exit status that names
// neither the target nor the reason.
func ipcError(bin string, args []string, stdout []byte, err error) error {
	invocation := strings.Join(append([]string{bin}, args...), " ")
	details := make([]string, 0, 2)
	if out := strings.TrimSpace(string(stdout)); out != "" {
		details = append(details, out)
	}
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) {
		if errOut := strings.TrimSpace(string(exitErr.Stderr)); errOut != "" {
			details = append(details, errOut)
		}
	}
	if len(details) == 0 {
		return fmt.Errorf("%s: %w", invocation, err)
	}
	return fmt.Errorf("%s: %s", invocation, strings.Join(details, "; "))
}
