package cmd

import (
	"encoding/json"
	"strconv"

	"github.com/carapace-sh/carapace"
	"github.com/myamusashi/vast-shell/vastctl/internal/hypr"
	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
)

var percentValues = []string{"0%", "25%", "50%", "75%", "100%", "+10%", "-10%"}

func emptyOnErr(err error) bool { return err != nil }

func init() {
	carapace.Gen(captureScreenCmd).PositionalCompletion(
		carapace.ActionValues("copy", "save", "save+copy"),
	)
	carapace.Gen(captureRegionCmd).PositionalCompletion(
		carapace.ActionValues("copy", "save", "save+copy"),
	)
	carapace.Gen(captureWindowCmd).PositionalCompletion(
		carapace.ActionValues("copy", "save", "save+copy"),
	)

	carapace.Gen(wallpaperSetCmd).PositionalCompletion(
		carapace.ActionFiles(".png", ".jpg", ".jpeg", ".webp"),
	)

	carapace.Gen(toastOpenCmd).FlagCompletion(carapace.ActionMap{
		"icon": carapace.ActionFiles(),
	})

	carapace.Gen(volumeSystemSetCmd).PositionalCompletion(
		carapace.ActionValues(percentValues...),
	)
	carapace.Gen(brightnessSetCmd).PositionalCompletion(
		carapace.ActionValues(percentValues...),
	)

	carapace.Gen(dispatchCmd).PositionalCompletion(
		carapace.ActionCallback(func(c carapace.Context) carapace.Action {
			shortcuts, err := hypr.ListShortcuts()
			if emptyOnErr(err) {
				return carapace.ActionValues()
			}
			vals := make([]string, 0, len(shortcuts)*2)
			for _, s := range shortcuts {
				vals = append(vals, s.Name, s.Description)
			}
			return carapace.ActionValuesDescribed(vals...)
		}),
	)

	carapace.Gen(audioProfileSetCmd).PositionalCompletion(
		carapace.ActionCallback(func(c carapace.Context) carapace.Action {
			out, err := ipc.Call("audio", "profileList")
			if emptyOnErr(err) {
				return carapace.ActionValues()
			}
			var res struct {
				Profiles []struct {
					Name        string `json:"name"`
					Description string `json:"description"`
				} `json:"profiles"`
			}
			if err := json.Unmarshal([]byte(out), &res); err != nil {
				return carapace.ActionValues()
			}
			vals := make([]string, 0, len(res.Profiles)*2)
			for _, p := range res.Profiles {
				vals = append(vals, p.Name, p.Description)
			}
			return carapace.ActionValuesDescribed(vals...)
		}),
	)

	carapace.Gen(audioDeviceSetCmd).PositionalCompletion(
		carapace.ActionCallback(func(c carapace.Context) carapace.Action {
			out, err := ipc.Call("audio", "deviceList")
			if emptyOnErr(err) {
				return carapace.ActionValues()
			}
			var devices []struct {
				Name        string `json:"name"`
				Description string `json:"description"`
			}
			if err := json.Unmarshal([]byte(out), &devices); err != nil {
				return carapace.ActionValues()
			}
			vals := make([]string, 0, len(devices)*2)
			for _, d := range devices {
				vals = append(vals, d.Name, d.Description)
			}
			return carapace.ActionValuesDescribed(vals...)
		}),
	)

	appNodeCallback := carapace.ActionCallback(func(c carapace.Context) carapace.Action {
		out, err := ipc.Call("volume", "appList")
		if emptyOnErr(err) {
			return carapace.ActionValues()
		}
		var streams []struct {
			ID        int    `json:"id"`
			Name      string `json:"name"`
			AppName   string `json:"appName"`
			MediaName string `json:"mediaName"`
		}
		if err := json.Unmarshal([]byte(out), &streams); err != nil {
			return carapace.ActionValues()
		}
		vals := make([]string, 0, len(streams)*2)
		for _, s := range streams {
			label := s.AppName
			if label == "" {
				label = s.Name
			}
			if s.MediaName != "" {
				label += " — " + s.MediaName
			}
			vals = append(vals, strconv.Itoa(s.ID), label)
		}
		return carapace.ActionValuesDescribed(vals...)
	})
	carapace.Gen(volumeAppSetCmd).PositionalCompletion(
		appNodeCallback,
		carapace.ActionValues(percentValues...),
	)
	carapace.Gen(volumeAppMuteCmd).PositionalCompletion(appNodeCallback)
	carapace.Gen(volumeAppUnmuteCmd).PositionalCompletion(appNodeCallback)
	carapace.Gen(volumeAppToggleCmd).PositionalCompletion(appNodeCallback)

	carapace.Gen(clipboardRemoveCmd).PositionalCompletion(
		carapace.ActionCallback(func(c carapace.Context) carapace.Action {
			out, err := ipc.Call("clipboardHistory", "list")
			if emptyOnErr(err) {
				return carapace.ActionValues()
			}
			var entries []struct {
				EntryID int    `json:"entryId"`
				ID      int    `json:"id"`
				Preview string `json:"preview"`
				Type    string `json:"type"`
			}
			if err := json.Unmarshal([]byte(out), &entries); err != nil {
				return carapace.ActionValues()
			}
			vals := make([]string, 0, len(entries)*2)
			for _, e := range entries {
				id := e.EntryID
				if id == 0 {
					id = e.ID
				}
				desc := e.Preview
				if e.Type != "" {
					desc = e.Type + ": " + desc
				}
				vals = append(vals, strconv.Itoa(id), desc)
			}
			return carapace.ActionValuesDescribed(vals...)
		}),
	)
}
