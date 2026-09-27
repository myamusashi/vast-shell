package cmd

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/spf13/cobra"
)

// redirectLog points the daemon log at a scratch file for the duration
// of a test. LogFilePath is a real system path and the command both
// reads and waits on it, so a test that left it alone would either
// read whatever the developer's shell has logged or block forever
// waiting for a file that is not coming.
func redirectLog(t *testing.T, content string) string {
	t.Helper()
	orig := ipc.LogFilePath
	path := filepath.Join(t.TempDir(), "vast-shell.log")
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatalf("write log: %v", err)
	}
	ipc.LogFilePath = path
	t.Cleanup(func() { ipc.LogFilePath = orig })
	return path
}

// logCmdForTest returns a throwaway command that writes into buf, so
// printRecentLines can be exercised without going through the package
// level tree.
func logCmdForTest(buf *strings.Builder) *cobra.Command {
	c := &cobra.Command{Use: "log"}
	c.SetOut(buf)
	return c
}

// TestLogNoFollowPrintsRecentLines pins the tail. `vastctl log -n 20`
// is the first thing a user runs when the shell misbehaves, and the
// most recent lines are the relevant ones.
func TestLogNoFollowPrintsRecentLines(t *testing.T) {
	redirectLog(t, "one\ntwo\nthree\nfour\n")

	res, err := runCLI(t, "log", "--no-follow")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	// `log` writes through cobra's writer, unlike the commands that
	// print with fmt.Println.
	if want := "one\ntwo\nthree\nfour\n"; res.cmdOut != want {
		t.Fatalf("output = %q, want %q", res.cmdOut, want)
	}
}

// TestLogLinesFlag pins -n. A fixed 20 lines is wrong for both ends of
// the range: too few hides the failure, too many buries it.
func TestLogLinesFlag(t *testing.T) {
	redirectLog(t, "one\ntwo\nthree\nfour\nfive\n")

	for _, tc := range []struct {
		n    string
		want string
	}{
		{"1", "five\n"},
		{"2", "four\nfive\n"},
		{"3", "three\nfour\nfive\n"},
		// Asking for more lines than exist yields everything, not an
		// error and not padding.
		{"99", "one\ntwo\nthree\nfour\nfive\n"},
	} {
		t.Run("n="+tc.n, func(t *testing.T) {
			res, err := runCLI(t, "log", "--no-follow", "-n", tc.n)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if res.cmdOut != tc.want {
				t.Fatalf("output = %q, want %q", res.cmdOut, tc.want)
			}
		})
	}
}

// TestLogZeroLines pins that -n 0 prints nothing but still succeeds.
// The offset is taken from the file size, so a zero-line tail followed
// by a follow still resumes at the end rather than replaying.
func TestLogZeroLines(t *testing.T) {
	redirectLog(t, "one\ntwo\n")

	for _, args := range [][]string{
		{"log", "--no-follow", "-n", "0"},
		{"log", "--no-follow", "-n", "-1"},
	} {
		t.Run(strings.Join(args, " "), func(t *testing.T) {
			res, err := runCLI(t, args...)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if res.cmdOut != "" {
				t.Fatalf("output = %q, want nothing", res.cmdOut)
			}
		})
	}
}

// TestLogMissingFileWithoutFollow pins the answer when the log does not
// exist yet. Waiting for a file that no daemon will ever write would
// hang a script forever, so --no-follow has to report and exit.
func TestLogMissingFileWithoutFollow(t *testing.T) {
	orig := ipc.LogFilePath
	ipc.LogFilePath = filepath.Join(t.TempDir(), "absent.log")
	t.Cleanup(func() { ipc.LogFilePath = orig })

	res, err := runCLI(t, "log", "--no-follow")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if want := "no log file at " + ipc.LogFilePath + "\n"; res.cmdOut != want {
		t.Fatalf("output = %q, want %q", res.cmdOut, want)
	}
}

// TestLogEmptyFile pins that an empty log is not an error and does not
// print a stray newline.
func TestLogEmptyFile(t *testing.T) {
	redirectLog(t, "")

	res, err := runCLI(t, "log", "--no-follow")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if res.cmdOut != "" {
		t.Fatalf("output = %q, want nothing", res.cmdOut)
	}
}

// TestLogHandlesMissingTrailingNewline pins that a log whose last write
// was cut short still prints that line. A daemon killed mid-write is
// the case a user is usually reading the log to diagnose.
func TestLogHandlesMissingTrailingNewline(t *testing.T) {
	redirectLog(t, "one\ntwo\npartial")

	res, err := runCLI(t, "log", "--no-follow")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if want := "one\ntwo\npartial\n"; res.cmdOut != want {
		t.Fatalf("output = %q, want %q", res.cmdOut, want)
	}
}

// TestPrintRecentLinesResumeOffset pins that the returned offset is the
// end of the file. followLog resumes reading from it, and an offset at
// the start of the tail would replay the recent lines on every poll.
func TestPrintRecentLinesResumeOffset(t *testing.T) {
	for _, tc := range []struct {
		name    string
		content string
		n       int
		want    string
	}{
		{"all lines", "one\ntwo\n", 20, "one\ntwo\n"},
		{"last line", "one\ntwo\n", 1, "two\n"},
		{"no lines", "one\ntwo\n", 0, ""},
		{"negative is treated as none", "one\ntwo\n", -1, ""},
		{"single line", "only\n", 5, "only\n"},
		{"empty", "", 5, ""},
		{"no trailing newline", "a\nb", 5, "a\nb\n"},
		{"blank lines are preserved", "a\n\n\nb\n", 5, "a\n\n\nb\n"},
		{"more requested than exist", "a\n", 50, "a\n"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			path := redirectLog(t, tc.content)
			file, err := os.Open(path)
			if err != nil {
				t.Fatalf("open: %v", err)
			}
			defer func() { _ = file.Close() }()

			buf := new(strings.Builder)
			offset, err := printRecentLines(logCmdForTest(buf), file, tc.n)
			if err != nil {
				t.Fatalf("printRecentLines: %v", err)
			}
			if buf.String() != tc.want {
				t.Fatalf("printed %q, want %q", buf.String(), tc.want)
			}
			info, err := file.Stat()
			if err != nil {
				t.Fatalf("stat: %v", err)
			}
			if offset != info.Size() {
				t.Fatalf("offset = %d, want the file size %d", offset, info.Size())
			}
		})
	}
}

// TestPrintRecentLinesLargeLog pins the tail window. A log past the
// scan limit is read from the end only; reading the whole file would
// make `vastctl log` slower the longer the shell has been up, and the
// lines the user wants are the recent ones regardless.
func TestPrintRecentLinesLargeLog(t *testing.T) {
	// Fixed-width lines make the byte arithmetic exact, so this does
	// not depend on how the window happens to land.
	var sb strings.Builder
	const lines = 8000
	for i := range lines {
		fmt.Fprintf(&sb, "line%06d\n", i)
	}
	content := sb.String()
	path := redirectLog(t, content)

	file, err := os.Open(path)
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	defer func() { _ = file.Close() }()

	buf := new(strings.Builder)
	if _, err := printRecentLines(logCmdForTest(buf), file, 3); err != nil {
		t.Fatalf("printRecentLines: %v", err)
	}

	want := "line007997\nline007998\nline007999\n"
	if buf.String() != want {
		t.Fatalf("printed %q, want %q", buf.String(), want)
	}
}

// signalWriter is a cobra output that reports each write on a channel.
// followLog blocks until its writer fails, so the test needs a writer
// it can both observe and then break.
type signalWriter struct {
	writes chan string
	fail   atomic.Bool
}

func newSignalWriter() *signalWriter {
	return &signalWriter{writes: make(chan string, 16)}
}

func (s *signalWriter) Write(p []byte) (int, error) {
	if s.fail.Load() {
		return 0, errors.New("output closed")
	}
	s.writes <- string(p)
	return len(p), nil
}

// await returns every write made within timeout, once want is among
// them.
func (s *signalWriter) await(t *testing.T, want string, timeout time.Duration) string {
	t.Helper()
	var got strings.Builder
	deadline := time.After(timeout)
	for !strings.Contains(got.String(), want) {
		select {
		case chunk := <-s.writes:
			got.WriteString(chunk)
		case <-deadline:
			t.Fatalf("timed out waiting for %q, got %q so far", want, got.String())
		}
	}
	return got.String()
}

// TestLogFollowsNewLines pins the streaming half: content appended
// after the tail has been printed is forwarded, and the tail is not
// replayed on the way. That is the whole point of `vastctl log` without
// --no-follow.
func TestLogFollowsNewLines(t *testing.T) {
	path := redirectLog(t, "first\n")

	file, err := os.Open(path)
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	tail := new(strings.Builder)
	offset, err := printRecentLines(logCmdForTest(tail), file, 20)
	if err != nil {
		t.Fatalf("printRecentLines: %v", err)
	}
	if want := "first\n"; tail.String() != want {
		t.Fatalf("tail = %q, want %q", tail.String(), want)
	}

	out := newSignalWriter()
	c := &cobra.Command{Use: "log"}
	c.SetOut(out)

	done := make(chan error, 1)
	go func() { done <- followLog(c, file, offset) }()

	// The follow has to be parked at the end of the file before the
	// append. Waiting is unavoidable when testing a blocking reader;
	// the assertion afterwards is still on what it actually printed.
	time.Sleep(50 * time.Millisecond)
	appendTo(t, path, "second\n")

	got := out.await(t, "second\n", 3*time.Second)
	if strings.Contains(got, "first\n") {
		t.Fatalf("the tail was replayed: %q", got)
	}

	// A failing writer is how followLog is meant to end, but it only
	// writes when there is new data, so the failure is noticed on the
	// next append rather than at the moment the writer breaks.
	out.fail.Store(true)
	appendTo(t, path, "third\n")
	select {
	case err := <-done:
		if err == nil {
			t.Fatal("followLog returned no error after its output failed")
		}
	case <-time.After(3 * time.Second):
		t.Fatal("followLog did not return after its output was closed")
	}
}

// TestLogFollowsReplacement pins rotation handling. A daemon that
// reopens its log leaves a follow reading an inode nothing writes to
// any more, so the command has to notice the new file and continue.
// "Restarts without re-running the command" is exactly this.
func TestLogFollowsReplacement(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "vast-shell.log")
	orig := ipc.LogFilePath
	ipc.LogFilePath = path
	t.Cleanup(func() { ipc.LogFilePath = orig })
	if err := os.WriteFile(path, []byte("old\n"), 0o600); err != nil {
		t.Fatalf("write: %v", err)
	}

	file, err := os.Open(path)
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	offset, err := printRecentLines(logCmdForTest(new(strings.Builder)), file, 20)
	if err != nil {
		t.Fatalf("printRecentLines: %v", err)
	}

	out := newSignalWriter()
	c := &cobra.Command{Use: "log"}
	c.SetOut(out)

	done := make(chan error, 1)
	go func() { done <- followLog(c, file, offset) }()

	time.Sleep(50 * time.Millisecond)
	if err := os.Rename(path, filepath.Join(dir, "vast-shell.log.1")); err != nil {
		t.Fatalf("rename: %v", err)
	}
	if err := os.WriteFile(path, []byte("rotated\n"), 0o600); err != nil {
		t.Fatalf("write rotated log: %v", err)
	}

	out.await(t, "rotated\n", 3*time.Second)

	// Same as the append case: the failure surfaces on the next write,
	// and followLog only writes when there is new data.
	out.fail.Store(true)
	appendTo(t, path, "after\n")
	select {
	case err := <-done:
		if err == nil {
			t.Fatal("followLog returned no error after its output failed")
		}
	case <-time.After(3 * time.Second):
		t.Fatal("followLog did not return after its output was closed")
	}
}

func appendTo(t *testing.T, path, content string) {
	t.Helper()
	f, err := os.OpenFile(path, os.O_APPEND|os.O_WRONLY, 0o600)
	if err != nil {
		t.Fatalf("open for append: %v", err)
	}
	if _, err := f.WriteString(content); err != nil {
		t.Fatalf("append: %v", err)
	}
	if err := f.Close(); err != nil {
		t.Fatalf("close: %v", err)
	}
}
