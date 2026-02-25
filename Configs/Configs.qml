pragma Singleton

import Quickshell
import Quickshell.Io
import TranslationManager

import qs.Configs
import qs.Helpers

Singleton {
    id: root

    property alias appearance: adapter.appearance
    property alias bar: adapter.bar
    property alias colors: adapter.colors
    property alias generals: adapter.generals
    property alias wallpaper: adapter.wallpaper
    property alias weather: adapter.weather
    property alias widgets: adapter.widgets
    property alias language: adapter.language

    onLanguageChanged: {
        TranslationManager.loadTranslation(root.language, Paths.translateFilePath);
    }

    FileView {
        path: Paths.shellDir + "/configurations.json"
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                console.log("Failed to read config files");
        }
        onLoaded: TranslationManager.loadTranslation(root.language, Paths.translateFilePath)
        onSaveFailed: err => console.log("Failed to save config", FileViewError.toString(err))

        JsonAdapter {
            id: adapter

            property AppearanceConfig appearance: AppearanceConfig {}
            property ColorSystemConfig colors: ColorSystemConfig {}
            property GeneralConfig generals: GeneralConfig {}
            property WallpaperConfig wallpaper: WallpaperConfig {}
            property WeatherConfig weather: WeatherConfig {}
            property BarConfig bar: BarConfig {}
            property string language: ""
            property var widgets: [
                {}
            ]
        }
    }
}
