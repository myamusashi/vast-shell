package cmd

import (
	"errors"
	"os"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/myamusashi/vast-shell/vastctl/internal/templates"
	"github.com/myamusashi/vast-shell/vastctl/internal/wallpaper"
	"github.com/spf13/cobra"
)

// colorRenderCommand renders the configured templates with the palette
// the shell holds. The renderer lives in the templates package; this
// command only names the files and forwards the flags.
func colorRenderCommand() *cobra.Command {
	var templateName string
	var wallpaperPath string

	command := &cobra.Command{
		Use:   "render",
		Short: "Render the configured color templates",
		Long: "Render every enabled template of the template list with the current palette. " +
			"The palette comes from the shell, so the rendered files always match the live colors. " +
			"An output file that is already there is replaced.",
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			mode, err := cmd.Flags().GetString("mode")
			if err != nil {
				return err
			}
			scheme, err := cmd.Flags().GetString("scheme")
			if err != nil {
				return err
			}
			configPath := templates.DefaultConfigPath()
			if configPath == "" {
				return errors.New("cannot locate the template list: the home directory is unknown")
			}
			renderer := templates.Renderer{
				ConfigPath: configPath,
				Source:     shellPaletteSource{},
				Out:        os.Stdout,
				Stderr:     os.Stderr,
			}
			return renderer.Render(templates.RenderOptions{
				Wallpaper:    wallpaperPath,
				Mode:         mode,
				Scheme:       scheme,
				TemplateName: templateName,
			})
		},
	}
	command.Flags().StringVar(&templateName, "template", "", "Render only the template with this name")
	command.Flags().StringVar(&wallpaperPath, "wallpaper", "", "Render from this wallpaper instead of the current one")
	return command
}

// shellPaletteSource asks the running shell for the wallpaper and the
// palette. The shell owns the palette: the renderer must not
// reimplement the color math.
type shellPaletteSource struct{}

func (shellPaletteSource) CurrentWallpaper() (string, error) {
	return ipc.Call("img", "get")
}

func (shellPaletteSource) Palette(wallpaperPath, mode, scheme string) (map[string]string, error) {
	image, err := wallpaper.PaletteImage(wallpaperPath)
	if err != nil {
		return nil, err
	}
	output, err := ipc.Call("color", "generate", image, mode, scheme)
	if err != nil {
		return nil, err
	}
	return templates.ParsePalette(output)
}

func init() {
	colorCmd.AddCommand(colorRenderCommand())
}
