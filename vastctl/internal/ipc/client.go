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

// InstallConfigDir is the vast-shell installed next to this binary, or ""
// when this binary is not part of an install. A var for the tests.
var InstallConfigDir = ownConfigDir

// ShellDirectory returns the config directory a started daemon runs from.
// IPC calls ignore it on purpose: a stray variable must not redirect a
// client to a shell that is not running. The dev directory wins, then the
// install beside this binary, then VAST_SHELL_DIRECTORY -- after a rebuild a
// session can still carry the previous generation's path.
func ShellDirectory() string {
	if dev := ConfigDir(os.Getenv("VAST_SHELL_DEV_DIRECTORY")); dev != "" {
		return dev
	}
	env := ConfigDir(os.Getenv("VAST_SHELL_DIRECTORY"))
	if own := InstallConfigDir(); own != "" && env != own {
		return own
	}
	return env
}

// IgnoredShellDirectory reports the VAST_SHELL_DIRECTORY value
// ShellDirectory() passed over, so a start can say which one it launched.
// A dev directory replaces it deliberately and reports nothing.
func IgnoredShellDirectory() string {
	if ConfigDir(os.Getenv("VAST_SHELL_DEV_DIRECTORY")) != "" {
		return ""
	}
	env := ConfigDir(os.Getenv("VAST_SHELL_DIRECTORY"))
	own := InstallConfigDir()
	if own == "" || env == "" || env == own {
		return ""
	}
	return env
}

// ownConfigDir is the share/quickshell directory beside this binary:
// <prefix>/bin/vastctl next to <prefix>/share/quickshell.
func ownConfigDir() string {
	exe, err := os.Executable()
	if err != nil {
		return ""
	}
	exe = canonical(exe)
	if filepath.Base(filepath.Dir(exe)) != "bin" {
		return ""
	}
	root := filepath.Join(filepath.Dir(filepath.Dir(exe)), "share", "quickshell")
	if !hasEntryPoint(root) {
		return ""
	}
	return ConfigDir(root)
}

// hasEntryPoint reports whether root holds a shell.qml quickshell can run.
func hasEntryPoint(root string) bool {
	return isFile(filepath.Join(root, "shell.qml")) || isFile(filepath.Join(root, "Qml", "shell.qml"))
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
// ShellDirectory resolved, falling back to the installed "shell" wrapper.
func ShellBinArgs() (string, []string) {
	if dir := ShellDirectory(); dir != "" {
		return "quickshell", []string{"-p", dir}
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
