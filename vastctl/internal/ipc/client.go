package ipc

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"syscall"
	"time"
)

const LogFilePath = "/tmp/vast-shell.log"

const bootTimeout = 45 * time.Second
const bootPoll = 250 * time.Millisecond

func LogFile() *os.File {
	f, err := os.OpenFile(LogFilePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		return nil
	}
	return f
}

var (
	runningMu     sync.Mutex
	runningCached bool
	runningValue  bool
)

var ensureOnce sync.Once

func ensureShellDaemon() {
	ensureOnce.Do(func() {
		if ShellRunning() {
			return
		}

		if dir := shellDirectory(); dir != "" && shellBooting(dir) {
			waitForShell(nil)
			return
		}
		bin, args := ShellBinArgs()
		cmd := exec.Command(bin, args...)
		cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
		if logFile := LogFile(); logFile != nil {
			defer func() { _ = logFile.Close() }()
			_, _ = fmt.Fprintf(logFile, "\n--- %s ---\n", time.Now().Format(time.RFC3339))
			cmd.Stdout = logFile
			cmd.Stderr = logFile
		}
		if err := cmd.Start(); err != nil {
			return
		}
		exited := make(chan struct{})
		go func() {
			_ = cmd.Wait()
			close(exited)
		}()
		waitForShell(exited)
	})
}

func waitForShell(exited <-chan struct{}) {
	dir := shellDirectory()
	if dir == "" {
		return
	}
	deadline := time.Now().Add(bootTimeout)
	for {
		select {
		case <-exited:
			return
		default:
		}
		if probe(dir) == nil {
			SetShellRunning(true)
			return
		}
		if !time.Now().Before(deadline) {
			return
		}
		time.Sleep(bootPoll)
	}
}

func shellBooting(dir string) bool {
	out, err := exec.Command("pgrep", "-f", "quickshell.*"+regexp.QuoteMeta(dir)).Output()
	return err == nil && len(out) > 0
}

func probe(dir string) error {
	args := []string{"-p", dir, "ipc", "show"}
	out, err := exec.Command("quickshell", args...).Output()
	if err == nil {
		return nil
	}
	return ipcError("quickshell", args, out, err)
}

// ShellRunning reports whether a shell instance is live for the resolved
// config path. The check shells out to quickshell, so the answer is
// memoized for the life of the process: vastctl is short-lived and is not
// expected to watch the shell come up or go down underneath it. Callers
// that change the state in this process record it through
// SetShellRunning rather than re-probing.
func ShellRunning() bool {
	runningMu.Lock()
	defer runningMu.Unlock()
	if runningCached {
		return runningValue
	}
	runningValue = probeShell()
	runningCached = true
	return runningValue
}

// SetShellRunning records a known running state and invalidates the memo.
// Start and stop paths must call it, otherwise a later ShellRunning
// answers from the probe taken before the transition.
func SetShellRunning(running bool) {
	runningMu.Lock()
	defer runningMu.Unlock()
	runningValue = running
	runningCached = true
}

func probeShell() bool {
	if dir := shellDirectory(); dir != "" {
		return probe(dir) == nil
	}
	out, err := exec.Command("pgrep", "-f", "quickshell").Output()
	return err == nil && len(out) > 0
}

// resetShellRunning drops the memo so a test observes a cold process.
// Production code never needs it: a real state change goes through
// SetShellRunning, which is the honest answer rather than a guess.
func resetShellRunning() {
	runningMu.Lock()
	defer runningMu.Unlock()
	runningCached = false
}

func ShellDirectory() string {
	return shellDirectory()
}

func ShellBinArgs() (string, []string) {
	if dir := shellDirectory(); dir != "" {
		return "quickshell", []string{"-p", dir}
	}
	if _, err := exec.LookPath("shell"); err == nil {
		return "shell", nil
	}
	return "quickshell", nil
}

func shellDirectory() string {
	root := ExpandEnv(os.Getenv("VAST_SHELL_DIRECTORY"))
	if root == "" {
		return ""
	}
	root = canonical(root)
	if isFile(filepath.Join(root, "shell.qml")) {
		return root
	}
	return filepath.Join(root, "Qml")
}

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

func shellIPCArgs() (string, []string) {
	bin, args := ShellBinArgs()
	return bin, append(args, "ipc", "call")
}

// Call invokes `shell ipc call <target> <method> [args...]` and returns
// the stdout output trimmed. Call only works for IPC targets that print
// results to stdout; void functions return empty string.
func Call(target string, method string, args ...string) (string, error) {
	ensureShellDaemon()

	bin, callArgs := shellIPCArgs()
	callArgs = append(callArgs, target, method)
	callArgs = append(callArgs, args...)

	output, err := exec.Command(bin, callArgs...).Output()
	if err != nil {
		return "", ipcError(bin, callArgs, output, err)
	}
	return strings.TrimSpace(string(output)), nil
}

// ipcError turns a failed quickshell invocation into an error carrying
// whatever diagnostics the binary produced. quickshell reports IPC
// routing failures — "No running instances for ..." — on stdout rather
// than stderr, so both streams have to be folded into the message. If
// stdout is dropped, every routing failure collapses to a bare
// "exit status 255" that names neither the target nor the cause.
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
