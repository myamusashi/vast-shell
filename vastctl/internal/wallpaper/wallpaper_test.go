package wallpaper

import (
	"crypto/md5"
	"encoding/hex"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// fakeFfmpeg answers the two calls the frame extraction makes: the
// length of the video and the frame itself.
const fakeFfmpeg = `#!/bin/sh
case "$1" in
  -v)
    printf -- '%s' "$SHIM_DURATION"
    exit 0
    ;;
esac
for argument in "$@"; do
  case "$argument" in
    *.png) output="$argument" ;;
  esac
done
printf -- 'frame' > "$output"
exit 0
`

// installFfmpeg puts a fake ffmpeg and ffprobe in front of the PATH and
// returns the directory they live in.
func installFfmpeg(t *testing.T, duration string) {
	t.Helper()
	directory := t.TempDir()
	for _, name := range []string{"ffmpeg", "ffprobe"} {
		if err := os.WriteFile(filepath.Join(directory, name), []byte(fakeFfmpeg), 0o755); err != nil {
			t.Fatalf("write the %s shim: %v", name, err)
		}
	}
	t.Setenv("PATH", directory+string(os.PathListSeparator)+os.Getenv("PATH"))
	t.Setenv("SHIM_DURATION", duration)
}

// TestIsVideo pins the extensions the shell treats as a video. The
// shell and the CLI have to agree, or a video wallpaper would take a
// different path in each.
func TestIsVideo(t *testing.T) {
	for _, path := range []string{"/wall.mp4", "/wall.MKV", "/wall.webm", "/wall.mov", "/wall.avi", "/wall.m4v"} {
		if !IsVideo(path) {
			t.Errorf("IsVideo(%q) = false, want true", path)
		}
	}
	for _, path := range []string{"/wall.png", "/wall.jpg", "/wall.webp", "/wall", "/wall.mp4.txt"} {
		if IsVideo(path) {
			t.Errorf("IsVideo(%q) = true, want false", path)
		}
	}
}

// TestCachePathMatchesTheShell pins the name of the cached frame. The
// shell caches the frame under this name, so the CLI has to find the
// frame the shell wrote instead of writing a second one.
func TestCachePathMatchesTheShell(t *testing.T) {
	t.Setenv("XDG_CACHE_DIR", "/cache")
	digest := md5.Sum([]byte("/videos/wall.mp4"))
	want := filepath.Join("/cache", "vast-shell", "vast-wallpaper-"+hex.EncodeToString(digest[:])+"-1024.png")
	got, err := CachePath("/videos/wall.mp4")
	if err != nil {
		t.Fatalf("CachePath: %v", err)
	}
	if got != want {
		t.Fatalf("CachePath = %q, want %q", got, want)
	}
}

// TestPaletteImageKeepsPictures pins that a picture is its own palette
// image.
func TestPaletteImageKeepsPictures(t *testing.T) {
	got, err := PaletteImage("/wallpapers/wall.png")
	if err != nil {
		t.Fatalf("PaletteImage: %v", err)
	}
	if got != "/wallpapers/wall.png" {
		t.Fatalf("PaletteImage = %q, want the wallpaper itself", got)
	}
}

// TestPaletteImageUsesTheCachedFrame pins that the frame the shell
// already wrote is used instead of a new one.
func TestPaletteImageUsesTheCachedFrame(t *testing.T) {
	cacheDirectory := t.TempDir()
	t.Setenv("XDG_CACHE_DIR", cacheDirectory)
	cachePath, err := CachePath("/videos/wall.mp4")
	if err != nil {
		t.Fatalf("CachePath: %v", err)
	}
	if err := os.MkdirAll(filepath.Dir(cachePath), 0o755); err != nil {
		t.Fatalf("create %s: %v", filepath.Dir(cachePath), err)
	}
	if err := os.WriteFile(cachePath, []byte("cached frame"), 0o644); err != nil {
		t.Fatalf("write %s: %v", cachePath, err)
	}
	// An empty PATH proves that no frame is extracted.
	t.Setenv("PATH", t.TempDir())

	got, err := PaletteImage("/videos/wall.mp4")
	if err != nil {
		t.Fatalf("PaletteImage: %v", err)
	}
	if got != cachePath {
		t.Fatalf("PaletteImage = %q, want the cached frame %q", got, cachePath)
	}
}

// TestPaletteImageExtractsAFrame pins that a video without a cached
// frame gets one, taken from the middle of the video.
func TestPaletteImageExtractsAFrame(t *testing.T) {
	installFfmpeg(t, "24")
	cacheDirectory := t.TempDir()
	t.Setenv("XDG_CACHE_DIR", cacheDirectory)

	got, err := PaletteImage("/videos/wall.mp4")
	if err != nil {
		t.Fatalf("PaletteImage: %v", err)
	}
	cachePath, err := CachePath("/videos/wall.mp4")
	if err != nil {
		t.Fatalf("CachePath: %v", err)
	}
	if got != cachePath {
		t.Fatalf("PaletteImage = %q, want %q", got, cachePath)
	}
	if _, err := os.Stat(cachePath); err != nil {
		t.Fatalf("the frame was not written: %v", err)
	}
}

// TestPaletteImageReportsAMissingFfmpeg pins that a video without a
// frame and without ffmpeg fails with a reason, instead of rendering a
// template without a palette.
func TestPaletteImageReportsAMissingFfmpeg(t *testing.T) {
	t.Setenv("XDG_CACHE_DIR", t.TempDir())
	t.Setenv("PATH", t.TempDir())

	_, err := PaletteImage("/videos/wall.mp4")
	if err == nil {
		t.Fatal("a video without ffmpeg must fail")
	}
	if !strings.Contains(err.Error(), "wall.mp4") {
		t.Errorf("the error %q does not name the video", err)
	}
}

// TestSeekFor pins the timestamp ffmpeg seeks to.
func TestSeekFor(t *testing.T) {
	for _, testCase := range []struct {
		seconds float64
		want    string
	}{
		{0, "00:00:00"},
		{12, "00:00:12"},
		{3725, "01:02:05"},
		{-5, "00:00:00"},
	} {
		if got := seekFor(testCase.seconds); got != testCase.want {
			t.Errorf("seekFor(%v) = %q, want %q", testCase.seconds, got, testCase.want)
		}
	}
}
