package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"
)

type Keyboard struct {
	Address  string `json:"address"`
	Name     string `json:"name"`
	CapsLock bool   `json:"capsLock"`
	NumLock  bool   `json:"numLock"`
	Main     bool   `json:"main"`
}

type DevicesOutput struct {
	Keyboards []Keyboard `json:"keyboards"`
}

type LockStatus struct {
	CapsLock bool `json:"capsLock"`
	NumLock  bool `json:"numLock"`
}

func GetLockStatus() (*LockStatus, error) {
	cmd := exec.Command("hyprctl", "devices", "-j")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("KEYSTATE: failed to execute hyprctl: %w", err)
	}

	var devices DevicesOutput
	if err := json.Unmarshal(output, &devices); err != nil {
		return nil, fmt.Errorf("KEYSTATE: failed to parse JSON: %w", err)
	}

	status := &LockStatus{}

	for _, kb := range devices.Keyboards {
		if kb.Main || kb.CapsLock || kb.NumLock {
			status.CapsLock = kb.CapsLock
			status.NumLock = kb.NumLock

			if kb.Main {
				break
			}
		}
	}

	return status, nil
}

type LockListener struct {
	interval     time.Duration
	lastStatus   *LockStatus
	jsonFilePath string
}

func NewLockListener(interval time.Duration, jsonPath string) *LockListener {
	return &LockListener{
		interval:     interval,
		lastStatus:   nil,
		jsonFilePath: jsonPath,
	}
}

func (l *LockListener) writeJSONFile(status *LockStatus) error {
	data, err := json.MarshalIndent(status, "", "  ")
	if err != nil {
		return fmt.Errorf("KEYSTATE: failed to marshal JSON: %w", err)
	}

	err = os.WriteFile(l.jsonFilePath, data, 0644)
	if err != nil {
		return fmt.Errorf("KEYSTATE: failed to write JSON file: %w", err)
	}

	return nil
}

func (l *LockListener) Start(ctx context.Context) error {
	ticker := time.NewTicker(l.interval)
	defer ticker.Stop()

	initialStatus, err := GetLockStatus()
	if err != nil {
		return fmt.Errorf("KEYSTATE: failed to get initial status: %w", err)
	}
	l.lastStatus = initialStatus

	if err := l.writeJSONFile(initialStatus); err != nil {
		return err
	}

	fmt.Printf("KEYSTATE: Monitoring started - Caps Lock: %v, Num Lock: %v\n",
		initialStatus.CapsLock, initialStatus.NumLock)

	for {
		select {
		case <-ctx.Done():
			fmt.Println("KEYSTATE: Monitoring stopped")
			return nil
		case <-ticker.C:
			status, err := GetLockStatus()
			if err != nil {
				log.Printf("KEYSTATE: getting status: %v", err)
				continue
			}

			if status.CapsLock != l.lastStatus.CapsLock || status.NumLock != l.lastStatus.NumLock {
				if err := l.writeJSONFile(status); err != nil {
					log.Printf("KEYSTATE: error writing JSON: %v", err)
				}

				l.lastStatus = status
			}
		}
	}
}

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-sigChan
		fmt.Println("KEYSTATE: Interrupt received, shutting down...")
		cancel()
	}()

	listener := NewLockListener(100*time.Millisecond, "/tmp/keystate.json")
	if err := listener.Start(ctx); err != nil {
		log.Fatalf("KEYSTATE: services failed to run: %v", err)
	}
}
