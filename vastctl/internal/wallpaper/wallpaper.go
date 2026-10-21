package wallpaper

import (
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

// videoExtensions are the extensions the shell recognises as a video
// wallpaper. The list is the shell's own, so both agree on what a
// video wallpaper is.
var videoExtensions = []string{".mp4", ".mkv", ".webm", ".mov", ".avi", ".m4v"}

func IsVideo(path string) bool {
	lowered := strings.ToLower(path)
	for _, extension := range videoExtensions {
		if strings.HasSuffix(lowered, extension) {
			return true
		}
	}
	return false
}

// CachePath is the frame the shell caches for a video wallpaper. The
// name is the one the shell uses, so the shell and the CLI share one
// frame instead of extracting the same picture twice.
func CachePath(videoPath string) (string, error) {
	cacheDirectory, err := cacheDirectory()
	if err != nil {
		return "", err
	}
	digest := md5.Sum([]byte(videoPath))
	name := fmt.Sprintf("vast-wallpaper-%s-1024.png", hex.EncodeToString(digest[:]))
	return filepath.Join(cacheDirectory, "vast-shell", name), nil
}

// PaletteImage returns the image the palette of a wallpaper is built
// from. A picture is its own image; a video is represented by a frame
// of it, the cached one when it is there and a new one otherwise.
func PaletteImage(wallpaperPath string) (string, error) {
	if !IsVideo(wallpaperPath) {
		return wallpaperPath, nil
	}
	cachePath, err := CachePath(wallpaperPath)
	if err != nil {
		return "", err
	}
	if info, err := os.Stat(cachePath); err == nil && info.Size() > 0 {
		return cachePath, nil
	}
	if err := extractFrame(wallpaperPath, cachePath); err != nil {
		return "", err
	}
	return cachePath, nil
}

// extractFrame writes a frame of the video into the cache path. The
// frame is taken from the middle of the video, like the shell does, so
// the black frames at the start are skipped.
func extractFrame(videoPath, cachePath string) error {
	directory := filepath.Dir(cachePath)
	if err := os.MkdirAll(directory, 0o755); err != nil {
		return fmt.Errorf("create %s: %w", directory, err)
	}
	duration, err := probeDuration(videoPath)
	if err != nil {
		return err
	}
	command := exec.Command("ffmpeg", "-ss", seekFor(duration/2), "-i", videoPath, "-vframes", "1", "-q:v", "2", "-vf", "scale=1024:-1", cachePath, "-y", "-v", "error")
	output, err := command.CombinedOutput()
	if err != nil {
		return fmt.Errorf("extract a frame of %s: %w: %s", videoPath, err, strings.TrimSpace(string(output)))
	}
	return nil
}

func probeDuration(videoPath string) (float64, error) {
	output, err := exec.Command("ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", videoPath).Output()
	if err != nil {
		return 0, fmt.Errorf("read the length of %s: %w", videoPath, err)
	}
	duration, err := strconv.ParseFloat(strings.TrimSpace(string(output)), 64)
	if err != nil {
		return 0, fmt.Errorf("read the length of %s: %w", videoPath, err)
	}
	return duration, nil
}

func seekFor(seconds float64) string {
	if seconds < 0 {
		seconds = 0
	}
	hours := int(seconds) / 3600
	minutes := (int(seconds) % 3600) / 60
	whole := int(seconds) % 60
	return fmt.Sprintf("%02d:%02d:%02d", hours, minutes, whole)
}

func cacheDirectory() (string, error) {
	if directory := os.Getenv("XDG_CACHE_DIR"); directory != "" {
		return directory, nil
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("locate the cache directory: %w", err)
	}
	return filepath.Join(home, ".cache"), nil
}
