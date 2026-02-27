package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"
)

// Directories & paths
var (
	homeDir       = os.Getenv("HOME")
	screenshotDir = filepath.Join(homeDir, "Pictures", "screenshot")
	videoDir      = filepath.Join(homeDir, "Videos", "Shell")
	thumbnailDir  = filepath.Join(homeDir, ".cache", "thumbnails", "normal")

	recordPIDFile   = "/tmp/wl-screenrec.pid"
	recordVideoFile = "/tmp/wl-screenrec.video"

	audioDevice string
)

func init() {
	for _, d := range []string{screenshotDir, videoDir, thumbnailDir} {
		os.MkdirAll(d, 0755)
	}
}

// Path helpers
func timestamp() string {
	return time.Now().Format("2006-01-02_15-04-05")
}

func imgPath() string {
	return filepath.Join(screenshotDir, timestamp()+".png")
}

func vidPath() string {
	return filepath.Join(videoDir, timestamp()+".mp4")
}

// Notification helper
func notify(summary, body, urgency, icon, app string, actions []string, wait bool) string {
	args := []string{"-a", app}
	if urgency != "" && urgency != "normal" {
		args = append(args, "-u", urgency)
	}
	if icon != "" {
		args = append(args, "-i", icon)
	}
	for _, action := range actions {
		args = append(args, "--action", action)
	}
	if wait {
		args = append(args, "--wait")
	}
	args = append(args, summary, body)
	out, _ := exec.Command("notify-send", args...).Output()
	return strings.TrimSpace(string(out))
}

// Process helpers
func commandExists(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

func run(name string, args ...string) error {
	return exec.Command(name, args...).Run()
}

// Monitor detection
func getMonitors() []string {
	out, err := exec.Command("hyprctl", "monitors", "-j").Output()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error: hyprctl monitors failed")
		return nil
	}
	var monitors []struct {
		Name string `json:"name"`
	}
	if err := json.Unmarshal(out, &monitors); err != nil {
		fmt.Fprintln(os.Stderr, "Error parsing hyprctl output:", err)
		return nil
	}
	names := make([]string, len(monitors))
	for i, m := range monitors {
		names[i] = m.Name
	}
	return names
}

// Thumbnail helper
func createThumbnail(video, output string) bool {
	out, err := exec.Command(
		"ffprobe", "-v", "error",
		"-show_entries", "format=duration",
		"-of", "default=noprint_wrappers=1:nokey=1",
		video,
	).Output()
	if err != nil || strings.TrimSpace(string(out)) == "" {
		fmt.Fprintln(os.Stderr, "Error: Cannot get video duration")
		return false
	}

	duration, err := strconv.ParseFloat(strings.TrimSpace(string(out)), 64)
	if err != nil || duration < 1 {
		fmt.Fprintln(os.Stderr, "Error: Video too short or invalid duration")
		return false
	}

	ts := duration / 2
	h := int(ts / 3600)
	m := int(ts/60) % 60
	s := int(ts) % 60
	formatted := fmt.Sprintf("%02d:%02d:%02d", h, m, s)

	err = exec.Command(
		"ffmpeg", "-ss", formatted, "-i", video,
		"-vframes", "1", "-q:v", "2", "-vf", "scale=256:-1",
		output, "-y", "-v", "error",
	).Run()

	if err == nil {
		if _, statErr := os.Stat(output); statErr == nil {
			fmt.Println("Thumbnail created:", output)
			return true
		}
	}
	fmt.Fprintln(os.Stderr, "Error: Failed to create thumbnail")
	return false
}

// File opener
func gotoLink(file, thumb string, showNotification bool) {
	if _, err := os.Stat(file); err != nil {
		fmt.Fprintln(os.Stderr, "ERROR: File does not exist:", file)
		return
	}

	action := "default"
	if showNotification {
		icon := ""
		if thumb != "" {
			if _, err := os.Stat(thumb); err == nil {
				icon = thumb
			}
		}
		action = notify(
			"Capture Saved", file,
			"normal", icon, "screengrab",
			[]string{"default=open link"}, true,
		)
	}

	switch action {
	case "default":
		if commandExists("foot") {
			if commandExists("yazi") {
				exec.Command("footclient", "yazi", file).Start()
			} else {
				fmt.Fprintln(os.Stderr, "ERROR: yazi not found")
				exec.Command("xdg-open", filepath.Dir(file)).Start()
			}
		} else {
			fmt.Fprintln(os.Stderr, "ERROR: foot not found")
			exec.Command("xdg-open", file).Start()
		}
	case "":
		fmt.Println("No action taken (notification dismissed or timeout)")
	default:
		fmt.Printf("Unexpected action: '%s'\n", action)
	}
}

// Clipboard
func copyToClipboard(img string) {
	f, err := os.Open(img)
	if err != nil {
		return
	}
	defer f.Close()
	cmd := exec.Command("wl-copy")
	cmd.Stdin = f
	cmd.Run()
}

// Recording
func wlScreenrecCmd(vid, geometry, output string) []string {
	base := []string{"wl-screenrec", "--codec", "hevc", "--max-fps", "50"}
	if audioDevice != "" {
		base = append(base, "--audio", "--audio-device", audioDevice)
	}
	if geometry != "" {
		base = append(base, "-g", geometry)
	} else if output != "" {
		base = append(base, "-o", output)
	}
	base = append(base, "-f", vid)
	return base
}

func startRecording(geometry, output string) {
	if _, err := os.Stat(recordPIDFile); err == nil {
		notify("Recording Active", "A recording is already in progress.",
			"critical", "dialog-warning", "Screen Record", nil, false)
		return
	}

	vid := vidPath()
	args := wlScreenrecCmd(vid, geometry, output)
	cmd := exec.Command(args[0], args[1:]...)
	if err := cmd.Start(); err != nil {
		fmt.Fprintln(os.Stderr, "Error starting recording:", err)
		return
	}

	os.WriteFile(recordPIDFile, []byte(strconv.Itoa(cmd.Process.Pid)), 0644)
	os.WriteFile(recordVideoFile, []byte(vid), 0644)
	notify("Recording Started", "Press the same keybind again to stop recording.",
		"normal", "", "screenrecord", nil, false)
}

func stopRecording() {
	pidBytes, err := os.ReadFile(recordPIDFile)
	if err != nil {
		notify("Recording Failed", "No active recording found.",
			"critical", "dialog-error", "Screen Record", nil, false)
		return
	}

	vidBytes, err := os.ReadFile(recordVideoFile)
	if err != nil {
		notify("Recording Failed", "Cannot find video file path.",
			"critical", "dialog-error", "Screen Record", nil, false)
		os.Remove(recordPIDFile)
		return
	}

	pid, _ := strconv.Atoi(strings.TrimSpace(string(pidBytes)))
	vid := strings.TrimSpace(string(vidBytes))

	proc, err := os.FindProcess(pid)
	if err != nil {
		notify("Recording Failed", "No active recording found.",
			"critical", "dialog-error", "Screen Record", nil, false)
		os.Remove(recordPIDFile)
		os.Remove(recordVideoFile)
		return
	}

	// Send SIGINT and wait
	proc.Signal(syscall.SIGINT)
	// Wait with a goroutine + timeout
	done := make(chan error, 1)
	go func() {
		_, err := syscall.Wait4(pid, nil, 0, nil)
		done <- err
	}()
	select {
	case <-done:
	case <-time.After(10 * time.Second):
		proc.Kill()
	}

	os.Remove(recordPIDFile)
	os.Remove(recordVideoFile)
	time.Sleep(1 * time.Second)

	stem := strings.TrimSuffix(filepath.Base(vid), filepath.Ext(vid))
	thumb := filepath.Join(thumbnailDir, stem+".png")

	if createThumbnail(vid, thumb) {
		notify("Recording Stopped", "Video saved to "+vid,
			"normal", thumb, "screenrecord", nil, false)
	} else {
		notify("Recording Stopped", "Video saved to "+vid,
			"normal", "video-x-generic", "screenrecord", nil, false)
	}

	gotoLink(vid, thumb, false)
}

// Screenshot functions
func screenshotWindow() {
	time.Sleep(2 * time.Second)
	img := imgPath()
	out, _ := exec.Command(
		"hyprshot", "-m", "window", "-d", "-s",
		"-o", screenshotDir, "-f", filepath.Base(img),
	).CombinedOutput()
	if !strings.Contains(string(out), "selection cancelled") {
		copyToClipboard(img)
		gotoLink(img, img, true)
	} else {
		notify("Screenshot Failed", "Failed to take screenshot.",
			"critical", "dialog-error", "Screen Capture", nil, false)
	}
}

func screenshotSelection() {
	time.Sleep(2 * time.Second)
	img := imgPath()
	slurpOut, err := exec.Command("slurp").Output()
	if err != nil {
		notify("Screenshot Failed", "Failed to take screenshot.",
			"critical", "dialog-error", "Screen Capture", nil, false)
		return
	}
	geometry := strings.TrimSpace(string(slurpOut))
	if err := run("grim", "-g", geometry, img); err != nil {
		notify("Screenshot Failed", "Failed to take screenshot.",
			"critical", "dialog-error", "Screen Capture", nil, false)
		return
	}
	copyToClipboard(img)
	gotoLink(img, img, true)
}

func screenshotOutput(out string) {
	monitors := getMonitors()
	if len(monitors) == 0 {
		notify("Screenshot Failed", "No monitors found.",
			"critical", "dialog-error", "Screen Capture", nil, false)
		return
	}
	target := monitors[0]
	for _, m := range monitors {
		if m == out {
			target = m
			break
		}
	}
	time.Sleep(2 * time.Second)
	img := imgPath()
	if err := run("grim", "-c", "-o", target, img); err != nil {
		notify("Screenshot Failed", "Failed to take screenshot on "+target+".",
			"critical", "dialog-error", "Screen Capture", nil, false)
		return
	}
	copyToClipboard(img)
	gotoLink(img, img, true)
}

func screenshotOutputs(out1, out2 string) {
	monitors := getMonitors()
	if len(monitors) < 2 {
		notify("Screenshot Failed", "Need at least two monitors.",
			"critical", "dialog-error", "Screen Capture", nil, false)
		return
	}

	contains := func(name string) bool {
		for _, m := range monitors {
			if m == name {
				return true
			}
		}
		return false
	}

	m1 := monitors[0]
	if contains(out1) {
		m1 = out1
	}
	m2 := monitors[1]
	if contains(out2) {
		m2 = out2
	}

	time.Sleep(2 * time.Second)
	base := imgPath()
	ext := filepath.Ext(base)
	stem := strings.TrimSuffix(base, ext)
	img1 := stem + "-" + m1 + ext
	img2 := stem + "-" + m2 + ext

	err1 := run("grim", "-c", "-o", m1, img1)
	err2 := run("grim", "-c", "-o", m2, img2)

	if err1 != nil || err2 != nil {
		notify("Screenshot Failed", "Failed to take screenshot on both screens.",
			"critical", "dialog-error", "Screen Capture", nil, false)
		return
	}

	run("montage", img1, img2, "-tile", "2x1", "-geometry", "+0+0", base)
	copyToClipboard(base)
	os.Remove(img1)
	os.Remove(img2)
	gotoLink(base, base, true)
}

// Entry point
const usage = `Usage: screen-capture {COMMAND} [ARGS]
Monitor names are auto-detected via hyprctl monitors -j.
Pass an explicit name to override the default.

Screenshot Commands:
  --screenshot-window                    Take screenshot of active window
  --screenshot-selection                 Take screenshot of selected area
  --screenshot-output [OUTPUT]           Screenshot a monitor (default: first detected)
  --screenshot-outputs [OUT1] [OUT2]     Screenshot two monitors and merge

Screenrecord Commands:
  --screenrecord-selection               Record selected area (toggle to stop)
  --screenrecord-output [OUTPUT]         Record a monitor (default: first detected)
  --screenrecord-all                     Record all screens (toggle to stop)
  --stop-recording                       Stop active recording

Global Flags:
  --audio-device <device>                Audio device for screen recording
`

func main() {
	// Ignore SIGPIPE
	signal.Ignore(syscall.SIGPIPE)

	args := os.Args[1:]
	if len(args) == 0 {
		fmt.Fprint(os.Stderr, usage)
		os.Exit(1)
	}

	// Strip --audio-device <device>
	for i := 0; i < len(args); i++ {
		if args[i] == "--audio-device" {
			if i+1 >= len(args) {
				fmt.Fprintln(os.Stderr, "Error: --audio-device requires a value")
				os.Exit(1)
			}
			audioDevice = args[i+1]
			args = append(args[:i], args[i+2:]...)
			i--
		}
	}

	if len(args) == 0 {
		fmt.Fprint(os.Stderr, usage)
		os.Exit(1)
	}

	cmd := args[0]
	arg := func(n int) string {
		if len(args) > n {
			return args[n]
		}
		return ""
	}

	switch cmd {
	case "--screenshot-window":
		screenshotWindow()

	case "--screenshot-selection":
		screenshotSelection()

	case "--screenshot-output":
		screenshotOutput(arg(1))

	case "--screenshot-outputs":
		screenshotOutputs(arg(1), arg(2))

	case "--screenrecord-selection":
		if _, err := os.Stat(recordPIDFile); err == nil {
			stopRecording()
		} else {
			time.Sleep(2 * time.Second)
			slurpOut, err := exec.Command("slurp").Output()
			if err != nil {
				notify("Recording Failed", "Selection cancelled.",
					"critical", "dialog-error", "Screen Record", nil, false)
				return
			}
			startRecording(strings.TrimSpace(string(slurpOut)), "")
		}

	case "--screenrecord-output":
		if _, err := os.Stat(recordPIDFile); err == nil {
			stopRecording()
		} else {
			monitors := getMonitors()
			if len(monitors) == 0 {
				notify("Recording Failed", "No monitors found.",
					"critical", "dialog-error", "Screen Record", nil, false)
				os.Exit(1)
			}
			out := monitors[0]
			if a := arg(1); a != "" {
				for _, m := range monitors {
					if m == a {
						out = a
						break
					}
				}
			}
			time.Sleep(2 * time.Second)
			startRecording("", out)
		}

	case "--screenrecord-all":
		if _, err := os.Stat(recordPIDFile); err == nil {
			stopRecording()
		} else {
			time.Sleep(2 * time.Second)
			startRecording("", "")
		}

	case "--stop-recording":
		stopRecording()

	default:
		fmt.Fprint(os.Stderr, usage)
		os.Exit(1)
	}
}
