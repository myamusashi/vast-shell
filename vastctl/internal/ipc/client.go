package ipc

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"
)

var ensureOnce sync.Once

// ensureShellDaemon launches the shell in the background if it's not already
// running. Uses pgrep to check for an existing quickshell process.
func ensureShellDaemon() {
	ensureOnce.Do(func() {
		if out, err := exec.Command("pgrep", "-f", "quickshell").Output(); err == nil && len(out) > 0 {
			return
		}
		bin, args := ShellBinArgs()
		cmd := exec.Command(bin, args...)
		cmd.Stdout = nil
		cmd.Stderr = nil
		_ = cmd.Start()
		time.Sleep(500 * time.Millisecond)
	})
}

// ShellBinArgs returns the binary and arguments to launch the shell.
func ShellBinArgs() (string, []string) {
	if _, err := exec.LookPath("shell"); err == nil {
		return "shell", nil
	}
	if dir := os.Getenv("VAST_SHELL_DIRECTORY"); dir != "" {
		return "quickshell", []string{"-p", dir + "/Qml"}
	}
	return "quickshell", nil
}

// ShellIPCArgs builds the command and args needed to invoke an IPC call.
func ShellIPCArgs() (string, []string) {
	if _, err := exec.LookPath("shell"); err == nil {
		return "shell", []string{"ipc", "call"}
	}
	if dir := os.Getenv("VAST_SHELL_DIRECTORY"); dir != "" {
		return "quickshell", []string{"-p", dir + "/Qml", "ipc", "call"}
	}
	return "quickshell", []string{"ipc", "call"}
}

// Call invokes `shell ipc call <target> <method> [args...]` and returns
// the stdout output trimmed. Call only works for IPC targets that print
// results to stdout; void functions return empty string.
func Call(target string, method string, args ...string) (string, error) {
	ensureShellDaemon()

	bin, callArgs := ShellIPCArgs()
	callArgs = append(callArgs, target, method)
	callArgs = append(callArgs, args...)

	cmd := exec.Command(bin, callArgs...)
	output, err := cmd.Output()
	if err != nil {
		var exitErr *exec.ExitError
		if errorsAs(err, &exitErr) {
			stderr := strings.TrimSpace(string(exitErr.Stderr))
			if stderr != "" {
				return "", fmt.Errorf("%s ipc call %s %s: %s", bin, target, method, stderr)
			}
		}
		return "", fmt.Errorf("%s ipc call %s %s: %w", bin, target, method, err)
	}
	return strings.TrimSpace(string(output)), nil
}

// errorsAs is a local helper to avoid importing errors for a single use case.
func errorsAs(err error, target interface{}) bool {
	type as interface{ As(interface{}) bool }
	if a, ok := err.(as); ok {
		return a.As(target)
	}
	return false
}

// CallJSON calls the IPC target and unmarshals the output as JSON into v.
func CallJSON(target string, method string, args []string, v interface{}) error {
	ensureShellDaemon()

	bin, callArgs := ShellIPCArgs()
	callArgs = append(callArgs, target, method)
	callArgs = append(callArgs, args...)

	cmd := exec.Command(bin, callArgs...)
	output, err := cmd.Output()
	if err != nil {
		var exitErr *exec.ExitError
		if errorsAs(err, &exitErr) {
			stderr := strings.TrimSpace(string(exitErr.Stderr))
			if stderr != "" {
				return fmt.Errorf("%s ipc call %s %s: %s", bin, target, method, stderr)
			}
		}
		return fmt.Errorf("%s ipc call %s %s: %w", bin, target, method, err)
	}
	if err := json.Unmarshal(output, v); err != nil {
		return fmt.Errorf("json unmarshal: %w", err)
	}
	return nil
}
